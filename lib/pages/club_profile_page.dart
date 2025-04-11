import 'package:flutter/material.dart';

class ClubProfilePage extends StatelessWidget {
  const ClubProfilePage({super.key});

  void _logout(BuildContext context) {
    // Implement your logout logic here
    // For example: FirebaseAuth.instance.signOut();
    // Then navigate to login page
    Navigator.of(context).pushReplacementNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // Implement logout functionality here
              Navigator.popUntil(context, (route) => route.isFirst);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Club Name',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text('Description: This is a brief description of the club.'),
            const SizedBox(height: 20),
            const Text('Members: 150'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Implement edit profile logic here
              },
              child: const Text('Edit Profile'),
            ),
          ],
        ),
      ),
    );
  }
}
