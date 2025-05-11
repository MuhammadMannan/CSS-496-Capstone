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
          .select('*, clubs:club_id(name, logo_url)')
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

      setState(() {
        _posts = postList;
        _rsvpedPostIds = rsvpPostIds;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _toggleRsvp(String postId) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final isRsvped = _rsvpedPostIds.contains(postId);

    try {
      if (isRsvped) {
        await supabase
            .from('rsvps')
            .delete()
            .eq('post_id', postId)
            .eq('student_id', user.id);
      } else {
        await supabase.from('rsvps').insert({
          'post_id': postId,
          'student_id': user.id,
        });
      }
      _loadFeed();
    } catch (e) {
      // handle error
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

        final club = post['clubs'];
        final logoUrl = club != null ? club['logo_url'] : null;

        print('🪵 clubs field: $club');

        return Padding(
          padding: const EdgeInsets.all(12.0),
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  leading:
                      logoUrl != null
                          ? CircleAvatar(
                            backgroundImage: NetworkImage(logoUrl),
                            backgroundColor: Colors.transparent,
                          )
                          : CircleAvatar(
                            backgroundColor: Colors.purple[100],
                            child: Text(
                              post['title']?[0].toUpperCase() ?? '?',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                  title: Text(
                    post['title'] ?? 'No Title',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                if (post['image_url'] != null)
                  Container(
                    height: 180,
                    width: double.infinity,
                    color: Colors.grey[300],
                    child: Image.network(
                      post['image_url'],
                      fit: BoxFit.cover,
                      errorBuilder:
                          (context, error, stackTrace) => const Center(
                            child: Icon(Icons.broken_image, size: 40),
                          ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Text(
                    post['caption'] ?? '',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.favorite_border, size: 20),
                          const SizedBox(width: 4),
                          const Text('0'),
                          const SizedBox(width: 16),
                          GestureDetector(
                            onTap: () => _openCommentsModal(context, postId),
                            child: Row(
                              children: const [
                                Icon(Icons.chat_bubble_outline, size: 20),
                                SizedBox(width: 4),
                                Text('Comment'),
                              ],
                            ),
                          ),
                        ],
                      ),
                      isEvent
                          ? TextButton(
                            onPressed: () => _toggleRsvp(postId),
                            child: Text(isRsvped ? 'Cancel RSVP' : 'RSVP'),
                          )
                          : TextButton(
                            onPressed: () {},
                            child: const Text('Visit Club'),
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
