import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/song_entity.dart';
import '../providers/music_providers.dart';
import '../pages/player_page.dart';

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  Widget _cover(SongEntity song) {
    const fallback = Icon(Icons.music_note, color: Color(0xFFB3B3B3), size: 20);
    if (song.coverImageUrl != null) {
      return Image.network(
        song.coverImageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
      );
    }
    final path = song.coverImagePath;
    if (path != null && File(path).existsSync()) {
      return Image.file(File(path), fit: BoxFit.cover);
    }
    return fallback;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSong = ref.watch(currentSongProvider);
    final isPlaying = ref.watch(isPlayingProvider);
    final playerController = ref.watch(audioPlayerControllerProvider);
    final audioPlayer = ref.watch(audioPlayerProvider);

    if (currentSong == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const PlayerPage()),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF282828),
          border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.08), width: 0.5),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            StreamBuilder<Duration>(
              stream: audioPlayer.positionStream,
              builder: (context, snapshot) {
                final position = snapshot.data ?? Duration.zero;
                final duration = audioPlayer.duration ?? Duration.zero;
                final progress = duration.inMilliseconds > 0
                    ? (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
                    : 0.0;
                return LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1DB954)),
                  minHeight: 2,
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF404040),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: _cover(currentSong),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          currentSong.title,
                          style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          currentSong.artist,
                          style: const TextStyle(color: Color(0xFFB3B3B3), fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.favorite_border, color: Color(0xFFB3B3B3), size: 22),
                    onPressed: () {},
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  ),
                  IconButton(
                    icon: Icon(
                      isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      size: 28,
                    ),
                    onPressed: () => isPlaying ? playerController.pause() : playerController.resume(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_next, color: Colors.white, size: 26),
                    onPressed: () => playerController.skipNext(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
