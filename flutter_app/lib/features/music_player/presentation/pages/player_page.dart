import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import '../../domain/entities/song_entity.dart';
import '../providers/music_providers.dart';

class PlayerPage extends ConsumerWidget {
  const PlayerPage({super.key});

  Widget _albumArt(SongEntity song) {
    const fallback = Icon(Icons.music_note, size: 80, color: Color(0xFFB3B3B3));
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

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString();
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSong = ref.watch(currentSongProvider);
    final isPlaying = ref.watch(isPlayingProvider);
    final shuffleMode = ref.watch(shuffleModeProvider);
    final repeatMode = ref.watch(repeatModeProvider);
    final controller = ref.watch(audioPlayerControllerProvider);
    final audioPlayer = ref.watch(audioPlayerProvider);

    if (currentSong == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF121212),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 32),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: const Center(
          child: Text('No song playing', style: TextStyle(color: Color(0xFFB3B3B3))),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 32),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Column(
          children: [
            Text(
              'NOW PLAYING',
              style: TextStyle(color: Color(0xFFB3B3B3), fontSize: 11, letterSpacing: 1.5),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 24),
            // Album art
            Expanded(
              flex: 5,
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF282828),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: const [
                        BoxShadow(color: Colors.black54, blurRadius: 40, offset: Offset(0, 16)),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: _albumArt(currentSong),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Song info + heart
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentSong.title,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currentSong.artist,
                        style: const TextStyle(fontSize: 15, color: Color(0xFFB3B3B3)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.favorite_border, color: Color(0xFFB3B3B3), size: 26),
                  onPressed: () {},
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Progress bar
            StreamBuilder<Duration>(
              stream: audioPlayer.positionStream,
              builder: (context, snapshot) {
                final position = snapshot.data ?? Duration.zero;
                final duration = audioPlayer.duration ?? Duration.zero;
                final progress = duration.inMilliseconds > 0
                    ? (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
                    : 0.0;
                return Column(
                  children: [
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 3,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                        activeTrackColor: Colors.white,
                        inactiveTrackColor: const Color(0xFF4D4D4D),
                        thumbColor: Colors.white,
                        overlayColor: Colors.white24,
                      ),
                      child: Slider(
                        value: progress,
                        onChanged: (value) {
                          final ms = (value * duration.inMilliseconds).toInt();
                          audioPlayer.seek(Duration(milliseconds: ms));
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_formatDuration(position),
                              style: const TextStyle(color: Color(0xFFB3B3B3), fontSize: 12)),
                          Text(_formatDuration(duration),
                              style: const TextStyle(color: Color(0xFFB3B3B3), fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            // Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.shuffle,
                    color: shuffleMode ? const Color(0xFF1DB954) : const Color(0xFFB3B3B3),
                    size: 24,
                  ),
                  onPressed: () => controller.toggleShuffle(),
                ),
                IconButton(
                  icon: const Icon(Icons.skip_previous, color: Colors.white, size: 36),
                  onPressed: () => controller.skipPrevious(),
                ),
                GestureDetector(
                  onTap: () => isPlaying ? controller.pause() : controller.resume(),
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: Icon(
                      isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.black,
                      size: 36,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.skip_next, color: Colors.white, size: 36),
                  onPressed: () => controller.skipNext(),
                ),
                IconButton(
                  icon: Icon(
                    repeatMode == LoopMode.one ? Icons.repeat_one : Icons.repeat,
                    color: repeatMode != LoopMode.off ? const Color(0xFF1DB954) : const Color(0xFFB3B3B3),
                    size: 24,
                  ),
                  onPressed: () => controller.toggleRepeat(),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
