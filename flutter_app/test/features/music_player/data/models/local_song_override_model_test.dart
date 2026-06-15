import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/features/music_player/data/models/local_song_override_model.dart';
import 'package:flutter_app/features/music_player/domain/entities/local_song_override_entity.dart';

void main() {
  group('LocalSongOverrideModel', () {
    test('is a LocalSongOverrideEntity', () {
      const model = LocalSongOverrideModel(songId: 'abc');
      expect(model, isA<LocalSongOverrideEntity>());
    });

    group('fromMap', () {
      test('maps all fields correctly', () {
        final map = {
          'song_id': 's1',
          'title': 'New Title',
          'artist': 'New Artist',
          'album': 'New Album',
          'cover_image_path': '/path/cover.jpg',
          'backend_song_id': 42,
        };

        final model = LocalSongOverrideModel.fromMap(map);

        expect(model.songId, 's1');
        expect(model.title, 'New Title');
        expect(model.artist, 'New Artist');
        expect(model.album, 'New Album');
        expect(model.coverImagePath, '/path/cover.jpg');
        expect(model.backendSongId, 42);
      });

      test('nullable fields are null when absent', () {
        final map = {
          'song_id': 's2',
          'title': null,
          'artist': null,
          'album': null,
          'cover_image_path': null,
          'backend_song_id': null,
        };

        final model = LocalSongOverrideModel.fromMap(map);

        expect(model.songId, 's2');
        expect(model.title, isNull);
        expect(model.artist, isNull);
        expect(model.album, isNull);
        expect(model.coverImagePath, isNull);
        expect(model.backendSongId, isNull);
      });
    });

    group('toMap', () {
      test('serializes all fields', () {
        const model = LocalSongOverrideModel(
          songId: 's3',
          title: 'T',
          artist: 'A',
          album: 'Al',
          coverImagePath: '/c.jpg',
          backendSongId: 7,
        );

        expect(model.toMap(), {
          'song_id': 's3',
          'title': 'T',
          'artist': 'A',
          'album': 'Al',
          'cover_image_path': '/c.jpg',
          'backend_song_id': 7,
        });
      });

      test('serializes nulls for unset optional fields', () {
        const model = LocalSongOverrideModel(songId: 's4');

        expect(model.toMap(), {
          'song_id': 's4',
          'title': null,
          'artist': null,
          'album': null,
          'cover_image_path': null,
          'backend_song_id': null,
        });
      });
    });

    test('fromMap then toMap round-trips', () {
      final map = {
        'song_id': 's5',
        'title': 'Round',
        'artist': 'Trip',
        'album': 'Album',
        'cover_image_path': '/r.jpg',
        'backend_song_id': 99,
      };

      expect(LocalSongOverrideModel.fromMap(map).toMap(), map);
    });
  });
}
