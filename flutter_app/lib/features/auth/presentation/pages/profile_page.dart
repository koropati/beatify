import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: authState.when(
        data: (user) {
          if (user == null) return const Center(child: Text('Not logged in'));
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: const Color(0xFF1A1A1A),
                expandedHeight: 200,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFF1DB954), Color(0xFF121212)],
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        CircleAvatar(
                          radius: 52,
                          backgroundColor: const Color(0xFF282828),
                          backgroundImage: user.profilePictureUrl != null
                              ? NetworkImage(user.profilePictureUrl!)
                              : null,
                          child: user.profilePictureUrl == null
                              ? Text(
                                  user.username[0].toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 42,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                )
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),
                title: Text(
                  user.username,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.username,
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(user.email, style: const TextStyle(fontSize: 14, color: Color(0xFFB3B3B3))),
                      const SizedBox(height: 16),
                      _RoleBadge(role: user.role, isVerified: user.isVerified),
                      const SizedBox(height: 40),
                      const Divider(color: Color(0xFF282828)),
                      const SizedBox(height: 16),
                      _ProfileMenuItem(
                        icon: Icons.edit_outlined,
                        label: 'Edit Profile',
                        onTap: () => _showEditProfileDialog(context, ref, user.username),
                      ),
                      _ProfileMenuItem(
                        icon: Icons.lock_outline,
                        label: 'Change Password',
                        onTap: () => _showChangePasswordDialog(context, ref),
                      ),
                      _ProfileMenuItem(
                        icon: Icons.notifications_none,
                        label: 'Notifications',
                        onTap: () {},
                      ),
                      _ProfileMenuItem(
                        icon: Icons.privacy_tip_outlined,
                        label: 'Privacy',
                        onTap: () {},
                      ),
                      const SizedBox(height: 24),
                      const Divider(color: Color(0xFF282828)),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Color(0xFF727272)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: const StadiumBorder(),
                          ),
                          onPressed: () => ref.read(authStateProvider.notifier).logout(),
                          child: const Text('Log out', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF1DB954))),
        error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.white))),
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, WidgetRef ref, String currentUsername) {
    final controller = TextEditingController(text: currentUsername);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF282828),
        title: const Text('Edit Profile', style: TextStyle(color: Colors.white)),
        content: _DialogTextField(controller: controller, label: 'Username'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFFB3B3B3))),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF1DB954),
              foregroundColor: Colors.black,
            ),
            onPressed: () async {
              final username = controller.text.trim();
              if (username.isEmpty || username == currentUsername) {
                Navigator.pop(ctx);
                return;
              }
              Navigator.pop(ctx);
              final result = await ref.read(authStateProvider.notifier).updateProfile(username);
              if (context.mounted) {
                result.fold(
                  (e) => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
                  ),
                  (_) => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Profile updated!'),
                      backgroundColor: Color(0xFF1DB954),
                    ),
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context, WidgetRef ref) {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF282828),
        title: const Text('Change Password', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DialogTextField(controller: currentCtrl, label: 'Current Password', obscure: true),
            const SizedBox(height: 12),
            _DialogTextField(controller: newCtrl, label: 'New Password', obscure: true),
            const SizedBox(height: 12),
            _DialogTextField(controller: confirmCtrl, label: 'Confirm New Password', obscure: true),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFFB3B3B3))),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF1DB954),
              foregroundColor: Colors.black,
            ),
            onPressed: () async {
              if (newCtrl.text != confirmCtrl.text) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('New passwords do not match')),
                );
                return;
              }
              if (newCtrl.text.length < 6) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Password must be at least 6 characters')),
                );
                return;
              }
              Navigator.pop(ctx);
              final result = await ref.read(authStateProvider.notifier).changePassword(
                    currentCtrl.text,
                    newCtrl.text,
                  );
              if (context.mounted) {
                result.fold(
                  (e) => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
                  ),
                  (_) => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Password changed successfully!'),
                      backgroundColor: Color(0xFF1DB954),
                    ),
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _DialogTextField extends StatelessWidget {
  const _DialogTextField({required this.controller, required this.label, this.obscure = false});
  final TextEditingController controller;
  final String label;
  final bool obscure;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF727272)),
        filled: true,
        fillColor: const Color(0xFF3E3E3E),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide.none),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role, required this.isVerified});
  final String role;
  final bool isVerified;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (role) {
      'admin' => ('Admin', const Color(0xFF9C27B0)),
      _ when isVerified => ('Verified Creator', const Color(0xFF1DB954)),
      _ => ('Listener', const Color(0xFF4D4D4D)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  const _ProfileMenuItem({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: Colors.white, size: 22),
      title: Text(label, style: const TextStyle(color: Colors.white, fontSize: 15)),
      trailing: const Icon(Icons.chevron_right, color: Color(0xFFB3B3B3)),
      onTap: onTap,
    );
  }
}
