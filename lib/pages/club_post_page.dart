import 'package:flutter/material.dart';

class ClubPostPage extends StatelessWidget {
  const ClubPostPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Post')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            const TextField(
              decoration: InputDecoration(labelText: 'Post Title'),
            ),
            const TextField(
              decoration: InputDecoration(labelText: 'Post Content'),
              maxLines: 5,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Implement post creation logic here
              },
              child: const Text('Post'),
            ),
          ],
        ),
      ),
    );
  }
}
