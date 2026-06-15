import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/features/music_player/domain/entities/song_entity.dart';
import 'package:flutter_app/features/music_player/domain/usecases/is_local_song_published.dart';

SongEntity _song(String title, String artist) => SongEntity(
      id: 't',
      title: title,
      artist: artist,
      duration: 1,
      uri: 'x',
      isLocal: true,
    );

void main() {
  final usecase = IsLocalSongPublished();

  final online = [
    SongEntity(
      id: '1',
      title: 'Bohemian Rhapsody',
      artist: 'Queen',
      duration: 1,
      uri: 'x',
      isLocal: false,
    ),
  ];

  test('returns true when backendSongId is set', () {
    expect(usecase.call(_song('Anything', 'X'), const [], backendSongId: 5),
        true);
  });

  test('returns true when title+artist match an online song (case-insensitive)',
      () {
    expect(usecase.call(_song('bohemian rhapsody', 'QUEEN'), online), true);
  });

  test('trims whitespace before matching', () {
    expect(usecase.call(_song('  Bohemian Rhapsody  ', ' Queen '), online), true);
  });

  test('returns false when no match and no backend id', () {
    expect(usecase.call(_song('Unknown', 'Nobody'), online), false);
  });

  test('returns false against an empty online list', () {
    expect(usecase.call(_song('Bohemian Rhapsody', 'Queen'), const []), false);
  });
}
