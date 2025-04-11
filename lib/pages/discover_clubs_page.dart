import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'student_home_page.dart';
import 'profile_page.dart';

class DiscoverClubsPage extends StatefulWidget {
  const DiscoverClubsPage({super.key});

  @override
  _DiscoverClubsPageState createState() => _DiscoverClubsPageState();
}

class _DiscoverClubsPageState extends State<DiscoverClubsPage> {
  final supabase = Supabase.instance.client;

  final int _selectedIndex = 1;
  List<dynamic> _clubs = [];
  List<String> _followingClubIds = [];

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

    // Get all clubs
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

    debugPrint("🧠 userId trying to update: $userId");
  }

  Widget _buildClubCard(Map club) {
    final clubId = club['id'];
    final isFollowing = _followingClubIds.contains(clubId);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        title: Text(club['name']),
        subtitle: Text(club['description'] ?? ''),
        trailing: ElevatedButton(
          onPressed: () => _toggleFollowClub(clubId),
          style: ElevatedButton.styleFrom(
            backgroundColor: isFollowing ? Colors.grey : Colors.blue,
          ),
          child: Text(isFollowing ? 'Following' : 'Follow'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Discover Clubs')),
      body: ListView.builder(
        itemCount: _clubs.length,
        itemBuilder: (context, index) {
          final club = _clubs[index] as Map<String, dynamic>;
          return _buildClubCard(club);
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Discover'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: _selectedIndex,
        onTap: (index) {
          if (index == _selectedIndex) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) {
                if (index == 0) return const StudentHomePage();
                if (index == 2) return const ProfilePage();
                return widget;
              },
            ),
          );
        },
      ),
    );
  }
}
