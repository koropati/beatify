import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_app/features/music_player/domain/entities/local_song_override_entity.dart';
import 'package:flutter_app/features/music_player/domain/entities/song_entity.dart';
import 'package:flutter_app/features/music_player/domain/usecases/get_local_song_overrides.dart';
import 'package:flutter_app/features/music_player/domain/usecases/update_local_song_metadata.dart';
import 'package:flutter_app/features/music_player/domain/usecases/upload_local_song_to_public.dart';
import '../../../../mocks.mocks.dart';

void main() {
  late MockMusicRepositoryImpl repo;

  setUp(() => repo = MockMusicRepositoryImpl());

  test('UpdateLocalSongMetadata delegates to repository', () async {
    when(repo.updateLocalSongMetadata(any,
            title: anyNamed('title'),
            artist: anyNamed('artist'),
            album: anyNamed('album'),
            coverImagePath: anyNamed('coverImagePath')))
        .thenAnswer((_) async => const Right(null));

    final result = await UpdateLocalSongMetadata(repo)
        .call('10', title: 'T', artist: 'A', album: 'Al', coverImagePath: 'c');

    expect(result.isRight(), true);
    verify(repo.updateLocalSongMetadata('10',
            title: 'T', artist: 'A', album: 'Al', coverImagePath: 'c'))
        .called(1);
  });

  test('UploadLocalSongToPublic delegates to repository', () async {
    final song = SongEntity(
      id: '10',
      title: 'T',
      artist: 'A',
      duration: 1,
      uri: '/x.mp3',
      isLocal: true,
    );
    when(repo.uploadLocalSongToPublic(any, coverImagePath: anyNamed('coverImagePath')))
        .thenAnswer((_) async => Right(song));

    final result = await UploadLocalSongToPublic(repo).call(song, coverImagePath: 'c');

    expect(result.isRight(), true);
    verify(repo.uploadLocalSongToPublic(song, coverImagePath: 'c')).called(1);
  });

  test('GetLocalSongOverrides delegates to repository', () async {
    when(repo.getLocalSongOverrides()).thenAnswer(
        (_) async => const Right([LocalSongOverrideEntity(songId: '10')]));

    final result = await GetLocalSongOverrides(repo).call();

    expect(result.isRight(), true);
    result.fold((_) => fail('expected Right'), (list) => expect(list.length, 1));
    verify(repo.getLocalSongOverrides()).called(1);
  });
}
