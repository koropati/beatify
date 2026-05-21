import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/local_playlist_entity.dart';
import '../../domain/repositories/local_playlist_repository.dart';
import '../../data/datasources/local_playlist_data_source.dart';
import '../../data/repositories/local_playlist_repository_impl.dart';
import '../../domain/usecases/get_local_playlists.dart';
import '../../domain/usecases/create_local_playlist.dart';
import '../../domain/usecases/update_local_playlist.dart';
import '../../domain/usecases/delete_local_playlist.dart';
import '../../domain/usecases/add_song_to_local_playlist.dart';
import '../../domain/usecases/remove_song_from_local_playlist.dart';

final localPlaylistDataSourceProvider = Provider<LocalPlaylistDataSource>(
  (_) => LocalPlaylistDataSourceImpl(),
);

final localPlaylistRepositoryProvider = Provider<LocalPlaylistRepository>(
  (ref) => LocalPlaylistRepositoryImpl(ref.read(localPlaylistDataSourceProvider)),
);

final getLocalPlaylistsUseCaseProvider = Provider<GetLocalPlaylists>(
  (ref) => GetLocalPlaylists(ref.read(localPlaylistRepositoryProvider)),
);

final createLocalPlaylistUseCaseProvider = Provider<CreateLocalPlaylist>(
  (ref) => CreateLocalPlaylist(ref.read(localPlaylistRepositoryProvider)),
);

final updateLocalPlaylistUseCaseProvider = Provider<UpdateLocalPlaylist>(
  (ref) => UpdateLocalPlaylist(ref.read(localPlaylistRepositoryProvider)),
);

final deleteLocalPlaylistUseCaseProvider = Provider<DeleteLocalPlaylist>(
  (ref) => DeleteLocalPlaylist(ref.read(localPlaylistRepositoryProvider)),
);

final addSongToPlaylistUseCaseProvider = Provider<AddSongToLocalPlaylist>(
  (ref) => AddSongToLocalPlaylist(ref.read(localPlaylistRepositoryProvider)),
);

final removeSongFromPlaylistUseCaseProvider = Provider<RemoveSongFromLocalPlaylist>(
  (ref) => RemoveSongFromLocalPlaylist(ref.read(localPlaylistRepositoryProvider)),
);

final localPlaylistsProvider = FutureProvider<List<LocalPlaylistEntity>>((ref) async {
  final result = await ref.read(getLocalPlaylistsUseCaseProvider).call();
  return result.fold((e) => throw e, (p) => p);
});
