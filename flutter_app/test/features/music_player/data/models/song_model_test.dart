import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/features/music_player/data/models/song_model.dart';

void main() {
  group('SongModel.fromJson', () {
    test('maps all fields correctly', () {
      final json = {
        'id': 1,
        'title': 'Bohemian Rhapsody',
        'artist': 'Queen',
        'album': 'A Night at the Opera',
        'duration': 354,
        'file_url': 'http://localhost:8000/api/songs/stream/1',
        'cover_image_url': 'http://localhost:8000/api/image/cover.jpg',
      };

      final model = SongModel.fromJson(json);

      expect(model.id, '1');
      expect(model.title, 'Bohemian Rhapsody');
      expect(model.artist, 'Queen');
      expect(model.album, 'A Night at the Opera');
      expect(model.duration, 354);
      // fixUrl rewrites localhost origin to the production origin.
      expect(model.uri, 'https://beatify-api.satriakode.com/api/songs/stream/1');
      expect(model.coverImageUrl, 'https://beatify-api.satriakode.com/api/image/cover.jpg');
      expect(model.isLocal, false);
    });

    test('converts integer id to String', () {
      final json = {
        'id': 42,
        'title': 'Track',
        'artist': 'Artist',
        'duration': 180,
        'file_url': 'http://url',
      };

      final model = SongModel.fromJson(json);

      expect(model.id, '42');
      expect(model.id, isA<String>());
    });

    test('nullable album and cover_image_url are null', () {
      final json = {
        'id': 2,
        'title': 'No Cover',
        'artist': 'Artist',
        'album': null,
        'duration': 200,
        'file_url': 'http://localhost:8000/api/songs/stream/2',
        'cover_image_url': null,
      };

      final model = SongModel.fromJson(json);

      expect(model.album, isNull);
      expect(model.coverImageUrl, isNull);
    });

    test('isLocal is always false for remote songs', () {
      final json = {
        'id': 3,
        'title': 'Remote Song',
        'artist': 'DJ',
        'duration': 240,
        'file_url': 'http://server/stream/3',
      };

      final model = SongModel.fromJson(json);

      expect(model.isLocal, false);
    });

    test('file_url maps to uri field', () {
      final json = {
        'id': 99,
        'title': 'T',
        'artist': 'A',
        'duration': 100,
        'file_url': 'http://localhost:8000/api/songs/stream/99',
      };

      final model = SongModel.fromJson(json);

      // localhost origin is normalized to production by fixUrl.
      expect(model.uri, 'https://beatify-api.satriakode.com/api/songs/stream/99');
    });
  });
}
