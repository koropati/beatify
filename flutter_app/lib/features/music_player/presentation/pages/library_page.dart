import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/music_providers.dart';
import '../../domain/entities/song_entity.dart';

class LibraryPage extends ConsumerWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localSongsAsync = ref.watch(localSongsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: CustomScrollView(
        slivers: [
          const SliverAppBar(
            backgroundColor: Color(0xFF121212),
            floating: true,
            title: Text(
              'Your Library',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          localSongsAsync.when(
            data: (songs) {
              if (songs.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.library_music, size: 72, color: Color(0xFF282828)),
                        SizedBox(height: 16),
                        Text(
                          'No local music found',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Add audio files to your device to see them here.',
                          style: TextStyle(color: Color(0xFFB3B3B3), fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index == 0) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 4, bottom: 12),
                          child: Text(
                            '${songs.length} songs',
                            style: const TextStyle(
                              color: Color(0xFFB3B3B3),
                              fontSize: 13,
                            ),
                          ),
                        );
                      }
                      return _LocalSongTile(song: songs[index - 1]);
                    },
                    childCount: songs.length + 1,
                  ),
                ),
              );
            },
            loading: () => const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFF1DB954)),
              ),
            ),
            error: (e, _) => SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, color: Color(0xFFB3B3B3), size: 48),
                    const SizedBox(height: 12),
                    const Text(
                      'Could not load local music',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      e.toString().replaceFirst('Exception: ', ''),
                      style: const TextStyle(color: Color(0xFFB3B3B3), fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 16)),
        ],
      ),
    );
  }
}

class _LocalSongTile extends ConsumerWidget {
  const _LocalSongTile({required this.song});
  final SongEntity song;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSong = ref.watch(currentSongProvider);
    final isCurrentSong = currentSong?.id == song.id;

    return InkWell(
      onTap: () {
        final songs = ref.read(localSongsProvider).value ?? [];
        final idx = songs.indexWhere((s) => s.id == song.id);
        ref.read(audioPlayerControllerProvider).playQueue(songs, idx == -1 ? 0 : idx);
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
              const Icon(Icons.equalizer, color: Color(0xFF1DB954), size: 20),
          ],
        ),
      ),
    );
  }
}
