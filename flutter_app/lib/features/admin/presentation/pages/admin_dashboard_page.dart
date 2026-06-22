import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../music_player/domain/entities/song_entity.dart';
import '../../../music_player/presentation/providers/music_providers.dart';
import '../providers/admin_providers.dart';

class AdminDashboardPage extends ConsumerWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFF121212),
        appBar: AppBar(
          backgroundColor: const Color(0xFF121212),
          elevation: 0,
          title: const Text(
            'Admin Dashboard',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Color(0xFFB3B3B3),
            indicatorColor: Color(0xFF1DB954),
            tabs: [Tab(text: 'Pengguna'), Tab(text: 'Lagu Publik')],
          ),
        ),
        body: const TabBarView(
          children: [_UsersTab(), _SongsTab()],
        ),
      ),
    );
  }
}

// ── Users management ──────────────────────────────────────────────────────────

class _UsersTab extends ConsumerWidget {
  const _UsersTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(allUsersProvider);

    return usersAsync.when(
      data: (users) => RefreshIndicator(
        color: const Color(0xFF1DB954),
        onRefresh: () async => ref.invalidate(allUsersProvider),
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
          itemCount: users.length,
          itemBuilder: (context, index) => _UserCard(user: users[index]),
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF1DB954))),
      error: (e, _) => _ErrorRetry(
        message: e.toString().replaceFirst('Exception: ', ''),
        onRetry: () => ref.invalidate(allUsersProvider),
      ),
    );
  }
}

class _UserCard extends ConsumerWidget {
  const _UserCard({required this.user});
  final UserEntity user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFF282828),
            backgroundImage: user.profilePictureUrl != null
                ? NetworkImage(user.profilePictureUrl!)
                : null,
            child: user.profilePictureUrl == null
                ? Text(user.username[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.username,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 2),
                Text(user.email,
                    style: const TextStyle(color: Color(0xFFB3B3B3), fontSize: 12),
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                Row(children: [
                  _Pill(
                    label: user.role == 'admin' ? 'Admin' : 'User',
                    color: user.role == 'admin' ? const Color(0xFF9C27B0) : const Color(0xFF4D4D4D),
                  ),
                  const SizedBox(width: 6),
                  _Pill(
                    label: user.isVerified ? 'Verified' : 'Unverified',
                    color: user.isVerified ? const Color(0xFF1DB954) : const Color(0xFFB0772F),
                  ),
                ]),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Color(0xFFB3B3B3)),
            onPressed: () => showDialog(
              context: context,
              builder: (_) => _EditUserDialog(user: user),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditUserDialog extends ConsumerStatefulWidget {
  const _EditUserDialog({required this.user});
  final UserEntity user;

  @override
  ConsumerState<_EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends ConsumerState<_EditUserDialog> {
  late final TextEditingController _username;
  late final TextEditingController _email;
  late String _role;
  late bool _isVerified;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _username = TextEditingController(text: widget.user.username);
    _email = TextEditingController(text: widget.user.email);
    _role = widget.user.role == 'admin' ? 'admin' : 'user';
    _isVerified = widget.user.isVerified;
  }

  @override
  void dispose() {
    _username.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final username = _username.text.trim();
    final email = _email.text.trim();
    if (username.isEmpty || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username dan email wajib diisi')),
      );
      return;
    }
    setState(() => _saving = true);
    final result = await ref.read(adminRepositoryProvider).updateUser(
          widget.user.id,
          username: username,
          email: email,
          role: _role,
          isVerified: _isVerified,
        );
    if (!mounted) return;
    result.fold(
      (e) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      },
      (_) {
        ref.invalidate(allUsersProvider);
        ref.invalidate(unverifiedUsersProvider);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pengguna diperbarui'), backgroundColor: Color(0xFF1DB954)),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF282828),
      title: const Text('Edit Pengguna', style: TextStyle(color: Colors.white)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DialogField(controller: _username, label: 'Username'),
            const SizedBox(height: 12),
            _DialogField(controller: _email, label: 'Email'),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _role,
              dropdownColor: const Color(0xFF3E3E3E),
              style: const TextStyle(color: Colors.white),
              decoration: _fieldDecoration('Role'),
              items: const [
                DropdownMenuItem(value: 'user', child: Text('User')),
                DropdownMenuItem(value: 'admin', child: Text('Admin')),
              ],
              onChanged: (v) => setState(() => _role = v ?? 'user'),
            ),
            const SizedBox(height: 4),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              activeThumbColor: const Color(0xFF1DB954),
              title: const Text('Verified', style: TextStyle(color: Colors.white, fontSize: 14)),
              value: _isVerified,
              onChanged: (v) => setState(() => _isVerified = v),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Batal', style: TextStyle(color: Color(0xFFB3B3B3))),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF1DB954),
            foregroundColor: Colors.black,
          ),
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 18, height: 18,
                  child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
              : const Text('Simpan'),
        ),
      ],
    );
  }
}

// ── Songs management ──────────────────────────────────────────────────────────

