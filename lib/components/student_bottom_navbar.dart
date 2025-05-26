// shared/bottom_nav_bar.dart
import 'package:flutter/material.dart';
import '../pages/student_home_page.dart';
import '../pages/discover_clubs_page.dart';
import '../pages/profile_page.dart';

class StudentBottomNavBar extends StatelessWidget {
  final int currentIndex;

  const StudentBottomNavBar({super.key, required this.currentIndex});

  void _navigateTo(int index, BuildContext context) {
    Widget destination;
    switch (index) {
      case 0:
        destination = const StudentHomePage();
        break;
      case 1:
        destination = const DiscoverClubsPage();
        break;
      case 2:
        destination = const ProfilePage();
        break;
      default:
        return;
    }

    if (ModalRoute.of(context)?.settings.name !=
        destination.runtimeType.toString()) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => destination),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) => _navigateTo(index, context),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Discover'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
    );
  }
}
