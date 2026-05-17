import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../music_player/presentation/providers/music_providers.dart';

final unverifiedUsersProvider = FutureProvider.autoDispose<List<UserEntity>>((ref) async {
  final dio = ref.read(dioProvider);
  final response = await dio.get('/admin/users/unverified');
  return (response.data as List).map((e) => UserEntity.fromJson(e)).toList();
});

class AdminDashboardPage extends ConsumerWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unverifiedUsersAsync = ref.watch(unverifiedUsersProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: CustomScrollView(
        slivers: [
          const SliverAppBar(
            backgroundColor: Color(0xFF121212),
            floating: true,
            title: Text(
              'Admin Dashboard',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pending Verification',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Users waiting for creator access',
                    style: TextStyle(fontSize: 13, color: Color(0xFFB3B3B3)),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          unverifiedUsersAsync.when(
            data: (users) {
              if (users.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified_user, size: 64, color: Color(0xFF1DB954)),
                        SizedBox(height: 16),
                        Text(
                          'All users verified!',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'No pending verification requests.',
                          style: TextStyle(color: Color(0xFFB3B3B3), fontSize: 14),
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
                    (context, index) => _UserVerificationCard(
                      user: users[index],
                      onVerify: () async {
                        try {
                          final dio = ref.read(dioProvider);
                          await dio.put('/admin/users/${users[index].id}/verify');
                          ref.invalidate(unverifiedUsersProvider);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${users[index].username} is now verified!'),
                                backgroundColor: const Color(0xFF1DB954),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        }
                      },
                    ),
                    childCount: users.length,
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
                    Text('Error: $e', style: const TextStyle(color: Color(0xFFB3B3B3))),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => ref.invalidate(unverifiedUsersProvider),
                      child: const Text('Retry', style: TextStyle(color: Color(0xFF1DB954))),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UserVerificationCard extends StatelessWidget {
  const _UserVerificationCard({required this.user, required this.onVerify});
  final UserEntity user;
  final VoidCallback onVerify;

  @override
  Widget build(BuildContext context) {
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
            child: Text(
              user.username[0].toUpperCase(),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.username,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
                ),
                const SizedBox(height: 2),
                Text(
                  user.email,
                  style: const TextStyle(color: Color(0xFFB3B3B3), fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF1DB954),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: const StadiumBorder(),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: onVerify,
            child: const Text('Verify', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
