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
          _loading = false;
        });
        return;
      }

      final postsResponse = await supabase
          .from('posts')
          .select()
          .inFilter('club_id', followingClubs) // ✅ correct usage now
          .order('created_at', ascending: false);

      print('📦 postsResponse: $postsResponse');

      setState(() {
        _posts = List<Map<String, dynamic>>.from(postsResponse);
        _loading = false;
      });
    } catch (e) {
      print('🔥 Failed to load feed: $e');
      setState(() => _loading = false);
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
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: ListTile(
            title: Text(post['title'] ?? 'No Title'),
            subtitle: Column(
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
              ],
            ),
          ),
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
