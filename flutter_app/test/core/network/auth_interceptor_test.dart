import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_app/core/network/auth_interceptor.dart';
import '../../mocks.mocks.dart';

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.statusCode, {this.onFetch});
  final int statusCode;
  final void Function(RequestOptions)? onFetch;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    onFetch?.call(options);
    return ResponseBody.fromString(
      '{}',
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType]
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Dio _dioWith(AuthInterceptor interceptor, _FakeAdapter adapter) =>
    Dio(BaseOptions(baseUrl: 'http://test'))
      ..interceptors.add(interceptor)
      ..httpClientAdapter = adapter;

void main() {
  late MockSecureStorage storage;
  late AuthInterceptor interceptor;

  setUp(() {
    storage = MockSecureStorage();
    interceptor = AuthInterceptor(storage);
    when(storage.getToken()).thenAnswer((_) async => null);
    when(storage.deleteToken()).thenAnswer((_) async {});
  });

  group('onRequest', () {
    test('adds Authorization header when token exists', () async {
      when(storage.getToken()).thenAnswer((_) async => 'tok123');
      RequestOptions? captured;
      final dio = _dioWith(interceptor, _FakeAdapter(200, onFetch: (o) => captured = o));

      await dio.get('/x');

      expect(captured!.headers['Authorization'], 'Bearer tok123');
    });

    test('does not add header when token is null', () async {
      RequestOptions? captured;
      final dio = _dioWith(interceptor, _FakeAdapter(200, onFetch: (o) => captured = o));

      await dio.get('/x');

      expect(captured!.headers.containsKey('Authorization'), false);
    });
  });

  group('onError', () {
    test('deletes token on 401', () async {
      final dio = _dioWith(interceptor, _FakeAdapter(401));

      try {
        await dio.get('/x');
      } on DioException catch (_) {}

      verify(storage.deleteToken()).called(1);
    });

    test('does not delete token on non-401', () async {
      final dio = _dioWith(interceptor, _FakeAdapter(500));

      try {
        await dio.get('/x');
      } on DioException catch (_) {}

      verifyNever(storage.deleteToken());
    });
  });
}
