import 'package:campus_connect/components/club_bottom_navbar.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class ClubMetricsPage extends StatefulWidget {
  final String clubId;
  const ClubMetricsPage({super.key, required this.clubId});

  @override
  State<ClubMetricsPage> createState() => _ClubMetricsPageState();
}

class _ClubMetricsPageState extends State<ClubMetricsPage> {
  final supabase = Supabase.instance.client;
  int _followerCount = 0;
  int _viewCount = 0;
  double _avgLikes = 0;
  int _totalComments = 0;
  double _engagementRate = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMetrics();
  }

  Future<void> _loadMetrics() async {
    try {
      final clubData =
          await supabase
              .from('clubs')
              .select('followers, view_count')
              .eq('id', widget.clubId)
              .single();

      final followerCount = clubData['followers'] as int;
      final viewCount = clubData['view_count'] ?? 0;

      final posts = await supabase
          .from('posts')
          .select('id')
          .eq('club_id', widget.clubId);

      final postIds = (posts as List).map((p) => p['id'] as String).toList();

      double avgLikes = 0;
      int totalComments = 0;

      if (postIds.isNotEmpty) {
        final likes = await supabase
            .from('likes')
            .select('post_id')
            .inFilter('post_id', postIds);

        final postLikeCounts = <String, int>{for (var id in postIds) id: 0};
        for (final like in likes as List) {
          final postId = like['post_id'] as String;
          if (postLikeCounts.containsKey(postId)) {
            postLikeCounts[postId] = postLikeCounts[postId]! + 1;
          }
        }

        final totalLikes = postLikeCounts.values.fold(0, (a, b) => a + b);
        avgLikes = totalLikes / postIds.length;

        final comments = await supabase
            .from('comments')
            .select('post_id')
            .inFilter('post_id', postIds);

        totalComments = (comments as List).length;

        final totalEngagements = totalLikes + totalComments;
        final engagementRate =
            followerCount > 0 ? totalEngagements / followerCount : 0;

        setState(() {
          _followerCount = followerCount;
          _viewCount = viewCount;
          _avgLikes = avgLikes;
          _totalComments = totalComments;
          _engagementRate = engagementRate.toDouble();
          _loading = false;
        });
      } else {
        setState(() {
          _followerCount = followerCount;
          _viewCount = viewCount;
          _avgLikes = 0;
          _totalComments = 0;
          _engagementRate = 0;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading metrics: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    await supabase.auth.signOut();
    if (context.mounted) {
      Navigator.pushReplacementNamed(context, '/auth');
    }
  }

  Color _getEngagementColor(double rate) {
    if (rate >= 2.0) return Colors.green;
    if (rate >= 1.0) return Colors.orange;
    return Colors.red;
  }

  Widget _buildMetricTile(String label, String value, {Color? color}) {
    return ShadCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color ?? ShadTheme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart() {
    final double likesValue = _avgLikes;
    final double engagementValue = _engagementRate;
    final double followersValue = _followerCount.toDouble();

    final maxValue = [
      followersValue,
      likesValue,
      engagementValue,
    ].reduce((a, b) => a > b ? a : b);
    double _scale(double value) => maxValue > 0 ? (value / maxValue) * 100 : 0;

    final barData = [
      BarChartGroupData(
        x: 0,
        barRods: [
          BarChartRodData(
            toY: _scale(followersValue),
            color: Colors.blue,
            width: 18,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
      BarChartGroupData(
        x: 1,
        barRods: [
          BarChartRodData(
            toY: _scale(likesValue),
            color: Colors.green,
            width: 18,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
      BarChartGroupData(
        x: 2,
        barRods: [
          BarChartRodData(
            toY: _scale(engagementValue),
            color: Colors.orange,
            width: 18,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    ];

    return ShadCard(
      child: SizedBox(
        height: 220,
        child: BarChart(
          BarChartData(
            barGroups: barData,
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  getTitlesWidget: (value, _) {
                    switch (value.toInt()) {
                      case 0:
                        return const Text('Followers');
                      case 1:
                        return const Text('Likes');
                      case 2:
                        return const Text('Engage');
                      default:
                        return const Text('');
                    }
                  },
                ),
              ),
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            barTouchData: BarTouchData(
              enabled: true,
              touchTooltipData: BarTouchTooltipData(
                tooltipPadding: const EdgeInsets.all(8),
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  String metric;
                  double rawValue;

                  switch (group.x) {
                    case 0:
                      metric = 'Followers';
                      rawValue = followersValue;
                      break;
                    case 1:
                      metric = 'Likes';
                      rawValue = likesValue;
                      break;
                    case 2:
                      metric = 'Engage';
                      rawValue = engagementValue;
                      break;
                    default:
                      metric = '';
                      rawValue = 0;
                  }

                  return BarTooltipItem(
                    '$metric\n${rawValue.toStringAsFixed(2)}',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
              ),
            ),
            gridData: FlGridData(show: true),
            borderData: FlBorderData(show: false),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Club Metrics'),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: ListView(
                  children: [
                    const Text(
                      '📊 Metrics Overview',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildMetricTile(
                      'Follower Count',
                      _followerCount.toString(),
                    ),
                    SizedBox(height: 10),
                    _buildMetricTile('Page Views', _viewCount.toString()),
                    _buildMetricTile(
                      'Avg Likes/Post',
                      _avgLikes.toStringAsFixed(2),
                    ),
                    SizedBox(height: 10),
                    _buildMetricTile(
                      'Total Comments',
                      _totalComments.toString(),
                    ),
                    SizedBox(height: 10),
                    _buildMetricTile(
                      'Engagement Rate',
                      _engagementRate.toStringAsFixed(2),
                      color: _getEngagementColor(_engagementRate),
                    ),
                    SizedBox(height: 5),
                    _buildChart(),
                  ],
                ),
              ),
      bottomNavigationBar: ClubBottomNavBar(
        currentIndex: 2,
        clubId: widget.clubId,
      ),
    );
  }
}
