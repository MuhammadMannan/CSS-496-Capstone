// Combined Login & Sign-Up Page for Students and Clubs

import 'package:flutter/material.dart'; // done by Muhammad
import 'package:supabase_flutter/supabase_flutter.dart'; // done by Muhammad
import 'student_home_page.dart'; // done by Muhammad
import 'club_main_page.dart'; // done by Muhammad
import 'package:shadcn_ui/shadcn_ui.dart'; // done by Muhammad

class UnifiedAuthPage extends StatefulWidget {
  const UnifiedAuthPage({super.key});

  @override
  State<UnifiedAuthPage> createState() => _UnifiedAuthPageState();
}

class _UnifiedAuthPageState extends State<UnifiedAuthPage> {
  final supabase = Supabase.instance.client;

  bool obscure = true;
  String _selectedTab = 'login';
  String _role = 'student';

  final roles = {'student': 'Student', 'club': 'Club'};

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _studentIdNumberController = TextEditingController();
  final _descriptionController = TextEditingController();

  List<String> _selectedCategories = []; // ✅ Multi-select list
  String _searchValue = '';

  // Club categories (preset list)
  static const clubCategories = {
    'tech': 'Technology',
    'business': 'Business',
    'cybersecurity': 'Cybersecurity',
    'data': 'Data & Analytics',
    'medical': 'Medical & Health',
    'science': 'Science & Engineering',
    'arts': 'Arts & Media',
    'culture': 'Cultural & Identity',
    'sports': 'Sports & Fitness',
    'gaming': 'Gaming & eSports',
    'hobbies': 'Hobbies & Special Interest',
    'environment': 'Environmental & Sustainability',
    'volunteering': 'Volunteering & Service',
    'leadership': 'Leadership & Professional Dev',
  };

  Map<String, String> get _filteredCategories => {
    for (final entry in clubCategories.entries)
      if (entry.value.toLowerCase().contains(_searchValue.toLowerCase()))
        entry.key: entry.value,
  };

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
          final studentIdNumber = _studentIdNumberController.text.trim();
          if (studentIdNumber.isEmpty) {
            ShadToast.destructive(
              title: const Text('Error'),
              description: const Text('Student ID number is required.'),
            );
            return;
          }

          await supabase.from('students').insert({
            'id': user.id,
            'full_name': name,
            'email': email,
            'student_id_number': studentIdNumber,
            'following_clubs': [],
          });

          ShadToast(
            title: const Text('Success'),
            description: const Text('Student sign up successful!'),
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const StudentHomePage()),
          );
        } else {
          final description = _descriptionController.text.trim();

          if (_selectedCategories.isEmpty) {
            ShadToast.destructive(
              title: const Text('Error'),
              description: const Text(
                'Please select at least one category for your club.',
              ),
            );
            return;
          }

          await supabase.from('clubs').insert({
            'id': user.id,
            'name': name,
            'email': email,
            'description': description,
            'category': _selectedCategories, // ✅ now a list
          });

          ShadToast(
            title: const Text('Success'),
            description: const Text('Club sign up successful!'),
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const ClubMainPage()),
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
            title: const Text('Error'),
            description: const Text('User role not found.'),
          );
          await supabase.auth.signOut();
        }
      }
    } catch (e) {
      ShadToast.destructive(
        title: const Text('Error'),
        description: Text(e.toString()),
      );
    }
  }

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

  Widget _buildInputField({
    required TextEditingController controller,
    required String placeholder,
    bool isPassword = false,
  }) {
    return ShadInput(
      controller: controller,
      placeholder: Text(placeholder),
      obscureText: isPassword ? obscure : false,
      leading:
          isPassword
              ? const Padding(
                padding: EdgeInsets.all(4.0),
                child: Icon(LucideIcons.lock),
              )
              : null,
      trailing:
          isPassword
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

  Widget _buildMultiCategorySelect() {
    final theme = ShadTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Club Categories',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ShadSelect<String>.multiple(
          minWidth: 340,
          allowDeselection: true,
          closeOnSelect: false,
          placeholder: const Text('Select multiple categories'),
          onChanged: (values) {
            setState(() {
              _selectedCategories = values;
              debugPrint('✅ Selected categories: $_selectedCategories');
            });
          },
          options: [
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 6, 6, 6),
              child: Text(
                'Categories',
                style: theme.textTheme.large,
                textAlign: TextAlign.start,
              ),
            ),
            ...clubCategories.entries.map(
              (entry) => ShadOption(value: entry.key, child: Text(entry.value)),
            ),
          ],
          selectedOptionsBuilder: (context, values) {
            if (values.isEmpty) {
              return const Text('Select multiple categories');
            }
            return Text(
              values.map((v) => clubCategories[v] ?? v).join(', '),
              overflow: TextOverflow.ellipsis,
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isStudent = _role == 'student';
    return Scaffold(
      appBar: AppBar(title: const Text('UWB Flock')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ShadTabs<String>(
          value: _selectedTab,
          onChanged: (value) => setState(() => _selectedTab = value),
          tabBarConstraints: const BoxConstraints(maxWidth: 500),
          contentConstraints: const BoxConstraints(maxWidth: 500),
          tabs: [
            ShadTab(
              value: 'login',
              content: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [const Text('I am a '), _buildRoleSelect()],
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
                    child: const Text('Login'),
                  ),
                ],
              ),
              child: const Text('Login'),
            ),
            ShadTab(
              value: 'signup',
              content: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [const Text('I am a '), _buildRoleSelect()],
                  ),
                  const SizedBox(height: 12),
                  _buildInputField(
                    controller: _nameController,
                    placeholder: isStudent ? 'Name' : 'Club Name',
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
                  if (isStudent)
                    _buildInputField(
                      controller: _studentIdNumberController,
                      placeholder: 'Student ID Number',
                    ),
                  if (!isStudent)
                    ShadInput(
                      controller: _descriptionController,
                      placeholder: const Text('Description'),
                      minLines: 3,
                      maxLines: 6,
                    ),
                  if (!isStudent) ...[
                    const SizedBox(height: 16),
                    _buildMultiCategorySelect(),
                  ],
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
