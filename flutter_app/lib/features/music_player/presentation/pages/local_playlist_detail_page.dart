import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../domain/entities/local_playlist_entity.dart';
import '../../domain/entities/song_entity.dart';
import '../providers/local_playlist_providers.dart';
import '../providers/music_providers.dart';

class LocalPlaylistDetailPage extends ConsumerWidget {
  const LocalPlaylistDetailPage({super.key, required this.playlist});
  final LocalPlaylistEntity playlist;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlistsAsync = ref.watch(localPlaylistsProvider);
    final current = playlistsAsync.maybeWhen(
      data: (list) => list.where((p) => p.id == playlist.id).firstOrNull,
      orElse: () => null,
    ) ?? playlist;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            backgroundColor: const Color(0xFF121212),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.white),
                onPressed: () => _showEditDialog(context, ref, current),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  _buildCover(current.coverImagePath),
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Color(0xFF121212)],
                        stops: [0.5, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    current.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${current.songs.length} lagu',
                    style: const TextStyle(color: Color(0xFFB3B3B3), fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  if (current.songs.isNotEmpty)
                    Row(
                      children: [
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF1DB954),
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Play All', style: TextStyle(fontWeight: FontWeight.bold)),
                          onPressed: () {
                            ref
                                .read(audioPlayerControllerProvider)
                                .playQueue(current.songs, 0);
                            Navigator.pop(context);
                          },
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0xFF282828),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                            ),
                          ),
                          icon: const Icon(Icons.shuffle, color: Colors.white),
                          onPressed: () async {
                            final shuffled = List<SongEntity>.from(current.songs)..shuffle();
                            ref.read(audioPlayerControllerProvider).playQueue(shuffled, 0);
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          if (current.songs.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.music_note, size: 64, color: Color(0xFF282828)),
                    SizedBox(height: 12),
                    Text(
                      'Playlist masih kosong',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Tambahkan lagu dari Library.',
                      style: TextStyle(color: Color(0xFFB3B3B3), fontSize: 13),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _PlaylistSongTile(
                    song: current.songs[index],
                    playlistId: current.id,
                    allSongs: current.songs,
                  ),
                  childCount: current.songs.length,
                ),
              ),
            ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
        ],
      ),
    );
  }

  Widget _buildCover(String? path) {
    if (path != null) {
      final file = File(path);
      if (file.existsSync()) {
        return Image.file(file, fit: BoxFit.cover);
      }
    }
    return Container(
      color: const Color(0xFF1A1A2E),
      child: const Icon(Icons.queue_music, size: 80, color: Color(0xFF282828)),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, LocalPlaylistEntity current) {
    final nameController = TextEditingController(text: current.name);
    String? pickedPath;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          backgroundColor: const Color(0xFF282828),
          title: const Text('Edit Playlist', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () async {
                  final result = await FilePicker.platform.pickFiles(type: FileType.image);
                  if (result?.files.single.path != null) {
                    setState(() => pickedPath = result!.files.single.path);
                  }
                },
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3E3E3E),
                    borderRadius: BorderRadius.circular(8),
                    image: _coverDecoration(pickedPath ?? current.coverImagePath),
                  ),
                  child: (pickedPath == null && current.coverImagePath == null)
                      ? const Icon(Icons.add_photo_alternate, color: Color(0xFFB3B3B3), size: 32)
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Nama playlist',
                  hintStyle: const TextStyle(color: Color(0xFF727272)),
                  filled: true,
                  fillColor: const Color(0xFF3E3E3E),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal', style: TextStyle(color: Color(0xFFB3B3B3))),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1DB954),
                foregroundColor: Colors.black,
              ),
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) return;
                final result = await ref.read(updateLocalPlaylistUseCaseProvider).call(
                      current.id,
                      name: name,
                      coverImagePath: pickedPath,
                    );
                result.fold(
                  (e) => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  ),
                  (_) => ref.invalidate(localPlaylistsProvider),
                );
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  DecorationImage? _coverDecoration(String? path) {
    if (path == null) return null;
    final file = File(path);
    if (!file.existsSync()) return null;
    return DecorationImage(image: FileImage(file), fit: BoxFit.cover);
  }
}

class _PlaylistSongTile extends ConsumerWidget {
  const _PlaylistSongTile({
    required this.song,
    required this.playlistId,
    required this.allSongs,
  });
  final SongEntity song;
  final int playlistId;
  final List<SongEntity> allSongs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSong = ref.watch(currentSongProvider);
    final isPlaying = currentSong?.id == song.id;

    return InkWell(
      onTap: () {
        final idx = allSongs.indexWhere((s) => s.id == song.id);
        ref.read(audioPlayerControllerProvider).playQueue(allSongs, idx == -1 ? 0 : idx);
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
              child: const Icon(Icons.music_note, color: Color(0xFFB3B3B3)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title,
                    style: TextStyle(
                      color: isPlaying ? const Color(0xFF1DB954) : Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    song.artist,
                    style: const TextStyle(color: Color(0xFFB3B3B3), fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isPlaying)
              const Padding(
                padding: EdgeInsets.only(right: 4),
                child: Icon(Icons.equalizer, color: Color(0xFF1DB954), size: 20),
              ),
            IconButton(
              icon: const Icon(Icons.remove_circle_outline, color: Color(0xFFB3B3B3), size: 20),
              onPressed: () => _confirmRemove(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmRemove(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF282828),
        title: const Text('Hapus lagu', style: TextStyle(color: Colors.white)),
        content: Text(
          'Hapus "${song.title}" dari playlist?',
          style: const TextStyle(color: Color(0xFFB3B3B3)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Color(0xFFB3B3B3))),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              await ref.read(removeSongFromPlaylistUseCaseProvider).call(playlistId, song.id);
              ref.invalidate(localPlaylistsProvider);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}
