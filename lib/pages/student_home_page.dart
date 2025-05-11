import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'discover_clubs_page.dart';
import 'profile_page.dart';

class StudentHomePage extends StatefulWidget {
  const StudentHomePage({super.key});

  @override
  State<StudentHomePage> createState() => _StudentHomePageState();
}

class _StudentHomePageState extends State<StudentHomePage> {
  final supabase = Supabase.instance.client;
  final int _selectedIndex = 0;

  List<Map<String, dynamic>> _posts = [];
  Set<String> _rsvpedPostIds = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadFeed();
  }

  Future<void> _loadFeed() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final studentResponse =
          await supabase
              .from('students')
              .select('following_clubs')
              .eq('id', user.id)
              .maybeSingle();

      final followingClubsRaw =
          (studentResponse?['following_clubs'] ?? []) as List<dynamic>;
      final followingClubs =
          followingClubsRaw.map((e) => e.toString()).toList();

      print('👀 following_clubs: $followingClubs');

      if (followingClubs.isEmpty) {
        setState(() {
          _posts = [];
          _rsvpedPostIds.clear();
          _loading = false;
        });
        return;
      }

      final postsResponse = await supabase
          .from('posts')
          .select()
          .inFilter('club_id', followingClubs)
          .order('created_at', ascending: false);

      final postList = List<Map<String, dynamic>>.from(postsResponse);
      final postIds = postList.map((p) => p['id'] as String).toList();

      final rsvpResponse = await supabase
          .from('rsvps')
          .select('post_id')
          .inFilter('post_id', postIds)
          .eq('student_id', user.id);

      final rsvpPostIds =
          (rsvpResponse as List<dynamic>)
              .map((e) => e['post_id'] as String)
              .toSet();

      print('📦 postsResponse: $postList');
      print('✅ RSVP Status: $rsvpPostIds');

      setState(() {
        _posts = postList;
        _rsvpedPostIds = rsvpPostIds;
        _loading = false;
      });
    } catch (e) {
      print('🔥 Failed to load feed: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _toggleRsvp(String postId) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final isRsvped = _rsvpedPostIds.contains(postId);
    print('🔁 Toggling RSVP for post $postId (currently: $isRsvped)');

    try {
      if (isRsvped) {
        await supabase
            .from('rsvps')
            .delete()
            .eq('post_id', postId)
            .eq('student_id', user.id);
        print('❌ RSVP removed for post: $postId');
      } else {
        await supabase.from('rsvps').insert({
          'post_id': postId,
          'student_id': user.id,
        });
        print('✅ RSVP added for post: $postId');
      }

      _loadFeed();
    } catch (e) {
      print('❗ Error toggling RSVP: $e');
    }
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    Widget page;
    if (index == 0) {
      page = const StudentHomePage();
    } else if (index == 1) {
      page = const DiscoverClubsPage();
    } else {
      page = const ProfilePage();
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }

  Widget _buildFeed() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_posts.isEmpty) {
      return const Center(
        child: Text('No posts yet. Follow clubs to see posts!'),
      );
    }

    return ListView.builder(
      itemCount: _posts.length,
      itemBuilder: (context, index) {
        final post = _posts[index];
        final postId = post['id'] as String;
        final isEvent = post['label'] == 'event';
        final isRsvped = _rsvpedPostIds.contains(postId);

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                title: Text(post['title'] ?? 'No Title'),
                trailing: IconButton(
                  icon: const Icon(Icons.comment),
                  onPressed: () => _openCommentsModal(context, postId),
                  tooltip: 'View Comments',
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (post['caption'] != null) Text(post['caption']),
                    if (post['image_url'] != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Image.network(
                          post['image_url'],
                          height: 150,
                          fit: BoxFit.cover,
                        ),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      post['label']?.toUpperCase() ?? '',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (isEvent)
                      TextButton(
                        onPressed: () => _toggleRsvp(postId),
                        child: Text(isRsvped ? 'Cancel RSVP' : 'RSVP'),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openCommentsModal(BuildContext context, String postId) {
    final commentController = TextEditingController();
    final user = supabase.auth.currentUser;

    List<Map<String, dynamic>> comments = [];
    bool loading = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            Future<void> loadComments() async {
              final response = await supabase
                  .from('comments')
                  .select('content, created_at, student_id')
                  .eq('post_id', postId)
                  .order('created_at', ascending: false);
              if (context.mounted) {
                setState(() {
                  comments = List<Map<String, dynamic>>.from(response);
                  loading = false;
                });
              }
            }

            Future<void> submitComment() async {
              final content = commentController.text.trim();
              if (content.isEmpty || user == null) return;

              await supabase.from('comments').insert({
                'post_id': postId,
                'student_id': user.id,
                'content': content,
              });
              commentController.clear();
              await loadComments();
            }

            if (loading) loadComments();

            return Padding(
              padding: MediaQuery.of(context).viewInsets,
              child: SizedBox(
                height: 400,
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    const Text('Comments', style: TextStyle(fontSize: 18)),
                    const Divider(),
                    Expanded(
                      child:
                          loading
                              ? const Center(child: CircularProgressIndicator())
                              : ListView.builder(
                                itemCount: comments.length,
                                itemBuilder: (context, index) {
                                  final c = comments[index];
                                  return ListTile(
                                    title: Text(c['content']),
                                    subtitle: Text(
                                      DateTime.parse(
                                        c['created_at'],
                                      ).toLocal().toString(),
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  );
                                },
                              ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: commentController,
                              decoration: const InputDecoration(
                                hintText: 'Write a comment...',
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.send),
                            onPressed: submitComment,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('UWB Flock')),
      body: _buildFeed(),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Discover'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
