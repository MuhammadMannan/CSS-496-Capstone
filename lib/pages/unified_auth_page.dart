// Unified Login & Sign-Up Page for both Students and Clubs

import 'package:campus_connect/pages/club_post_page.dart';
import 'package:flutter/material.dart'; // Flutter core UI toolkit
import 'package:supabase_flutter/supabase_flutter.dart'; // Supabase for auth and backend
import 'student_home_page.dart'; // Student landing page
import 'package:shadcn_ui/shadcn_ui.dart'; // ShadCN UI component library
import 'package:image_picker/image_picker.dart'; // For picking logo images
import 'dart:io'; // For handling file input (image files)

class UnifiedAuthPage extends StatefulWidget {
  const UnifiedAuthPage({super.key});

  @override
  State<UnifiedAuthPage> createState() => _UnifiedAuthPageState();
}

class _UnifiedAuthPageState extends State<UnifiedAuthPage> {
  final supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();

  // UI state variables
  bool obscure = true; // Password visibility toggle
  String _selectedTab = 'login'; // Current selected tab (login/signup)
  String _role = 'student'; // Default selected role

  // Role options
  final roles = {'student': 'Student', 'club': 'Club'};

  // Form input controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _studentIdNumberController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _meetingTimesController = TextEditingController();

  // Club-specific input
  List<String> _selectedCategories = [];
  final String _searchValue = ''; // Future support for category search
  File? _logoFile; // Club logo file reference

  // Predefined categories for clubs
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

  // Filter categories by search (placeholder logic for future enhancement)
  Map<String, String> get _filteredCategories => {
    for (final entry in clubCategories.entries)
      if (entry.value.toLowerCase().contains(_searchValue.toLowerCase()))
        entry.key: entry.value,
  };

  // Opens the image picker and stores the selected image file
  Future<void> _pickLogoImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _logoFile = File(picked.path));
    }
  }

  // Uploads the club logo to Supabase Storage and returns public URL
  Future<String?> _uploadLogo(String clubId) async {
    if (_logoFile == null) return null;

    final path = 'club-logos/$clubId.jpg';
    final bytes = await _logoFile!.readAsBytes();

    try {
      await supabase.storage
          .from('club-logos')
          .uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(
              upsert: true,
              contentType: 'image/jpeg',
            ),
          );

      return supabase.storage.from('club-logos').getPublicUrl(path);
    } catch (e) {
      debugPrint('🚫 Logo upload failed: $e');
      return null;
    }
  }

  // Checks if user is in students or clubs table and returns their role
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

  // Handles form submission for login or signup based on `isSignUp` flag
  Future<void> _submit({required bool isSignUp}) async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final toaster = ShadToaster.of(context);

    // Restrict student emails to @uw.edu domain
    if (_role == 'student' && !email.endsWith('@uw.edu')) {
      toaster.show(
        const ShadToast.destructive(
          title: Text('Invalid Email'),
          description: Text(
            'Please use your @uw.edu email address to sign up.',
          ),
        ),
      );
      return;
    }

    try {
      if (isSignUp) {
        // Sign-up flow
        final response = await supabase.auth.signUp(
          email: email,
          password: password,
        );
        final user = response.user;
        if (user == null) throw Exception("Sign up failed");

        final name = _nameController.text.trim();

        if (_role == 'student') {
          // Student signup
          final studentIdNumber = _studentIdNumberController.text.trim();
          if (studentIdNumber.isEmpty) {
            toaster.show(
              const ShadToast.destructive(
                title: Text('Error'),
                description: Text('Student ID number is required.'),
              ),
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

          toaster.show(
            const ShadToast(
              title: Text('Success'),
              description: Text('Student sign up successful!'),
            ),
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const StudentHomePage()),
          );
        } else {
          // Club signup
          final description = _descriptionController.text.trim();
          final recurringMeetings = _meetingTimesController.text.trim();

          if (_selectedCategories.isEmpty) {
            toaster.show(
              const ShadToast.destructive(
                title: Text('Error'),
                description: Text(
                  'Please select at least one category for your club.',
                ),
              ),
            );
            return;
          }

          final logoUrl = await _uploadLogo(user.id);

          await supabase.from('clubs').insert({
            'id': user.id,
            'name': name,
            'email': email,
            'description': description,
            'category': _selectedCategories,
            'logo_url': logoUrl,
            'recurring_meeting_times': recurringMeetings,
          });

          toaster.show(
            const ShadToast(
              title: Text('Success'),
              description: Text('Club sign up successful!'),
            ),
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const ClubPostPage()),
          );
        }
      } else {
        // Login flow
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
            MaterialPageRoute(builder: (_) => const ClubPostPage()),
          );
        } else {
          toaster.show(
            const ShadToast.destructive(
              title: Text('Error'),
              description: Text('User role not found.'),
            ),
          );
          await supabase.auth.signOut();
        }
      }
    } catch (e) {
      // Show error message on exception
      toaster.show(
        ShadToast.destructive(
          title: const Text('Error'),
          description: Text(e.toString()),
        ),
      );
    }
  }

  // Builds role selection dropdown (Student / Club)
  Widget _buildRoleSelect() {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 180),
      child: ShadSelect<String>(
        placeholder: const Text('Select Role'),
        initialValue: _role,
        options:
            roles.entries
                .map(
                  (entry) =>
                      ShadOption(value: entry.key, child: Text(entry.value)),
                )
                .toList(),
        selectedOptionBuilder: (context, value) => Text(roles[value]!),
        onChanged: (value) {
          if (value != null) setState(() => _role = value);
        },
      ),
    );
  }

  // Reusable input builder with optional password field toggle
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

  // Multi-select dropdown for club categories
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
            setState(() => _selectedCategories = values);
            debugPrint('✅ Selected categories: $values');
          },
          options: [
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 6, 6, 6),
              child: Text('Categories', style: theme.textTheme.large),
            ),
            ...clubCategories.entries.map(
              (entry) => ShadOption(value: entry.key, child: Text(entry.value)),
            ),
          ],
          selectedOptionsBuilder: (context, values) {
            if (values.isEmpty) return const Text('Select multiple categories');
            return Text(values.map((v) => clubCategories[v] ?? v).join(', '));
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
            // Login Tab
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

            // Sign-Up Tab
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
                    const SizedBox(height: 12),
                    ShadInput(
                      controller: _meetingTimesController,
                      placeholder: const Text(
                        'Recurring Meeting Times (e.g., Wednesdays 5 PM in UW1-103)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: _pickLogoImage,
                      icon: const Icon(Icons.image),
                      label: const Text('Upload Club Logo'),
                    ),
                    if (_logoFile != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Image.file(_logoFile!, height: 100),
                      ),
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
