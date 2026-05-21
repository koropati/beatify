import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/music_providers.dart';
import '../providers/local_playlist_providers.dart';
import '../../domain/entities/song_entity.dart';
import '../../domain/entities/local_playlist_entity.dart';
import 'local_playlist_detail_page.dart';

class LibraryPage extends ConsumerStatefulWidget {
  const LibraryPage({super.key});

  @override
  ConsumerState<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends ConsumerState<LibraryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentTab = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _currentTab = _tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        title: const Text(
          'Your Library',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          if (_currentTab == 1)
            IconButton(
              icon: const Icon(Icons.add, color: Colors.white),
              onPressed: () => _showCreatePlaylistDialog(context),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: const Color(0xFFB3B3B3),
          indicatorColor: const Color(0xFF1DB954),
          indicatorWeight: 2,
          tabs: const [
            Tab(text: 'Lagu'),
            Tab(text: 'Playlist'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [_SongsTab(), _PlaylistsTab()],
      ),
    );
  }

  void _showCreatePlaylistDialog(BuildContext context) {
    final nameController = TextEditingController();
    String? pickedPath;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          backgroundColor: const Color(0xFF282828),
          title: const Text('Playlist Baru', style: TextStyle(color: Colors.white)),
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
                    image: pickedPath != null
                        ? DecorationImage(
                            image: FileImage(File(pickedPath!)),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: pickedPath == null
                      ? const Icon(Icons.add_photo_alternate,
                          color: Color(0xFFB3B3B3), size: 32)
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
                final result = await ref
                    .read(createLocalPlaylistUseCaseProvider)
                    .call(name, coverImagePath: pickedPath);
                result.fold(
                  (e) => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  ),
                  (_) => ref.invalidate(localPlaylistsProvider),
                );
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Buat'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Songs Tab ────────────────────────────────────────────────────────────────

class _SongsTab extends ConsumerWidget {
  const _SongsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songsAsync = ref.watch(localSongsProvider);

    return songsAsync.when(
      data: (songs) {
        if (songs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.library_music, size: 72, color: Color(0xFF282828)),
                SizedBox(height: 16),
                Text(
                  'Belum ada lagu lokal',
                  style: TextStyle(
                      color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Tambahkan file audio ke perangkat untuk melihatnya di sini.',
                  style: TextStyle(color: Color(0xFFB3B3B3), fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
          itemCount: songs.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  '${songs.length} lagu',
                  style: const TextStyle(color: Color(0xFFB3B3B3), fontSize: 13),
                ),
              );
            }
            return _LocalSongTile(song: songs[index - 1], allSongs: songs);
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: Color(0xFF1DB954)),
      ),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFB3B3B3), size: 48),
            const SizedBox(height: 12),
            const Text('Gagal memuat musik lokal',
                style: TextStyle(color: Colors.white, fontSize: 16)),
            const SizedBox(height: 8),
            Text(
              e.toString().replaceFirst('Exception: ', ''),
              style: const TextStyle(color: Color(0xFFB3B3B3), fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _LocalSongTile extends ConsumerWidget {
  const _LocalSongTile({required this.song, required this.allSongs});
  final SongEntity song;
  final List<SongEntity> allSongs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSong = ref.watch(currentSongProvider);
    final isCurrentSong = currentSong?.id == song.id;

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
                      color: isCurrentSong ? const Color(0xFF1DB954) : Colors.white,
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
            if (isCurrentSong)
              const Padding(
                padding: EdgeInsets.only(right: 4),
                child: Icon(Icons.equalizer, color: Color(0xFF1DB954), size: 20),
              ),
            IconButton(
              icon: const Icon(Icons.more_vert, color: Color(0xFFB3B3B3), size: 20),
              onPressed: () => _showSongOptions(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  void _showSongOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF282828),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (ctx) => _AddToPlaylistSheet(song: song),
    );
  }
}

class _AddToPlaylistSheet extends ConsumerWidget {
  const _AddToPlaylistSheet({required this.song});
  final SongEntity song;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlistsAsync = ref.watch(localPlaylistsProvider);

    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Text(
              song.title,
              style: const TextStyle(
                  color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Divider(color: Color(0xFF3E3E3E), height: 1),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text('Tambah ke Playlist',
                style: TextStyle(color: Color(0xFFB3B3B3), fontSize: 13)),
          ),
          playlistsAsync.when(
            data: (playlists) {
              if (playlists.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Belum ada playlist. Buat dulu di tab Playlist.',
                      style: TextStyle(color: Color(0xFFB3B3B3), fontSize: 13)),
                );
              }
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: playlists
                    .map((p) => ListTile(
                          leading: _buildPlaylistThumb(p.coverImagePath),
                          title: Text(p.name,
                              style: const TextStyle(color: Colors.white, fontSize: 14)),
                          subtitle: Text('${p.songs.length} lagu',
                              style: const TextStyle(
                                  color: Color(0xFFB3B3B3), fontSize: 12)),
                          onTap: () async {
                            final result = await ref
                                .read(addSongToPlaylistUseCaseProvider)
                                .call(p.id, song);
                            ref.invalidate(localPlaylistsProvider);
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(result.isRight()
                                      ? 'Ditambahkan ke "${p.name}"'
                                      : 'Lagu sudah ada di playlist ini'),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                        ))
                    .toList(),
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(color: Color(0xFF1DB954)),
            ),
            error: (_, stackTrace) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaylistThumb(String? path) {
    if (path != null) {
      final file = File(path);
      if (file.existsSync()) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Image.file(file, width: 40, height: 40, fit: BoxFit.cover),
        );
      }
    }
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFF3E3E3E),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Icon(Icons.queue_music, color: Color(0xFF1DB954), size: 22),
    );
  }
}

