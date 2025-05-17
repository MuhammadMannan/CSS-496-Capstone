import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:campus_connect/components/club_bottom_navbar.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'dart:io';

class ClubPostPage extends StatefulWidget {
  const ClubPostPage({super.key});

  @override
  State<ClubPostPage> createState() => _ClubPostPageState();
}

class _ClubPostPageState extends State<ClubPostPage> {
  final supabase = Supabase.instance.client;
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String _label = 'announcement';
  DateTime? _eventDateTime;
  File? _imageFile;
  bool _isUploading = false;
  final _picker = ImagePicker();

  final postTypes = {'announcement': 'Announcement', 'event': 'Event'};

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _imageFile = File(picked.path));
    }
  }

  Future<String?> _uploadImage(String postId) async {
    if (_imageFile == null) return null;

    final path = 'posts/$postId.jpg';
    final bytes = await _imageFile!.readAsBytes();

    try {
      await supabase.storage
          .from('post-images')
          .uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(
              upsert: true,
              contentType: 'image/jpeg',
            ),
          );

      final publicUrl = supabase.storage.from('post-images').getPublicUrl(path);
      return publicUrl;
    } catch (e) {
      print('🚫 Upload failed: $e');
      return null;
    }
  }

  Future<void> _submitPost() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty || content.isEmpty) {
      ShadToaster.of(context).show(
        const ShadToast(
          title: Text('Missing Fields'),
          description: Text('Title and content are required.'),
        ),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      DateTime? utcEventDateTime;
      if (_label == 'event' && _eventDateTime != null) {
        utcEventDateTime = _eventDateTime!.toUtc();
      }

      final insertResponse =
          await supabase
              .from('posts')
              .insert({
                'club_id': user.id,
                'title': title,
                'caption': content,
                'label': _label,
                'event_datetime': utcEventDateTime?.toIso8601String(),
              })
              .select()
              .single();

      final postId = insertResponse['id'] as String;

      if (_imageFile != null) {
        final imageUrl = await _uploadImage(postId);
        if (imageUrl != null) {
          await supabase
              .from('posts')
              .update({'image_url': imageUrl})
              .eq('id', postId);
        }
      }

      ShadToaster.of(context).show(
        const ShadToast(
          title: Text('Success'),
          description: Text('Post created successfully!'),
        ),
      );

      _resetForm();
    } catch (e) {
      print('🔥 Error creating post: $e');
      ShadToaster.of(context).show(
        ShadToast.destructive(
          title: const Text('Error'),
          description: Text('Failed to create post: $e'),
        ),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  void _resetForm() {
    setState(() {
      _titleController.clear();
      _contentController.clear();
      _label = 'announcement';
      _eventDateTime = null;
      _imageFile = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEvent = _label == 'event';
    final userId = supabase.auth.currentUser?.id ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Create Post')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ShadInput(
              controller: _titleController,
              placeholder: const Text('Post Title'),
            ),
            const SizedBox(height: 16),
            ShadTextarea(
              controller: _contentController,
              placeholder: const Text('Post Content'),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ShadSelect<String>(
                    placeholder: const Text('Select Post Type'),
                    initialValue: _label,
                    onChanged:
                        (value) =>
                            setState(() => _label = value ?? 'announcement'),
                    options: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(32, 6, 6, 6),
                        child: Text(
                          'Post Types',
                          style: ShadTheme.of(context).textTheme.muted.copyWith(
                            fontWeight: FontWeight.w600,
                            color:
                                ShadTheme.of(
                                  context,
                                ).colorScheme.popoverForeground,
                          ),
                          textAlign: TextAlign.start,
                        ),
                      ),
                      ...postTypes.entries.map(
                        (e) => ShadOption(value: e.key, child: Text(e.value)),
                      ),
                    ],
                    selectedOptionBuilder:
                        (context, value) => Text(postTypes[value] ?? ''),
                  ),
                ),
                const SizedBox(width: 12),
                ShadIconButton(
                  icon: const Icon(Icons.photo),
                  onPressed: _pickImage,
                ),
              ],
            ),
            if (isEvent)
              Column(
                children: [
                  const SizedBox(height: 16),
                  ShadButton(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2024),
                        lastDate: DateTime(2030),
                      );
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (date != null && time != null) {
                        setState(() {
                          _eventDateTime = DateTime(
                            date.year,
                            date.month,
                            date.day,
                            time.hour,
                            time.minute,
                          );
                        });
                      }
                    },
                    child: Text(
                      _eventDateTime == null
                          ? 'Select Event Date & Time'
                          : 'Event: $_eventDateTime',
                    ),
                  ),
                ],
              ),
            if (_imageFile != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Image.file(_imageFile!, height: 150),
              ),
            const SizedBox(height: 24),
            ShadButton(
              onPressed: _isUploading ? null : _submitPost,
              child:
                  _isUploading
                      ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Text('Post'),
            ),
          ],
        ),
      ),
      bottomNavigationBar: ClubBottomNavBar(currentIndex: 0, clubId: userId),
    );
  }
}
