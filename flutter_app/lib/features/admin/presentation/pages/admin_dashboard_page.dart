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
      body: unverifiedUsersAsync.when(
        data: (users) {
          if (users.isEmpty) {
            return const Center(child: Text("All users are verified! 🎉"));
          }
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(user.username, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(user.email),
                trailing: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1DB954), foregroundColor: Colors.black),
                  onPressed: () async {
                     try {
                        final dio = ref.read(dioProvider);
                        await dio.put('/admin/users/${user.id}/verify');
                        ref.invalidate(unverifiedUsersProvider);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${user.username} is now verified!')));
                     } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                     }
                  },
                  child: const Text('Verify'),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text("Error fetching users: $e")),
      ),
    );
  }
}
