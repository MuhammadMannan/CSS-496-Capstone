import 'package:campus_connect/components/club_bottom_navbar.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ClubProfilePage extends StatefulWidget {
  const ClubProfilePage({super.key});

  @override
  State<ClubProfilePage> createState() => _ClubProfilePageState();
}

class _ClubProfilePageState extends State<ClubProfilePage> {
  final supabase = Supabase.instance.client;
  Map<String, dynamic>? _club;
  bool _loading = true;
  String _clubId = '';

  @override
  void initState() {
    super.initState();
    _clubId = supabase.auth.currentUser?.id ?? '';
    _loadClubProfile();
  }

  Future<void> _loadClubProfile() async {
    if (_clubId.isEmpty) return;

    try {
      final response =
          await supabase.from('clubs').select().eq('id', _clubId).maybeSingle();

      setState(() {
        _club = response;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Error loading club profile: $e');
      setState(() => _loading = false);
    }
  }

  void _logout() async {
    await supabase.auth.signOut();
    if (context.mounted) {
      Navigator.pushReplacementNamed(context, '/auth');
    }
  }

  @override
  Widget build(BuildContext context) {
    final logoUrl = _club?['logo_url'];
    final name = _club?['name'] ?? 'Club Name';
    final description = _club?['description'] ?? 'No description provided.';
    final email = _club?['email'] ?? 'No email';
    final meetingTimes = _club?['recurring_meeting_times'] ?? 'Not specified';
    final followerCount = _club?['followers'] ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    if (logoUrl != null && logoUrl.isNotEmpty)
                      Center(
                        child: CircleAvatar(
                          radius: 40,
                          backgroundImage: NetworkImage(logoUrl),
                        ),
                      ),
                    const SizedBox(height: 16),
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text('Email: $email'),
                    const SizedBox(height: 10),
                    Text('Description: $description'),
                    const SizedBox(height: 10),
                    Text('Recurring Meeting Times: $meetingTimes'),
                    const SizedBox(height: 10),
                    Text('Followers: $followerCount'),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: () {
                        // Navigate to edit profile page
                      },
                      child: const Text('Edit Profile'),
                    ),
                  ],
                ),
              ),
      bottomNavigationBar: ClubBottomNavBar(currentIndex: 1, clubId: _clubId),
    );
  }
}
