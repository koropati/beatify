import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../music_player/domain/entities/song_entity.dart';
import '../../../music_player/presentation/providers/music_providers.dart';
import '../../data/datasources/admin_remote_data_source.dart';
import '../../data/repositories/admin_repository_impl.dart';

final adminRemoteDataSourceProvider = Provider<AdminRemoteDataSource>((ref) {
  return AdminRemoteDataSourceImpl(dio: ref.read(dioProvider));
});

final adminRepositoryProvider = Provider<AdminRepositoryImpl>((ref) {
  return AdminRepositoryImpl(
    remoteDataSource: ref.read(adminRemoteDataSourceProvider),
  );
});

final allUsersProvider =
    FutureProvider.autoDispose<List<UserEntity>>((ref) async {
  final result = await ref.read(adminRepositoryProvider).getAllUsers();
  return result.fold((failure) => throw failure, (users) => users);
});

final unverifiedUsersProvider =
    FutureProvider.autoDispose<List<UserEntity>>((ref) async {
  final result = await ref.read(adminRepositoryProvider).getUnverifiedUsers();
  return result.fold((failure) => throw failure, (users) => users);
});

final allSongsAdminProvider =
    FutureProvider.autoDispose<List<SongEntity>>((ref) async {
  final result = await ref.read(adminRepositoryProvider).getAllSongs();
  return result.fold((failure) => throw failure, (songs) => songs);
});
