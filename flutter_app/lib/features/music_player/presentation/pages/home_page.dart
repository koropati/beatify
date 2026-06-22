import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/music_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../widgets/mini_player.dart';
import 'library_page.dart';
import 'playlists_page.dart';
import 'upload_song_page.dart';
import '../../../reading_book/presentation/pages/reading_book_page.dart';
import '../../../admin/presentation/pages/admin_dashboard_page.dart';
import '../../../auth/presentation/pages/profile_page.dart';
import '../../domain/entities/song_entity.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _selectedIndex = 0;

  Widget _buildPage(int index, bool showAdmin) {
    switch (index) {
      case 0:
        return const _HomeContent();
      case 1:
        return const LibraryPage();
      case 2:
        return const PlaylistsPage();
      case 3:
        return const ReadingBookPage();
      case 4:
        return showAdmin ? const AdminDashboardPage() : const ProfilePage();
      case 5:
        return const ProfilePage();
      default:
        return const _HomeContent();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final user = authState.value;
    final isOffline = ref.watch(isOfflineModeProvider);
    final isAdmin = user?.role == 'admin';
    final isVerified = user?.isVerified == true;
    final canUpload = (isAdmin || isVerified) && !isOffline;
    final showAdmin = isAdmin && !isOffline;
    final hasMiniPlayer = ref.watch(currentSongProvider) != null;

    // Saat masuk mode offline, arahkan ke Library (musik lokal) jika pengguna
    // masih berada di tab/indeks yang tidak tersedia offline.
    if (isOffline && (_selectedIndex == 0 || _selectedIndex >= 4)) {
      _selectedIndex = 1;
    }

    ref.listen(playbackErrorProvider, (prev, next) {
      if (next != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next), backgroundColor: Colors.redAccent),
        );
        ref.read(playbackErrorProvider.notifier).state = null;
      }
    });

    Widget? fab;
    if (_selectedIndex == 0 && canUpload) {
      fab = Padding(
        padding: EdgeInsets.only(bottom: hasMiniPlayer ? 68 : 0),
        child: FloatingActionButton(
          backgroundColor: const Color(0xFF1DB954),
          foregroundColor: Colors.black,
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const UploadSongPage()),
          ),
          child: const Icon(Icons.add),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Column(
        children: [
          if (isOffline) const _OfflineBanner(),
          Expanded(child: _buildPage(_selectedIndex, showAdmin)),
          const MiniPlayer(),
        ],
      ),
      floatingActionButton: fab,
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFF0A0A0A),
        indicatorColor: Colors.transparent,
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined, color: Color(0xFFB3B3B3)),
            selectedIcon: Icon(Icons.home, color: Color(0xFF1DB954)),
            label: 'Home',
          ),
          const NavigationDestination(
            icon: Icon(Icons.library_music_outlined, color: Color(0xFFB3B3B3)),
            selectedIcon: Icon(Icons.library_music, color: Color(0xFF1DB954)),
            label: 'Library',
          ),
          const NavigationDestination(
            icon: Icon(Icons.queue_music_outlined, color: Color(0xFFB3B3B3)),
            selectedIcon: Icon(Icons.queue_music, color: Color(0xFF1DB954)),
            label: 'Playlists',
          ),
          const NavigationDestination(
            icon: Icon(Icons.menu_book_outlined, color: Color(0xFFB3B3B3)),
            selectedIcon: Icon(Icons.menu_book, color: Color(0xFF1DB954)),
            label: 'Reading',
          ),
          if (showAdmin)
            const NavigationDestination(
              icon: Icon(Icons.admin_panel_settings_outlined, color: Color(0xFFB3B3B3)),
              selectedIcon: Icon(Icons.admin_panel_settings, color: Color(0xFF1DB954)),
              label: 'Admin',
            ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline, color: Color(0xFFB3B3B3)),
            selectedIcon: Icon(Icons.person, color: Color(0xFF1DB954)),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _HomeContent extends ConsumerWidget {
  const _HomeContent();

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOffline = ref.watch(isOfflineModeProvider);
    final onlineSongsAsync = ref.watch(onlineSongsProvider);
    final user = ref.watch(authStateProvider).value;

    if (isOffline) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off, size: 64, color: Color(0xFFB3B3B3)),
              SizedBox(height: 16),
              Text(
                'Mode Offline',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Lagu online tidak tersedia tanpa koneksi. '
                'Buka tab Library untuk mendengarkan musik dari perangkat.',
                style: TextStyle(color: Color(0xFFB3B3B3), fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          backgroundColor: const Color(0xFF121212),
          floating: true,
          pinned: false,
          expandedHeight: 0,
          title: Text(
            _greeting(),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          actions: [
            if (user != null)
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: const Color(0xFF1DB954),
                  child: Text(
                    user.username[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
          ],
        ),
        onlineSongsAsync.when(
          data: (songs) {
            if (songs.isEmpty) {
              return const SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.music_off, size: 64, color: Color(0xFFB3B3B3)),
                      SizedBox(height: 16),
                      Text(
                        'No songs available yet.',
                        style: TextStyle(color: Color(0xFFB3B3B3), fontSize: 16),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Upload your first song!',
                        style: TextStyle(color: Color(0xFF727272), fontSize: 14),
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
                      return const Padding(
                        padding: EdgeInsets.only(top: 8, bottom: 16),
                        child: Text(
                          'Songs for you',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      );
                    }
                    return _SongListTile(song: songs[index - 1]);
                  },
                  childCount: songs.length + 1,
                ),
              ),
            );
          },
          loading: () => const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator(color: Color(0xFF1DB954))),
          ),
          error: (e, _) => SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: Color(0xFFB3B3B3), size: 48),
                  const SizedBox(height: 12),
                  Text(
                    'Could not load songs',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => ref.invalidate(onlineSongsProvider),
                    child: const Text('Retry', style: TextStyle(color: Color(0xFF1DB954))),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 16)),
      ],
    );
  }
}

class _SongListTile extends ConsumerWidget {
  const _SongListTile({required this.song});
  final SongEntity song;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSong = ref.watch(currentSongProvider);
    final isCurrentSong = currentSong?.id == song.id;

    return InkWell(
      onTap: () {
        final songs = ref.read(onlineSongsProvider).value ?? [];
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
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: song.coverImageUrl != null
                    ? Image.network(
                        song.coverImageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stack) => const Icon(
                          Icons.music_note,
                          color: Color(0xFFB3B3B3),
                        ),
                      )
                    : const Icon(Icons.music_note, color: Color(0xFFB3B3B3)),
              ),
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
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}

class _OfflineBanner extends ConsumerWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: const Color(0xFF3E2723),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.cloud_off, color: Color(0xFFFFB74D), size: 18),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Mode offline — hanya musik lokal yang tersedia',
                  style: TextStyle(color: Color(0xFFFFB74D), fontSize: 12),
                ),
              ),
              TextButton(
                onPressed: () =>
                    ref.read(authStateProvider.notifier).retryConnection(),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Sambung ulang',
                    style: TextStyle(color: Color(0xFF1DB954), fontSize: 12)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
