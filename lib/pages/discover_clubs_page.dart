// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api

import 'package:campus_connect/components/student_bottom_navbar.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'club_details_page.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class DiscoverClubsPage extends StatefulWidget {
  const DiscoverClubsPage({super.key});

  @override
  _DiscoverClubsPageState createState() => _DiscoverClubsPageState();
}

class _DiscoverClubsPageState extends State<DiscoverClubsPage> {
  final supabase = Supabase.instance.client;

  List<dynamic> _clubs = [];
  List<String> _followingClubIds = [];
  List<String> _selectedCategories = [];

  static const clubCategories = {
    'tech': 'Technology',
    'business': 'Business',
    'cybersecurity': 'Cybersecurity',
    'data': 'Data & Analytics',
    'medical': 'Medical & Health',
    'science': 'Science & Engineering',
    'arts': 'Arts & Media',
    'culture': 'Cultural & Identity',
    'sports': 'Sports & Fitness',
    'gaming': 'Gaming & eSports',
    'hobbies': 'Hobbies & Special Interest',
    'environment': 'Environmental & Sustainability',
    'volunteering': 'Volunteering & Service',
    'leadership': 'Leadership & Professional Dev',
  };

  @override
  void initState() {
    super.initState();
    _loadClubs();
  }

  Future<void> _loadClubs() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId != null) {
      final studentResponse =
          await supabase
              .from('students')
              .select('following_clubs')
              .eq('id', userId)
              .maybeSingle();

      if (studentResponse != null) {
        _followingClubIds =
            (studentResponse['following_clubs'] ?? []).cast<String>();
      } else {
        _followingClubIds = [];
      }
    }

    final clubsResponse = await supabase.from('clubs').select();
    debugPrint('📦 Clubs response: $clubsResponse');

    setState(() {
      _clubs = clubsResponse;
    });
  }

  Future<void> _toggleFollowClub(String clubId) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    final isFollowing = _followingClubIds.contains(clubId);
    final updatedClubs =
        isFollowing
            ? _followingClubIds.where((id) => id != clubId).toList()
            : [..._followingClubIds, clubId];

    try {
      final response =
          await supabase
              .from('students')
              .update({'following_clubs': updatedClubs})
              .eq('id', userId)
              .select();

      if (response.isEmpty) {
        debugPrint('⚠️ No rows were updated.');
      } else {
        // ✅ Update followers count in clubs table
        final countDelta = isFollowing ? -1 : 1;
        final result = await supabase.rpc(
          'increment_followers',
          params: {'club_id_input': clubId, 'delta': countDelta},
        );
        debugPrint('📊 New follower count: $result');

        debugPrint(
          isFollowing
              ? '❎ Club unfollowed: $clubId'
              : '✅ Club followed: $clubId',
        );

        setState(() {
          _followingClubIds = updatedClubs;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Follow toggle failed: $e')));
    }
  }

  Widget _buildClubCard(Map club) {
    final clubId = club['id'];
    final isFollowing = _followingClubIds.contains(clubId);
    final logoUrl = club['logo_url'];

    return GestureDetector(
      onTap:
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ClubDetailsPage(clubId: clubId)),
          ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: ShadCard(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              logoUrl != null && logoUrl.toString().isNotEmpty
                  ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      logoUrl,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (context, error, stackTrace) =>
                              const Icon(Icons.image_not_supported),
                    ),
                  )
                  : const Icon(Icons.group, size: 60),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      club['name'] ?? '',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      club['description'] ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ShadButton(
                onPressed: () => _toggleFollowClub(clubId),
                child: Text(isFollowing ? 'Following' : 'Follow'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    final theme = ShadTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ShadSelect<String>.multiple(
        minWidth: 340,
        onChanged: (values) {
          setState(() => _selectedCategories = values);
        },
        allowDeselection: true,
        closeOnSelect: false,
        placeholder: const Text('Filter by categories'),
        options: [
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 6, 6, 6),
            child: Text('Categories', style: theme.textTheme.large),
          ),
          ...clubCategories.entries.map(
            (e) => ShadOption(value: e.key, child: Text(e.value)),
          ),
        ],
        selectedOptionsBuilder:
            (context, values) => Text(
              values.map((v) => clubCategories[v] ?? v).join(', '),
              overflow: TextOverflow.ellipsis,
            ),
      ),
    );
  }

  List<Map<String, dynamic>> get _filteredClubs {
    if (_selectedCategories.isEmpty) {
      return List<Map<String, dynamic>>.from(_clubs);
    }
    return _clubs
        .where((club) {
          final categories = (club['category'] as List?)?.cast<String>() ?? [];
          return categories.any((cat) => _selectedCategories.contains(cat));
        })
        .cast<Map<String, dynamic>>()
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Discover Clubs')),
      body: Column(
        children: [
          _buildCategoryFilter(),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredClubs.length,
              itemBuilder: (context, index) {
                final club = _filteredClubs[index];
                return _buildClubCard(club);
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: StudentBottomNavBar(currentIndex: 1),
    );
  }
}
