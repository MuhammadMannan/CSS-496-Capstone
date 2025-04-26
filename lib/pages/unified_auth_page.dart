// Combined Login & Sign-Up Page for Students and Clubs

import 'package:flutter/material.dart'; // done by Muhammad
import 'package:supabase_flutter/supabase_flutter.dart'; // done by Muhammad
import 'student_home_page.dart'; // done by Muhammad
import 'club_main_page.dart'; // done by Muhammad
import 'package:shadcn_ui/shadcn_ui.dart'; // done by Muhammad

// Main StatefulWidget for unified authentication page // done by Muhammad
class UnifiedAuthPage extends StatefulWidget {
  const UnifiedAuthPage({super.key});

  @override
  State<UnifiedAuthPage> createState() => _UnifiedAuthPageState();
}

class _UnifiedAuthPageState extends State<UnifiedAuthPage> {
  final supabase = Supabase.instance.client; // done by Muhammad

  bool obscure = true; // done by Muhammad
  String _selectedTab = 'login'; // done by Muhammad
  String _role = 'student'; // done by Muhammad

  final roles = {'student': 'Student', 'club': 'Club'}; // done by Muhammad

  final _nameController = TextEditingController(); // done by Muhammad
  final _emailController = TextEditingController(); // done by Muhammad
  final _passwordController = TextEditingController(); // done by Muhammad
  final _descriptionController = TextEditingController(); // done by Muhammad
  final _categoryController = TextEditingController(); // done by Muhammad

  final List<String> _categories = []; // done by Muhammad

  // Get user role from database based on ID // done by Muhammad
  Future<String?> _getUserRole(String userId) async {
    final student = await supabase
        .from('students')
        .select('id')
        .eq('id', userId)
        .maybeSingle();
    if (student != null) return 'student';

    final club = await supabase
        .from('clubs')
        .select('id')
        .eq('id', userId)
        .maybeSingle();
    if (club != null) return 'club';

    return null;
  }

  // Handle Sign Up and Login Submission Logic // done by Muhammad
  Future<void> _submit({required bool isSignUp}) async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    try {
      if (isSignUp) {
        final response = await supabase.auth.signUp(
          email: email,
          password: password,
        );
        final user = response.user;
        if (user == null) throw Exception("Sign up failed");

        final name = _nameController.text.trim();

        if (_role == 'student') {
          await supabase.from('students').insert({
            'id': user.id,
            'full_name': name,
            'email': email,
            'following_clubs': [],
          });
          ShadToast(
            title: Text('Success'),
            description: const Text('Student sign up successful!'),
          );
        } else {
          final description = _descriptionController.text.trim();
          await supabase.from('clubs').insert({
            'id': user.id,
            'name': name,
            'email': email,
            'description': description,
            'category': _categories,
          });
          ShadToast(
            title: Text('Success'),
            description: const Text('Club sign up successful!'),
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
          ShadToast.destructive(
            title: Text('Error'),
            description: Text('User role not found.'),
          );
          await supabase.auth.signOut();
        }
      }
    } catch (e) {
      ShadToast.destructive(
        title: Text('Error'),
        description: Text(e.toString()),
      );
    }
  }

  // Handle categories input field for clubs (when user types and adds) // done by Muhammad
  void _handleCategoryInput(String value) {
    if (value.endsWith(',')) {
      final trimmed = value.replaceAll(',', '').trim();
      if (trimmed.isNotEmpty && !_categories.contains(trimmed)) {
        setState(() {
          _categories.add(trimmed);
          _categoryController.clear();
        });
      }
    }
  }

  // Dropdown for role selection (student/club) // done by moumin
  Widget _buildRoleSelect() {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 180),
      child: ShadSelect<String>(
        placeholder: const Text('Select Role'),
        initialValue: _role,
        options: [
          ...roles.entries.map(
            (entry) => ShadOption(value: entry.key, child: Text(entry.value)),
          ),
        ],
        selectedOptionBuilder: (context, value) => Text(roles[value]! ?? ''),
        onChanged: (value) {
          if (value != null) setState(() => _role = value);
        },
      ),
    );
  }

  // Reusable input field (normal or password) // done by moumin
  Widget _buildInputField({
    required TextEditingController controller,
    required String placeholder,
    bool isPassword = false,
  }) {
    return ShadInput(
      controller: controller,
      placeholder: Text(placeholder),
      obscureText: isPassword ? obscure : false,
      leading: isPassword
          ? const Padding(
              padding: EdgeInsets.all(4.0),
              child: Icon(LucideIcons.lock),
            )
          : null,
      trailing: isPassword
          ? ShadButton(
              width: 24,
              height: 24,
              padding: EdgeInsets.zero,
              decoration: const ShadDecoration(
                secondaryBorder: ShadBorder.none,
                secondaryFocusedBorder: ShadBorder.none,
              ),
              icon: Icon(obscure ? LucideIcons.eyeOff : LucideIcons.eye),
              onPressed: () => setState(() => obscure = !obscure),
            )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isStudent = _role == 'student'; // done by hrishitha
    return Scaffold(
      appBar: AppBar(title: const Text('UWB Flock')), // done by moumin
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ShadTabs<String>(
          value: _selectedTab,
          onChanged: (value) => setState(() => _selectedTab = value),
          tabBarConstraints: const BoxConstraints(maxWidth: 500),
          contentConstraints: const BoxConstraints(maxWidth: 500),
          tabs: [
            // Login Tab // done by moumin
            ShadTab(
              value: 'login',
              content: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [Text('I am a '), _buildRoleSelect()],
                  ),
                  const SizedBox(height: 12),
                  _buildInputField(
                    controller: _emailController,
                    placeholder: 'Email',
                  ),
                  _buildInputField(
                    controller: _passwordController,
                    placeholder: 'Password',
                    isPassword: true,
                  ),
                  const SizedBox(height: 20),
                  ShadButton(
                    onPressed: () => _submit(isSignUp: false),
                    child: const Text('Login'), // done by hrishitha
                  ),
                ],
              ),
              child: const Text('Login'),
            ),

            // Signup Tab // done by moumin
            ShadTab(
              value: 'signup',
              content: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [Text('I am a '), _buildRoleSelect()],
                  ),
                  const SizedBox(height: 12),
                  _buildInputField(
                    controller: _nameController,
                    placeholder: isStudent ? 'Name' : 'Club Name', // done by hrishitha
                  ),
                  _buildInputField(
                    controller: _emailController,
                    placeholder: 'Email',
                  ),
                  _buildInputField(
                    controller: _passwordController,
                    placeholder: 'Password',
                    isPassword: true,
                  ),
                  if (!isStudent)
                    ShadInput(
                      controller: _descriptionController,
                      placeholder: const Text('Description'),
                      minLines: 3,
                      maxLines: 6,
                    ),
                  if (!isStudent)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShadInput(
                          controller: _categoryController,
                          placeholder: const Text(
                            'Categories (comma-separated)',
                          ),
                          onChanged: _handleCategoryInput,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: _categories
                              .map(
                                (category) => Chip(label: Text(category)),
                              )
                              .toList(),
                        ),
                      ],
                    ),
                  const SizedBox(height: 20),
                  ShadButton(
                    onPressed: () => _submit(isSignUp: true),
                    child: const Text('Sign Up'),
                  ),
                ],
              ),
              child: const Text('Sign Up'),
            ),
          ],
        ),
      ),
    );
  }
}