class _SongsTab extends ConsumerWidget {
  const _SongsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songsAsync = ref.watch(allSongsAdminProvider);

    return songsAsync.when(
      data: (songs) {
        if (songs.isEmpty) {
          return const Center(
            child: Text('Belum ada lagu publik.',
                style: TextStyle(color: Color(0xFFB3B3B3), fontSize: 14)),
          );
        }
        return RefreshIndicator(
          color: const Color(0xFF1DB954),
          onRefresh: () async => ref.invalidate(allSongsAdminProvider),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
            itemCount: songs.length,
            itemBuilder: (context, index) => _AdminSongTile(song: songs[index]),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF1DB954))),
      error: (e, _) => _ErrorRetry(
        message: e.toString().replaceFirst('Exception: ', ''),
        onRetry: () => ref.invalidate(allSongsAdminProvider),
      ),
    );
  }
}

class _AdminSongTile extends ConsumerWidget {
  const _AdminSongTile({required this.song});
  final SongEntity song;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: song.coverImageUrl != null
                ? Image.network(song.coverImageUrl!, width: 48, height: 48, fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _placeholder())
                : _placeholder(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(song.title,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(song.artist,
                    style: const TextStyle(color: Color(0xFFB3B3B3), fontSize: 13),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Color(0xFFB3B3B3), size: 20),
            onPressed: () => showDialog(
              context: context,
              builder: (_) => _EditSongDialog(song: song),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(
        width: 48, height: 48,
        decoration: BoxDecoration(color: const Color(0xFF282828), borderRadius: BorderRadius.circular(4)),
        child: const Icon(Icons.music_note, color: Color(0xFFB3B3B3)),
      );

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF282828),
        title: const Text('Hapus Lagu', style: TextStyle(color: Colors.white)),
        content: Text('Hapus "${song.title}" dari server? Tindakan ini permanen.',
            style: const TextStyle(color: Color(0xFFB3B3B3))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Color(0xFFB3B3B3))),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final result =
                  await ref.read(adminRepositoryProvider).deleteSong(int.parse(song.id));
              ref.invalidate(allSongsAdminProvider);
              ref.invalidate(onlineSongsProvider);
              if (ctx.mounted) Navigator.pop(ctx);
              result.fold(
                (e) => messenger.showSnackBar(
                  SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
                ),
                (_) => messenger.showSnackBar(
                  const SnackBar(content: Text('Lagu dihapus'), backgroundColor: Color(0xFF1DB954)),
                ),
              );
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}

class _EditSongDialog extends ConsumerStatefulWidget {
  const _EditSongDialog({required this.song});
  final SongEntity song;

  @override
  ConsumerState<_EditSongDialog> createState() => _EditSongDialogState();
}

class _EditSongDialogState extends ConsumerState<_EditSongDialog> {
  late final TextEditingController _title;
  late final TextEditingController _artist;
  late final TextEditingController _album;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.song.title);
    _artist = TextEditingController(text: widget.song.artist);
    _album = TextEditingController(text: widget.song.album ?? '');
  }

  @override
  void dispose() {
    _title.dispose();
    _artist.dispose();
    _album.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    final artist = _artist.text.trim();
    if (title.isEmpty || artist.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Judul dan penyanyi wajib diisi')),
      );
      return;
    }
    setState(() => _saving = true);
    final album = _album.text.trim();
    final result = await ref.read(adminRepositoryProvider).updateSong(
          int.parse(widget.song.id),
          title: title,
          artist: artist,
          album: album.isEmpty ? '' : album,
        );
    if (!mounted) return;
    result.fold(
      (e) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      },
      (_) {
        ref.invalidate(allSongsAdminProvider);
        ref.invalidate(onlineSongsProvider);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lagu diperbarui'), backgroundColor: Color(0xFF1DB954)),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF282828),
      title: const Text('Edit Lagu', style: TextStyle(color: Colors.white)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DialogField(controller: _title, label: 'Judul'),
            const SizedBox(height: 12),
            _DialogField(controller: _artist, label: 'Penyanyi'),
            const SizedBox(height: 12),
            _DialogField(controller: _album, label: 'Album (opsional)'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Batal', style: TextStyle(color: Color(0xFFB3B3B3))),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF1DB954),
            foregroundColor: Colors.black,
          ),
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 18, height: 18,
                  child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
              : const Text('Simpan'),
        ),
      ],
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

InputDecoration _fieldDecoration(String label) => InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFFB3B3B3)),
      filled: true,
      fillColor: const Color(0xFF3E3E3E),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: Color(0xFF1DB954), width: 2),
      ),
    );

class _DialogField extends StatelessWidget {
  const _DialogField({required this.controller, required this.label});
  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: _fieldDecoration(label),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}

class _ErrorRetry extends StatelessWidget {
  const _ErrorRetry({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFB3B3B3), size: 48),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(color: Color(0xFFB3B3B3)), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onRetry,
            child: const Text('Coba lagi', style: TextStyle(color: Color(0xFF1DB954))),
          ),
        ],
      ),
    );
  }
}
