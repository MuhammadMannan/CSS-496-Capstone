import 'package:flutter/material.dart';
import 'club_post_page.dart';
import 'club_profile_page.dart';

class ClubMainPage extends StatefulWidget {
  const ClubMainPage({super.key});

  @override
  _ClubMainPageState createState() => _ClubMainPageState();
}

class _ClubMainPageState extends State<ClubMainPage> {
  int _selectedIndex = 0;

  static final List<Widget> _pages = <Widget>[
    ClubPostPage(),
    ClubProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.post_add), label: 'Post'),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
