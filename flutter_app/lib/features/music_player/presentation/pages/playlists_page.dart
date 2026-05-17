import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/music_providers.dart';

final playlistsProvider = FutureProvider((ref) async {
  final dio = ref.read(dioProvider);
  final response = await dio.get('/playlists');
  return response.data as List<dynamic>;
});

class PlaylistsPage extends ConsumerWidget {
  const PlaylistsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlistsAsync = ref.watch(playlistsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: const Color(0xFF121212),
            floating: true,
            title: const Text(
              'Playlists',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.add, color: Colors.white),
                onPressed: () => _showCreatePlaylistDialog(context, ref),
              ),
            ],
          ),
          playlistsAsync.when(
            data: (playlists) {
              if (playlists.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.queue_music, size: 72, color: Color(0xFF282828)),
                        SizedBox(height: 16),
                        Text(
                          'No playlists yet',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Create your first playlist.',
                          style: TextStyle(color: Color(0xFFB3B3B3), fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _PlaylistTile(playlist: playlists[index]),
                    childCount: playlists.length,
                  ),
                ),
              );
            },
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: Color(0xFF1DB954))),
            ),
            error: (e, _) => SliverFillRemaining(
              child: Center(
                child: Text('Error: $e', style: const TextStyle(color: Color(0xFFB3B3B3))),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCreatePlaylistDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF282828),
        title: const Text('New Playlist', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Playlist name',
            hintStyle: const TextStyle(color: Color(0xFF727272)),
            filled: true,
            fillColor: const Color(0xFF3E3E3E),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFFB3B3B3))),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF1DB954), foregroundColor: Colors.black),
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                try {
                  final dio = ref.read(dioProvider);
                  await dio.post('/playlists', data: {'name': controller.text});
                  ref.invalidate(playlistsProvider);
                } catch (e) {
                  // ignore error silently
                }
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

class _PlaylistTile extends StatelessWidget {
  const _PlaylistTile({required this.playlist});
  final dynamic playlist;

  @override
  Widget build(BuildContext context) {
    final songCount = (playlist['songs'] as List?)?.length ?? 0;
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Playlist detail coming soon')),
        );
      },
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFF282828),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Icon(Icons.queue_music, color: Color(0xFF1DB954), size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    playlist['name'] ?? '',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Playlist • $songCount songs',
                    style: const TextStyle(color: Color(0xFFB3B3B3), fontSize: 13),
                  ),
                ],
              ),
            ),
            const Icon(Icons.more_vert, color: Color(0xFFB3B3B3), size: 20),
          ],
        ),
      ),
    );
  }
}