// ── Playlists Tab ─────────────────────────────────────────────────────────────

class _PlaylistsTab extends ConsumerWidget {
  const _PlaylistsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlistsAsync = ref.watch(localPlaylistsProvider);

    return playlistsAsync.when(
      data: (playlists) {
        if (playlists.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.queue_music, size: 72, color: Color(0xFF282828)),
                SizedBox(height: 16),
                Text(
                  'Belum ada playlist',
                  style: TextStyle(
                      color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Tekan + untuk membuat playlist baru.',
                  style: TextStyle(color: Color(0xFFB3B3B3), fontSize: 14),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
          itemCount: playlists.length,
          itemBuilder: (context, index) =>
              _PlaylistTile(playlist: playlists[index]),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: Color(0xFF1DB954)),
      ),
      error: (e, _) => Center(
        child: Text('Error: $e',
            style: const TextStyle(color: Color(0xFFB3B3B3))),
      ),
    );
  }
}

class _PlaylistTile extends ConsumerWidget {
  const _PlaylistTile({required this.playlist});
  final LocalPlaylistEntity playlist;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LocalPlaylistDetailPage(playlist: playlist),
        ),
      ),
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            _buildCover(playlist.coverImagePath),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    playlist.name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Playlist • ${playlist.songs.length} lagu',
                    style: const TextStyle(color: Color(0xFFB3B3B3), fontSize: 13),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.more_vert, color: Color(0xFFB3B3B3), size: 20),
              onPressed: () => _showOptions(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCover(String? path) {
    if (path != null) {
      final file = File(path);
      if (file.existsSync()) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Image.file(file, width: 52, height: 52, fit: BoxFit.cover),
        );
      }
    }
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFF282828),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Icon(Icons.queue_music, color: Color(0xFF1DB954), size: 28),
    );
  }

  void _showOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF282828),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Text(
                playlist.name,
                style: const TextStyle(
                    color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(color: Color(0xFF3E3E3E), height: 1),
            ListTile(
              leading: const Icon(Icons.play_arrow, color: Colors.white),
              title: const Text('Putar semua', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(ctx);
                if (playlist.songs.isNotEmpty) {
                  ref.read(audioPlayerControllerProvider).playQueue(playlist.songs, 0);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
              title: const Text('Hapus playlist',
                  style: TextStyle(color: Colors.redAccent)),
              onTap: () {
                Navigator.pop(ctx);
                _confirmDelete(context, ref);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF282828),
        title: const Text('Hapus Playlist', style: TextStyle(color: Colors.white)),
        content: Text(
          'Hapus "${playlist.name}"? Lagu di dalamnya tidak ikut terhapus.',
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
              await ref.read(deleteLocalPlaylistUseCaseProvider).call(playlist.id);
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
