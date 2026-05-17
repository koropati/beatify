import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../providers/music_providers.dart';

final playlistsProvider = FutureProvider((ref) async {
  final dio = ref.read(dioProvider);
  final response = await dio.get('/playlists');
  return response.data as List<dynamic>;
});

class PlaylistsPage extends ConsumerStatefulWidget {
  const PlaylistsPage({super.key});

  @override
  ConsumerState<PlaylistsPage> createState() => _PlaylistsPageState();
}

class _PlaylistsPageState extends ConsumerState<PlaylistsPage> {

  Future<void> _createPlaylist() async {
    final TextEditingController nameController = TextEditingController();
    
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('New Playlist'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(hintText: "Playlist Name"),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            TextButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty) {
                   try {
                     final dio = ref.read(dioProvider);
                     await dio.post('/playlists', data: {'name': nameController.text});
                     ref.invalidate(playlistsProvider);
                     Navigator.pop(context);
                   } catch (e) {
                     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: \$e')));
                   }
                }
              }, 
              child: const Text('Create')
            ),
          ],
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final playlistsAsync = ref.watch(playlistsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Playlists'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _createPlaylist),
        ],
      ),
      body: playlistsAsync.when(
        data: (playlists) {
          if (playlists.isEmpty) return const Center(child: Text("No playlists yet."));
          return ListView.builder(
            itemCount: playlists.length,
            itemBuilder: (context, index) {
              final playlist = playlists[index];
              return ListTile(
                leading: const Icon(Icons.queue_music, size: 40),
                title: Text(playlist['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("\${playlist['songs'].length} songs"),
                onTap: () {
                  // Not fully implemented in MVP, would navigate to a Playlist detail page
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Playlist detail view coming soon!')));
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: \$e')),
      ),
    );
  }
}
