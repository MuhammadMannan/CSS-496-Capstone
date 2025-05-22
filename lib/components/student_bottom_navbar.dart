import 'package:flutter/material.dart';
import '../pages/student_home_page.dart';
import '../pages/discover_clubs_page.dart';
import '../pages/profile_page.dart';

class StudentBottomNavBar extends StatelessWidget {
  final int currentIndex;

  const StudentBottomNavBar({super.key, required this.currentIndex});

  void _navigateTo(int index, BuildContext context) {
  if (index == currentIndex) return;

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

  Navigator.pushReplacement(
    context,
    PageRouteBuilder(
      pageBuilder: (_, __, ___) => destination,
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
    ),
  );
}


  @override
  Widget build(BuildContext context) {
    const iconData = [
      Icons.home,
      Icons.search,
      Icons.person,
    ];
    const labels = [
      'Home',
      'Discover',
      'Profile',
    ];
    final gradients = [
      [Colors.deepPurple, Colors.purpleAccent],
      [Colors.teal, Colors.lightBlueAccent],
      [Colors.indigo, Colors.greenAccent],
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        boxShadow: const [BoxShadow(blurRadius: 6, color: Colors.black12)],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(3, (index) {
          final isSelected = index == currentIndex;
          return GestureDetector(
            onTap: () => _navigateTo(index, context),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(colors: gradients[index])
                    : null,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    iconData[index],
                    color: isSelected ? Colors.white : Colors.grey[800],
                  ),
                  Text(
                    labels[index],
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[800],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
