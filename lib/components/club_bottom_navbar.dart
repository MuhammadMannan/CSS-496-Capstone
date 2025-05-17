// components/club_bottom_navbar.dart
import 'package:flutter/material.dart';
import '../pages/club_post_page.dart';
import '../pages/club_profile_page.dart';
import '../pages/club_metrics_page.dart';

class ClubBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final String clubId;

  const ClubBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.clubId,
  });

  void _onItemTapped(BuildContext context, int index) {
    if (index == currentIndex) return;

    Widget page;
    switch (index) {
      case 0:
        page = const ClubPostPage();
        break;
      case 1:
        page = const ClubProfilePage();
        break;
      case 2:
        page = ClubMetricsPage(clubId: clubId);
        break;
      default:
        return;
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => page),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) => _onItemTapped(context, index),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Post'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Metrics'),
      ],
    );
  }
}
