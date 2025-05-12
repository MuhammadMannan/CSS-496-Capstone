import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
      final response = await supabase.storage
          .from('post-images')
          .uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(
              upsert: true,
              contentType: 'image/jpeg',
            ),
          );

      print('🖼️ Upload response: $response');

      final publicUrl = supabase.storage.from('post-images').getPublicUrl(path);
      print('🌐 Public URL: $publicUrl');
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title and content are required.')),
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

      print('🧠 Post Insert Response: $insertResponse');

      final postId = insertResponse['id'] as String;

      if (_imageFile != null) {
        final imageUrl = await _uploadImage(postId);
        if (imageUrl != null) {
          await supabase
              .from('posts')
              .update({'image_url': imageUrl})
              .eq('id', postId);
          print('✅ Post updated with image URL');
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post created successfully!')),
      );

      _resetForm();
    } catch (e) {
      print('🔥 Error creating post: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to create post: $e')));
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

    return Scaffold(
      appBar: AppBar(title: const Text('Create Post')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Post Title'),
            ),
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(labelText: 'Post Content'),
              maxLines: 5,
            ),
            const SizedBox(height: 12),
            DropdownButton<String>(
              value: _label,
              onChanged: (value) => setState(() => _label = value!),
              items: const [
                DropdownMenuItem(
                  value: 'announcement',
                  child: Text('Announcement'),
                ),
                DropdownMenuItem(value: 'event', child: Text('Event')),
              ],
            ),
            if (isEvent)
              Column(
                children: [
                  const SizedBox(height: 12),
                  TextButton(
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
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.photo),
              label: const Text('Add Image (optional)'),
            ),
            if (_imageFile != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Image.file(_imageFile!, height: 150),
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isUploading ? null : _submitPost,
              child:
                  _isUploading
                      ? const CircularProgressIndicator()
                      : const Text('Post'),
            ),
          ],
        ),
      ),
    );
  }
}
