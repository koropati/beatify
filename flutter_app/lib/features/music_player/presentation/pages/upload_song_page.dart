import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import '../../domain/entities/song_entity.dart';
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

  Future<void> _pickAudio() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
    );

    if (result != null) {
      setState(() {
        _audioFile = result.files.first;
      });
    }
  }

  Future<void> _pickImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );

    if (result != null) {
      setState(() {
        _coverImage = result.files.first;
      });
    }
  }

  Future<void> _upload() async {
    if (_titleController.text.isEmpty || _artistController.text.isEmpty || _audioFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Title, Artist, and Audio File are required')));
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      final dio = ref.read(dioProvider);

      FormData formData = FormData.fromMap({
        'title': _titleController.text,
        'artist': _artistController.text,
        'album': _albumController.text,
        'audio_file': await MultipartFile.fromFile(_audioFile!.path!, filename: _audioFile!.name),
      });

      if (_coverImage != null) {
        formData.files.add(MapEntry(
          'cover_image',
          await MultipartFile.fromFile(_coverImage!.path!, filename: _coverImage!.name),
        ));
      }

      final response = await dio.post('/songs/upload', data: formData);
      
      if (response.statusCode == 200) {
        // Refresh online songs
        ref.invalidate(onlineSongsProvider);
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Upload successful!')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: \$e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Song')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _artistController,
              decoration: const InputDecoration(labelText: 'Artist', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _albumController,
              decoration: const InputDecoration(labelText: 'Album (Optional)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _pickAudio,
              icon: const Icon(Icons.audiotrack),
              label: Text(_audioFile == null ? 'Select MP3 File' : _audioFile!.name),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade800),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.image),
              label: Text(_coverImage == null ? 'Select Cover Image (Optional)' : _coverImage!.name),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade800),
            ),
            const SizedBox(height: 48),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1DB954),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: _isUploading ? null : _upload,
              child: _isUploading
                  ? const CircularProgressIndicator(color: Colors.black)
                  : const Text('Upload', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
