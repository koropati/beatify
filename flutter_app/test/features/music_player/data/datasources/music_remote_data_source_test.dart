import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_app/features/music_player/data/datasources/music_remote_data_source.dart';
import '../../../../mocks.mocks.dart';

Response<dynamic> _resp(int code, [dynamic data]) =>
    Response(requestOptions: RequestOptions(path: '/'), statusCode: code, data: data);

void main() {
  late MockDio dio;
  late MusicRemoteDataSourceImpl ds;

  setUp(() {
    dio = MockDio();
    ds = MusicRemoteDataSourceImpl(dio: dio);
  });

  test('getOnlineSongs returns parsed songs on 200', () async {
    when(dio.get(any)).thenAnswer((_) async => _resp(200, [
          {
            'id': 1,
            'title': 'Song',
            'artist': 'Artist',
            'album': null,
            'duration': 100,
            'file_url': 'http://localhost:8000/api/songs/stream/1',
            'cover_image_url': null,
          }
        ]));

    final songs = await ds.getOnlineSongs();
    expect(songs.length, 1);
    expect(songs.first.title, 'Song');
    expect(songs.first.isLocal, false);
  });

  test('getOnlineSongs returns empty list on empty 200', () async {
    when(dio.get(any)).thenAnswer((_) async => _resp(200, []));
    expect(await ds.getOnlineSongs(), isEmpty);
  });

  test('getOnlineSongs throws on non-200', () async {
    when(dio.get(any)).thenAnswer((_) async => _resp(500));
    expect(() => ds.getOnlineSongs(), throwsA(isA<Exception>()));
  });

  test('getOnlineSongs throws when dio throws', () async {
    when(dio.get(any)).thenThrow(Exception('network down'));
    expect(() => ds.getOnlineSongs(), throwsA(isA<Exception>()));
  });
}
