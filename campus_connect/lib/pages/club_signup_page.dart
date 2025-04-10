import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ClubSignUpPage extends StatefulWidget {
  const ClubSignUpPage({super.key});

  @override
  State<ClubSignUpPage> createState() => _ClubSignUpPageState();
}

class _ClubSignUpPageState extends State<ClubSignUpPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();

  final supabase = Supabase.instance.client;

  Future<void> _signUpClub() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final description = _descriptionController.text.trim();
    final categoryText = _categoryController.text.trim();

    // Allow multiple categories separated by commas
    final categories =
        categoryText
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();

    try {
      final response = await supabase.auth.signUp(
        email: email,
        password: password,
      );

      final user = response.user;

      if (user != null) {
        await supabase.from('clubs').insert({
          'id': user.id,
          'name': name,
          'email': email,
          'description': description,
          'category': categories,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Club sign up successful!')),
          );
          // You could navigate to club dashboard here
        }
      } else {
        throw Exception('User was not created.');
      }
    } catch (error) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Sign up failed: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Club Sign Up')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Club Name'),
            ),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            TextField(
              controller: _categoryController,
              decoration: const InputDecoration(
                labelText: 'Categories (comma-separated)',
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _signUpClub,
              child: const Text('Sign Up'),
            ),
          ],
        ),
      ),
    );
  }
}
