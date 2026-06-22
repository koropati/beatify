import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_app/features/auth/data/datasources/auth_remote_data_source.dart';
import '../../../../mocks.mocks.dart';

Response<dynamic> _resp(int code, [dynamic data]) =>
    Response(requestOptions: RequestOptions(path: '/'), statusCode: code, data: data);

DioException _dioErr([String? detail]) => DioException(
      requestOptions: RequestOptions(path: '/'),
      response: detail == null
          ? null
          : Response(requestOptions: RequestOptions(path: '/'), data: {'detail': detail}),
    );

final _userJson = {
  'id': 1,
  'username': 'u',
  'email': 'u@test.com',
  'role': 'user',
  'is_verified': false,
};

void main() {
  late MockDio dio;
  late AuthRemoteDataSourceImpl ds;

  setUp(() {
    dio = MockDio();
    ds = AuthRemoteDataSourceImpl(dio: dio);
  });

  group('login', () {
    test('returns access_token on 200', () async {
      when(dio.post(any, data: anyNamed('data')))
          .thenAnswer((_) async => _resp(200, {'access_token': 'tok'}));
      expect(await ds.login('u', 'p'), 'tok');
    });

    test('throws on non-200', () async {
      when(dio.post(any, data: anyNamed('data'))).thenAnswer((_) async => _resp(500));
      expect(() => ds.login('u', 'p'), throwsA(isA<Exception>()));
    });

    test('throws with detail on DioException', () async {
      when(dio.post(any, data: anyNamed('data'))).thenThrow(_dioErr('Bad creds'));
      expect(() => ds.login('u', 'p'), throwsA(predicate((e) => '$e'.contains('Bad creds'))));
    });
  });

  group('register', () {
    test('returns UserEntity on 200', () async {
      when(dio.post(any, data: anyNamed('data')))
          .thenAnswer((_) async => _resp(200, _userJson));
      final user = await ds.register('u', 'u@test.com', 'p');
      expect(user.username, 'u');
    });

    test('throws on non-200', () async {
      when(dio.post(any, data: anyNamed('data'))).thenAnswer((_) async => _resp(400));
      expect(() => ds.register('u', 'e', 'p'), throwsA(isA<Exception>()));
    });

    test('throws with detail on DioException', () async {
      when(dio.post(any, data: anyNamed('data'))).thenThrow(_dioErr('Email taken'));
      expect(() => ds.register('u', 'e', 'p'),
          throwsA(predicate((e) => '$e'.contains('Email taken'))));
    });
  });

  group('getCurrentUser', () {
    test('returns UserEntity on 200', () async {
      when(dio.get(any)).thenAnswer((_) async => _resp(200, _userJson));
      final user = await ds.getCurrentUser();
      expect(user.id, 1);
    });

    test('throws on non-200', () async {
      when(dio.get(any)).thenAnswer((_) async => _resp(401));
      expect(() => ds.getCurrentUser(), throwsA(isA<Exception>()));
    });

    test('throws when dio throws', () async {
      when(dio.get(any)).thenThrow(Exception('boom'));
      expect(() => ds.getCurrentUser(), throwsA(isA<Exception>()));
    });
  });

  group('updateProfile', () {
    test('returns UserEntity on 200', () async {
      when(dio.put(any, data: anyNamed('data')))
          .thenAnswer((_) async => _resp(200, _userJson));
      final user = await ds.updateProfile('newname');
      expect(user.email, 'u@test.com');
    });

    test('sends email in payload when provided', () async {
      when(dio.put(any, data: anyNamed('data')))
          .thenAnswer((_) async => _resp(200, _userJson));
      await ds.updateProfile('newname', email: 'new@test.com');
      final data = verify(dio.put(any, data: captureAnyNamed('data')))
          .captured
          .single as Map;
      expect(data['email'], 'new@test.com');
      expect(data['username'], 'newname');
    });

    test('omits email when empty', () async {
      when(dio.put(any, data: anyNamed('data')))
          .thenAnswer((_) async => _resp(200, _userJson));
      await ds.updateProfile('newname', email: '');
      final data = verify(dio.put(any, data: captureAnyNamed('data')))
          .captured
          .single as Map;
      expect(data.containsKey('email'), false);
    });

    test('throws on non-200', () async {
      when(dio.put(any, data: anyNamed('data'))).thenAnswer((_) async => _resp(400));
      expect(() => ds.updateProfile('x'), throwsA(isA<Exception>()));
    });

    test('throws with detail on DioException', () async {
      when(dio.put(any, data: anyNamed('data'))).thenThrow(_dioErr('Username taken'));
      expect(() => ds.updateProfile('x'),
          throwsA(predicate((e) => '$e'.contains('Username taken'))));
    });
  });

  group('uploadProfilePicture', () {
    late Directory tmpDir;
    late String picturePath;

    setUp(() async {
      tmpDir = await Directory.systemTemp.createTemp('beatify_pic');
      picturePath = '${tmpDir.path}/avatar.png';
      await File(picturePath).writeAsBytes([1, 2, 3, 4]);
    });

    tearDown(() async {
      if (await tmpDir.exists()) await tmpDir.delete(recursive: true);
    });

    test('returns UserEntity on 2xx', () async {
      when(dio.post(any, data: anyNamed('data')))
          .thenAnswer((_) async => _resp(200, _userJson));
      final user = await ds.uploadProfilePicture(picturePath);
      expect(user.id, 1);
    });

    test('throws on non-2xx', () async {
      when(dio.post(any, data: anyNamed('data'))).thenAnswer((_) async => _resp(500));
      expect(() => ds.uploadProfilePicture(picturePath), throwsA(isA<Exception>()));
    });

    test('throws with detail on DioException', () async {
      when(dio.post(any, data: anyNamed('data'))).thenThrow(_dioErr('Not an image'));
      expect(() => ds.uploadProfilePicture(picturePath),
          throwsA(predicate((e) => '$e'.contains('Not an image'))));
    });
  });

  group('changePassword', () {
    test('completes on 200', () async {
      when(dio.put(any, data: anyNamed('data'))).thenAnswer((_) async => _resp(200));
      await ds.changePassword('old', 'new');
    });

    test('throws on non-200', () async {
      when(dio.put(any, data: anyNamed('data'))).thenAnswer((_) async => _resp(400));
      expect(() => ds.changePassword('old', 'new'), throwsA(isA<Exception>()));
    });

    test('throws with detail on DioException', () async {
      when(dio.put(any, data: anyNamed('data'))).thenThrow(_dioErr('Wrong password'));
      expect(() => ds.changePassword('old', 'new'),
          throwsA(predicate((e) => '$e'.contains('Wrong password'))));
    });
  });

  group('forgotPassword', () {
    test('returns token on 200', () async {
      when(dio.post(any, data: anyNamed('data')))
          .thenAnswer((_) async => _resp(200, {'token': '123456'}));
      expect(await ds.forgotPassword('u@test.com'), '123456');
    });

    test('throws on non-200', () async {
      when(dio.post(any, data: anyNamed('data'))).thenAnswer((_) async => _resp(500));
      expect(() => ds.forgotPassword('e'), throwsA(isA<Exception>()));
    });

    test('throws with detail on DioException', () async {
      when(dio.post(any, data: anyNamed('data'))).thenThrow(_dioErr('Server error'));
      expect(() => ds.forgotPassword('e'),
          throwsA(predicate((e) => '$e'.contains('Server error'))));
    });
  });

  group('resetPassword', () {
    test('completes on 200', () async {
      when(dio.post(any, data: anyNamed('data'))).thenAnswer((_) async => _resp(200));
      await ds.resetPassword('123456', 'newpass');
    });

    test('throws on non-200', () async {
      when(dio.post(any, data: anyNamed('data'))).thenAnswer((_) async => _resp(400));
      expect(() => ds.resetPassword('t', 'p'), throwsA(isA<Exception>()));
    });

    test('throws with detail on DioException', () async {
      when(dio.post(any, data: anyNamed('data'))).thenThrow(_dioErr('Token expired'));
      expect(() => ds.resetPassword('t', 'p'),
          throwsA(predicate((e) => '$e'.contains('Token expired'))));
    });
  });
}
