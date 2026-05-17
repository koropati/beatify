import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/music_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../widgets/mini_player.dart';
import 'library_page.dart';
import 'playlists_page.dart';
import 'upload_song_page.dart';
import '../../../admin/presentation/pages/admin_dashboard_page.dart';
import '../../../auth/presentation/pages/profile_page.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _selectedIndex = 0;

  Widget _buildPage(int index, bool isAdmin) {
    switch (index) {
      case 0: return const _HomeContent();
      case 1: return const LibraryPage();
      case 2: return const PlaylistsPage();
      case 3: return isAdmin ? const AdminDashboardPage() : const ProfilePage();
      case 4: return const ProfilePage();
      default: return const _HomeContent();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final user = authState.value;
    final isAdmin = user?.role == 'admin';
    final isVerified = user?.isVerified == true;
    final canUpload = isAdmin || isVerified;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _getAppBarTitle(isAdmin),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        actions: [
          if (_selectedIndex == 0 && canUpload) 
            IconButton(
              icon: const Icon(Icons.upload),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const UploadSongPage()),
                );
              },
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _buildPage(_selectedIndex, isAdmin),
          ),
          const MiniPlayer(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black,
        selectedItemColor: const Color(0xFF1DB954),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          const BottomNavigationBarItem(icon: Icon(Icons.library_music), label: 'Library'),
          const BottomNavigationBarItem(icon: Icon(Icons.queue_music), label: 'Playlists'),
          if (isAdmin) const BottomNavigationBarItem(icon: Icon(Icons.admin_panel_settings), label: 'Admin'),
          const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  String _getAppBarTitle(bool isAdmin) {
    switch (_selectedIndex) {
      case 0: return 'Good Morning';
      case 1: return 'Local Library';
      case 2: return 'Playlists';
      case 3: return isAdmin ? 'Admin Dashboard' : 'Profile';
      case 4: return 'Profile';
      default: return 'Beatify';
    }
  }
}

class _HomeContent extends ConsumerWidget {
  const _HomeContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onlineSongsAsyncValue = ref.watch(onlineSongsProvider);

    return onlineSongsAsyncValue.when(
      data: (songs) {
        if (songs.isEmpty) {
          return const Center(child: Text('No songs available online. Upload one!'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: songs.length,
          itemBuilder: (context, index) {
            final song = songs[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 60,
                  height: 60,
                  color: Colors.grey.shade800,
                  child: song.coverImageUrl != null
                      ? Image.network(song.coverImageUrl!, fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.music_note, color: Colors.white54))
                      : const Icon(Icons.music_note, color: Colors.white54),
                ),
                title: Text(
                  song.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  song.artist,
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.more_vert, color: Colors.grey),
                  onPressed: () {
                    // MVP: Show options like add to playlist
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Options coming soon')));
                  },
                ),
                onTap: () {
                  ref.read(audioPlayerControllerProvider).playSong(song);
                },
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF1DB954))),
      error: (error, stack) => Center(child: Text('Error: \$error')),
    );
  }
}
