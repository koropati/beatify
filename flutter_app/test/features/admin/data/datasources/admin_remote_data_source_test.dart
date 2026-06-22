import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_app/features/admin/data/datasources/admin_remote_data_source.dart';
import '../../../../mocks.mocks.dart';

Response<dynamic> _resp(int code, [dynamic data]) =>
    Response(requestOptions: RequestOptions(path: '/'), statusCode: code, data: data);

DioException _dioErr([String? detail]) => DioException(
      requestOptions: RequestOptions(path: '/'),
      response: detail == null
          ? null
          : Response(requestOptions: RequestOptions(path: '/'), data: {'detail': detail}),
    );

Map<String, dynamic> _user(int id, String name) => {
      'id': id,
      'username': name,
      'email': '$name@test.com',
      'role': 'user',
      'is_verified': false,
    };

Map<String, dynamic> _song(int id) => {
      'id': id,
      'title': 'Song $id',
      'artist': 'Artist',
      'album': null,
      'duration': 100,
      'file_url': 'http://localhost:8000/api/songs/stream/$id',
      'cover_image_url': null,
    };

void main() {
  late MockDio dio;
  late AdminRemoteDataSourceImpl ds;

  setUp(() {
    dio = MockDio();
    ds = AdminRemoteDataSourceImpl(dio: dio);
  });

  group('getAllUsers', () {
    test('returns users on 200', () async {
      when(dio.get(any)).thenAnswer((_) async => _resp(200, [_user(1, 'a'), _user(2, 'b')]));
      final users = await ds.getAllUsers();
      expect(users.length, 2);
      expect(users.first.username, 'a');
    });

    test('throws on non-200', () async {
      when(dio.get(any)).thenAnswer((_) async => _resp(500));
      expect(() => ds.getAllUsers(), throwsA(isA<Exception>()));
    });

    test('throws with detail on DioException', () async {
      when(dio.get(any)).thenThrow(_dioErr('nope'));
      expect(() => ds.getAllUsers(), throwsA(predicate((e) => '$e'.contains('nope'))));
    });
  });

  group('getUnverifiedUsers', () {
    test('returns users on 200', () async {
      when(dio.get(any)).thenAnswer((_) async => _resp(200, [_user(2, 'b')]));
      final users = await ds.getUnverifiedUsers();
      expect(users.single.username, 'b');
    });

    test('throws on non-200', () async {
      when(dio.get(any)).thenAnswer((_) async => _resp(403));
      expect(() => ds.getUnverifiedUsers(), throwsA(isA<Exception>()));
    });

    test('throws with detail on DioException', () async {
      when(dio.get(any)).thenThrow(_dioErr('forbidden'));
      expect(() => ds.getUnverifiedUsers(),
          throwsA(predicate((e) => '$e'.contains('forbidden'))));
    });
  });

  group('verifyUser', () {
    test('returns user on 200', () async {
      when(dio.put(any)).thenAnswer((_) async => _resp(200, _user(2, 'b')));
      final user = await ds.verifyUser(2);
      expect(user.id, 2);
    });

    test('throws on non-200', () async {
      when(dio.put(any)).thenAnswer((_) async => _resp(404));
      expect(() => ds.verifyUser(2), throwsA(isA<Exception>()));
    });

    test('throws with detail on DioException', () async {
      when(dio.put(any)).thenThrow(_dioErr('not found'));
      expect(() => ds.verifyUser(2), throwsA(predicate((e) => '$e'.contains('not found'))));
    });
  });

  group('updateUser', () {
    test('returns user on 200 and sends only provided fields', () async {
      when(dio.put(any, data: anyNamed('data')))
          .thenAnswer((_) async => _resp(200, _user(2, 'edited')));
      final user = await ds.updateUser(2, username: 'edited', role: 'admin', isVerified: true);
      expect(user.username, 'edited');
      final data = verify(dio.put(any, data: captureAnyNamed('data'))).captured.single as Map;
      expect(data['username'], 'edited');
      expect(data['role'], 'admin');
      expect(data['is_verified'], true);
      expect(data.containsKey('email'), false);
    });

    test('omits empty email', () async {
      when(dio.put(any, data: anyNamed('data')))
          .thenAnswer((_) async => _resp(200, _user(2, 'b')));
      await ds.updateUser(2, email: '');
      final data = verify(dio.put(any, data: captureAnyNamed('data'))).captured.single as Map;
      expect(data.containsKey('email'), false);
    });

    test('throws on non-200', () async {
      when(dio.put(any, data: anyNamed('data'))).thenAnswer((_) async => _resp(400));
      expect(() => ds.updateUser(2, username: 'x'), throwsA(isA<Exception>()));
    });

    test('throws with detail on DioException', () async {
      when(dio.put(any, data: anyNamed('data'))).thenThrow(_dioErr('taken'));
      expect(() => ds.updateUser(2, username: 'x'),
          throwsA(predicate((e) => '$e'.contains('taken'))));
    });
  });

  group('getAllSongs', () {
    test('returns songs on 200', () async {
      when(dio.get(any)).thenAnswer((_) async => _resp(200, [_song(1), _song(2)]));
      final songs = await ds.getAllSongs();
      expect(songs.length, 2);
      expect(songs.first.id, '1');
    });

    test('throws on non-200', () async {
      when(dio.get(any)).thenAnswer((_) async => _resp(500));
      expect(() => ds.getAllSongs(), throwsA(isA<Exception>()));
    });

    test('throws with detail on DioException', () async {
      when(dio.get(any)).thenThrow(_dioErr('boom'));
      expect(() => ds.getAllSongs(), throwsA(predicate((e) => '$e'.contains('boom'))));
    });
  });

  group('updateSong', () {
    test('returns song on 200', () async {
      when(dio.put(any, data: anyNamed('data')))
          .thenAnswer((_) async => _resp(200, _song(1)));
      final song = await ds.updateSong(1, title: 'New', artist: 'A', album: 'Al');
      expect(song.id, '1');
      final data = verify(dio.put(any, data: captureAnyNamed('data'))).captured.single as Map;
      expect(data['title'], 'New');
    });

    test('throws on non-200', () async {
      when(dio.put(any, data: anyNamed('data'))).thenAnswer((_) async => _resp(404));
      expect(() => ds.updateSong(1, title: 'x'), throwsA(isA<Exception>()));
    });

    test('throws with detail on DioException', () async {
      when(dio.put(any, data: anyNamed('data'))).thenThrow(_dioErr('missing'));
      expect(() => ds.updateSong(1, title: 'x'),
          throwsA(predicate((e) => '$e'.contains('missing'))));
    });
  });

  group('deleteSong', () {
    test('completes on 2xx', () async {
      when(dio.delete(any)).thenAnswer((_) async => _resp(200, {'message': 'ok'}));
      await ds.deleteSong(1);
    });

    test('throws on non-2xx', () async {
      when(dio.delete(any)).thenAnswer((_) async => _resp(500));
      expect(() => ds.deleteSong(1), throwsA(isA<Exception>()));
    });

    test('throws with detail on DioException', () async {
      when(dio.delete(any)).thenThrow(_dioErr('not found'));
      expect(() => ds.deleteSong(1), throwsA(predicate((e) => '$e'.contains('not found'))));
    });
  });
}
