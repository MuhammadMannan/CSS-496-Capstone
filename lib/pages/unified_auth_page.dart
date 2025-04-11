// Combined Login & Sign-Up Page for Students and Clubs

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'student_home_page.dart';
import 'club_main_page.dart';

class UnifiedAuthPage extends StatefulWidget {
  const UnifiedAuthPage({super.key});

  @override
  State<UnifiedAuthPage> createState() => _UnifiedAuthPageState();
}

class _UnifiedAuthPageState extends State<UnifiedAuthPage> {
  final supabase = Supabase.instance.client;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();

  String _role = 'student'; // 'student' or 'club'
  bool _isSignUp = false;

  Future<String?> _getUserRole(String userId) async {
    final student =
        await supabase
            .from('students')
            .select('id')
            .eq('id', userId)
            .maybeSingle();

    if (student != null) return 'student';

    final club =
        await supabase
            .from('clubs')
            .select('id')
            .eq('id', userId)
            .maybeSingle();

    if (club != null) return 'club';

    return null;
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    try {
      if (_isSignUp) {
        final response = await supabase.auth.signUp(
          email: email,
          password: password,
        );

        final user = response.user;
        if (user == null) throw Exception("Sign up failed");

        if (_role == 'student') {
          final name = _nameController.text.trim();
          await supabase.from('students').insert({
            'id': user.id,
            'full_name': name,
            'email': email,
            'following_clubs': [],
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Student sign up successful!')),
          );
        } else {
          final name = _nameController.text.trim();
          final description = _descriptionController.text.trim();
          final categories =
              _categoryController.text
                  .split(',')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList();

          await supabase.from('clubs').insert({
            'id': user.id,
            'name': name,
            'email': email,
            'description': description,
            'category': categories,
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Club sign up successful!')),
          );
        }
      } else {
        final response = await supabase.auth.signInWithPassword(
          email: email,
          password: password,
        );

        final user = response.user;
        if (user == null) throw Exception("Login failed");

        final role = await _getUserRole(user.id);

        if (role == 'student') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const StudentHomePage()),
          );
        } else if (role == 'club') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const ClubMainPage()),
          );
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("User role not found.")));
          await supabase.auth.signOut();
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isStudent = _role == 'student';
    return Scaffold(
      appBar: AppBar(title: Text(_isSignUp ? 'Sign Up' : 'Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            DropdownButton<String>(
              value: _role,
              onChanged: (value) => setState(() => _role = value!),
              items: const [
                DropdownMenuItem(value: 'student', child: Text('Student')),
                DropdownMenuItem(value: 'club', child: Text('Club')),
              ],
            ),
            SwitchListTile(
              title: const Text('Sign Up'),
              value: _isSignUp,
              onChanged: (val) => setState(() => _isSignUp = val),
            ),
            if (_isSignUp)
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: isStudent ? 'Name' : 'Club Name',
                ),
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
            if (_isSignUp && !isStudent)
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
            if (_isSignUp && !isStudent)
              TextField(
                controller: _categoryController,
                decoration: const InputDecoration(
                  labelText: 'Categories (comma-separated)',
                ),
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submit,
              child: Text(_isSignUp ? 'Sign Up' : 'Login'),
            ),
          ],
        ),
      ),
    );
  }
}
