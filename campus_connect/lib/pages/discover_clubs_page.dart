import 'package:flutter/material.dart';
import 'student_home_page.dart';
import 'profile_page.dart';

class DiscoverClubsPage extends StatefulWidget {
  const DiscoverClubsPage({super.key});

  @override
  _DiscoverClubsPageState createState() => _DiscoverClubsPageState();
}

class _DiscoverClubsPageState extends State<DiscoverClubsPage> {
  int _selectedIndex = 1;

  static final List<Widget> _pages = <Widget>[
    StudentHomePage(),
    Center(child: Text('Discover Clubs Page')),
    ProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => _pages[index]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Discover Clubs')),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
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
