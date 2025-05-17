import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ClubDetailsPage extends StatefulWidget {
  final String clubId;

  const ClubDetailsPage({super.key, required this.clubId});

  @override
  State<ClubDetailsPage> createState() => _ClubDetailsPageState();
}

class _ClubDetailsPageState extends State<ClubDetailsPage> {
  final supabase = Supabase.instance.client;

  Map<String, dynamic>? _club;
  List<Map<String, dynamic>> _posts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _incrementViewCount().then((_) => _loadClubDetails());
  }

  Future<void> _incrementViewCount() async {
    try {
      await supabase.rpc(
        'increment_club_view_count',
        params: {'club_id_input': widget.clubId},
      );
    } catch (e) {
      debugPrint('Error incrementing view count: $e');
    }
  }

  Future<void> _loadClubDetails() async {
    try {
      final clubResponse =
          await supabase
              .from('clubs')
              .select()
              .eq('id', widget.clubId)
              .maybeSingle();

      final postsResponse = await supabase
          .from('posts')
          .select()
          .eq('club_id', widget.clubId)
          .order('created_at', ascending: false);

      setState(() {
        _club = clubResponse;
        _posts = List<Map<String, dynamic>>.from(postsResponse);
        _loading = false;
      });
    } catch (e) {
      print('🔥 Error loading club details: $e');
      setState(() => _loading = false);
    }
  }

  Widget _buildClubHeader() {
    if (_club == null) return const SizedBox();

    final logoUrl = _club!['logo_url'];
    final name = _club!['name'] ?? 'Unnamed Club';
    final description = _club!['description'] ?? '';
    final recurringMeetingTimes = _club!['recurring_meeting_times'];
    final categoryKeys = (_club!['category'] ?? []) as List<dynamic>;
    final categoryLabels = categoryKeys.join(', ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (logoUrl != null && logoUrl.toString().isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              logoUrl,
              width: 100,
              height: 100,
              fit: BoxFit.cover,
              errorBuilder:
                  (_, __, ___) =>
                      const Icon(Icons.image_not_supported, size: 100),
            ),
          ),
        const SizedBox(height: 12),
        Text(
          name,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          categoryLabels,
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        Text(description),
        if (recurringMeetingTimes != null &&
            recurringMeetingTimes.toString().isNotEmpty) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.calendar_today, size: 16, color: Colors.teal),
              SizedBox(width: 6),
              Text(
                'Recurring Meetings:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            recurringMeetingTimes,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Colors.teal),
          ),
        ],
        const Divider(thickness: 1),
      ],
    );
  }

  Widget _buildPostCard(Map post) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              post['title'] ?? 'Untitled',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            if (post['caption'] != null) ...[
              const SizedBox(height: 6),
              Text(post['caption']),
            ],
            if (post['image_url'] != null) ...[
              const SizedBox(height: 8),
              Image.network(post['image_url'], height: 150, fit: BoxFit.cover),
            ],
            const SizedBox(height: 6),
            Text(
              post['label']?.toUpperCase() ?? '',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Club Details')),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _loadClubDetails,
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  children: [_buildClubHeader(), ..._posts.map(_buildPostCard)],
                ),
              ),
    );
  }
}
