import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import '../providers/music_providers.dart';

class UploadSongPage extends ConsumerStatefulWidget {
  const UploadSongPage({super.key});

  @override
  ConsumerState<UploadSongPage> createState() => _UploadSongPageState();
}

class _UploadSongPageState extends ConsumerState<UploadSongPage> {
  final _titleController = TextEditingController();
  final _artistController = TextEditingController();
  final _albumController = TextEditingController();
  PlatformFile? _audioFile;
  PlatformFile? _coverImage;
  bool _isUploading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _artistController.dispose();
    _albumController.dispose();
    super.dispose();
  }

  Future<void> _pickAudio() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.audio);
    if (result != null) setState(() => _audioFile = result.files.first);
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null) setState(() => _coverImage = result.files.first);
  }

  Future<void> _upload() async {
    if (_titleController.text.isEmpty || _artistController.text.isEmpty || _audioFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title, Artist, and Audio File are required')),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final dio = ref.read(dioProvider);
      final formData = FormData.fromMap({
        'title': _titleController.text,
        'artist': _artistController.text,
        'album': _albumController.text,
        'audio_file': await MultipartFile.fromFile(
          _audioFile!.path!,
          filename: _audioFile!.name,
        ),
      });

      if (_coverImage != null) {
        formData.files.add(MapEntry(
          'cover_image',
          await MultipartFile.fromFile(_coverImage!.path!, filename: _coverImage!.name),
        ));
      }

      final response = await dio.post('/songs/upload', data: formData);
      if (response.statusCode == 200) {
        ref.invalidate(onlineSongsProvider);
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Upload successful!'),
              backgroundColor: Color(0xFF1DB954),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: ${e.toString().replaceFirst('Exception: ', '')}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Upload Song',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cover image picker
            GestureDetector(
              onTap: _pickImage,
              child: Center(
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    color: const Color(0xFF282828),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _coverImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            _coverImage!.path!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stack) => const Icon(
                              Icons.add_photo_alternate_outlined,
                              color: Color(0xFFB3B3B3),
                              size: 40,
                            ),
                          ),
                        )
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_outlined, color: Color(0xFFB3B3B3), size: 40),
                            SizedBox(height: 8),
                            Text('Add Cover', style: TextStyle(color: Color(0xFFB3B3B3), fontSize: 13)),
                          ],
                        ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            _UploadField(controller: _titleController, label: 'Song Title'),
            const SizedBox(height: 16),
            _UploadField(controller: _artistController, label: 'Artist'),
            const SizedBox(height: 16),
            _UploadField(controller: _albumController, label: 'Album (optional)'),
            const SizedBox(height: 24),
            // Audio file picker
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(
                  color: _audioFile != null ? const Color(0xFF1DB954) : const Color(0xFF727272),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
              onPressed: _pickAudio,
              icon: Icon(
                _audioFile != null ? Icons.check_circle : Icons.audiotrack,
                color: _audioFile != null ? const Color(0xFF1DB954) : const Color(0xFFB3B3B3),
              ),
              label: Text(
                _audioFile == null ? 'Select Audio File' : _audioFile!.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 40),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1DB954),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: const StadiumBorder(),
              ),
              onPressed: _isUploading ? null : _upload,
              child: _isUploading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                    )
                  : const Text(
                      'Upload',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UploadField extends StatelessWidget {
  const _UploadField({required this.controller, required this.label});
  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFFB3B3B3)),
        filled: true,
        fillColor: const Color(0xFF2A2A2A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: Color(0xFF1DB954), width: 2),
        ),
      ),
    );
  }
}
