import 'package:campus_connect/components/student_bottom_navbar.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import '../components/flock_app_bar.dart';

class StudentHomePage extends StatefulWidget {
  const StudentHomePage({super.key});

  @override
  State<StudentHomePage> createState() => _StudentHomePageState();
}

class _StudentHomePageState extends State<StudentHomePage> {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _posts = [];
  Set<String> _rsvpedPostIds = {};
  Set<String> _likedPostIds = {};
  Map<String, int> _likeCounts = {};
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
          _likedPostIds.clear();
          _likeCounts.clear();
          _loading = false;
        });
        return;
      }

      final postsResponse = await supabase
          .from('posts')
          .select('*, clubs:club_id(name, logo_url), event_datetime')
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

      final likeResponse = await supabase
          .from('likes')
          .select('post_id')
          .eq('student_id', user.id);

      final likedPostIds =
          (likeResponse as List<dynamic>)
              .map((e) => e['post_id'] as String)
              .toSet();

      final allLikesResponse = await supabase.from('likes').select('post_id');

      final likeCounts = <String, int>{};
      for (final item in allLikesResponse) {
        final pid = item['post_id'] as String;
        likeCounts[pid] = (likeCounts[pid] ?? 0) + 1;
      }

      setState(() {
        _posts = postList;
        _rsvpedPostIds = rsvpPostIds;
        _likedPostIds = likedPostIds;
        _likeCounts = likeCounts;
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

  Future<void> _toggleLike(String postId) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final isLiked = _likedPostIds.contains(postId);

    try {
      if (isLiked) {
        await supabase
            .from('likes')
            .delete()
            .eq('post_id', postId)
            .eq('student_id', user.id);
      } else {
        await supabase.from('likes').insert({
          'post_id': postId,
          'student_id': user.id,
        });
      }
      _loadFeed();
    } catch (e) {
      debugPrint('❌ Error toggling like: $e');
    }
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
        final isLiked = _likedPostIds.contains(postId);
        final likeCount = _likeCounts[postId] ?? 0;

        final club = post['clubs'];
        final logoUrl = club != null ? club['logo_url'] : null;

        final eventDateTimeRaw = post['event_datetime'];
        String? formattedEventDate;
        if (isEvent && eventDateTimeRaw != null) {
          try {
            final eventDateTime = DateTime.parse(eventDateTimeRaw).toLocal();
            formattedEventDate = DateFormat(
              'EEEE, MMM d • h:mm a',
            ).format(eventDateTime);
          } catch (_) {
            formattedEventDate = null;
          }
        }

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
                if (isEvent && formattedEventDate != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 4,
                    ),
                    child: Text(
                      'Event: $formattedEventDate',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
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
                          GestureDetector(
                            onTap: () => _toggleLike(postId),
                            child: Icon(
                              isLiked ? Icons.favorite : Icons.favorite_border,
                              color: isLiked ? Colors.red : null,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(likeCount.toString()),
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
      appBar: const FlockAppBar(),
      body: _buildFeed(),
      bottomNavigationBar: StudentBottomNavBar(currentIndex: 0),
    );
  }
}
