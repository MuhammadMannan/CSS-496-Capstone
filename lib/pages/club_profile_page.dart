import 'package:campus_connect/components/club_bottom_navbar.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class ClubProfilePage extends StatefulWidget {
  const ClubProfilePage({super.key});

  @override
  State<ClubProfilePage> createState() => _ClubProfilePageState();
}

class _ClubProfilePageState extends State<ClubProfilePage> {
  final supabase = Supabase.instance.client;
  Map<String, dynamic>? _club;
  List<Map<String, dynamic>> _posts = [];
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

      final postResponse = await supabase
          .from('posts')
          .select()
          .eq('club_id', _clubId)
          .order('created_at', ascending: false);

      setState(() {
        _club = response;
        _posts = List<Map<String, dynamic>>.from(postResponse);
        _loading = false;
      });
    } catch (e) {
      debugPrint('Error loading club profile: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _deletePost(String postId) async {
    try {
      await supabase.from('posts').delete().eq('id', postId);
      _loadClubProfile();
    } catch (e) {
      debugPrint('Error deleting post: $e');
    }
  }

  Future<void> _updateMeetingTimes(String newTime) async {
    try {
      await supabase
          .from('clubs')
          .update({'recurring_meeting_times': newTime})
          .eq('id', _clubId);
      _loadClubProfile();
    } catch (e) {
      debugPrint('Error updating meeting times: $e');
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
        title: const Text('Club Profile'),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                    const SizedBox(height: 8),
                    Text('Email: $email'),
                    const SizedBox(height: 8),
                    Text('Description: $description'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text('Recurring Meetings: $meetingTimes'),
                        ),
                        ShadIconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () async {
                            final controller = TextEditingController(
                              text: meetingTimes,
                            );
                            final updated = await showDialog<String>(
                              context: context,
                              builder:
                                  (context) => AlertDialog(
                                    title: const Text('Update Meeting Time'),
                                    content: TextField(
                                      controller: controller,
                                      decoration: const InputDecoration(
                                        labelText: 'New Time',
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Cancel'),
                                      ),
                                      ElevatedButton(
                                        onPressed:
                                            () => Navigator.pop(
                                              context,
                                              controller.text.trim(),
                                            ),
                                        child: const Text('Update'),
                                      ),
                                    ],
                                  ),
                            );
                            if (updated != null && updated.isNotEmpty) {
                              _updateMeetingTimes(updated);
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Followers: $followerCount'),
                    const SizedBox(height: 20),
                    const Divider(),
                    const Text(
                      'Your Posts',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ..._posts.map(
                      (post) => Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          title: Text(post['title'] ?? 'Untitled'),
                          subtitle: Text(post['caption'] ?? ''),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deletePost(post['id']),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      bottomNavigationBar: ClubBottomNavBar(currentIndex: 1, clubId: _clubId),
    );
  }
}
