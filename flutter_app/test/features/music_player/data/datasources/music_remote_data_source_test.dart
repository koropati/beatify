import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_app/features/music_player/data/datasources/music_remote_data_source.dart';
import '../../../../mocks.mocks.dart';

Response<dynamic> _resp(int code, [dynamic data]) =>
    Response(requestOptions: RequestOptions(path: '/'), statusCode: code, data: data);

Map<String, dynamic> _uploadedJson() => {
      'id': 42,
      'title': 'Song',
      'artist': 'Artist',
      'album': 'Album',
      'duration': 100,
      'file_url': 'http://localhost:8000/api/songs/stream/42',
      'cover_image_url': null,
    };

void main() {
  late MockDio dio;
  late MusicRemoteDataSourceImpl ds;
  late Directory tmpDir;
  late String audioPath;
  late String coverPath;

  setUp(() async {
    dio = MockDio();
    ds = MusicRemoteDataSourceImpl(dio: dio);
    tmpDir = await Directory.systemTemp.createTemp('beatify_test');
    audioPath = '${tmpDir.path}/song.mp3';
    coverPath = '${tmpDir.path}/cover.jpg';
    await File(audioPath).writeAsBytes([0, 1, 2, 3]);
    await File(coverPath).writeAsBytes([4, 5, 6, 7]);
  });

  tearDown(() async {
    if (await tmpDir.exists()) await tmpDir.delete(recursive: true);
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

  test('uploadSong returns parsed song on 200 with album and cover', () async {
    when(dio.post(any, data: anyNamed('data')))
        .thenAnswer((_) async => _resp(200, _uploadedJson()));

    final song = await ds.uploadSong(
      title: 'Song',
      artist: 'Artist',
      album: 'Album',
      filePath: audioPath,
      coverImagePath: coverPath,
    );

    expect(song.id, '42');
    expect(song.title, 'Song');
    expect(song.isLocal, false);
  });

  test('uploadSong works without album and cover', () async {
    when(dio.post(any, data: anyNamed('data')))
        .thenAnswer((_) async => _resp(201, _uploadedJson()));

    final song = await ds.uploadSong(
      title: 'Song',
      artist: 'Artist',
      filePath: audioPath,
    );

    expect(song.id, '42');
  });

  test('uploadSong throws on non-2xx', () async {
    when(dio.post(any, data: anyNamed('data')))
        .thenAnswer((_) async => _resp(500));
    expect(
      () => ds.uploadSong(title: 'S', artist: 'A', filePath: audioPath),
      throwsA(isA<Exception>()),
    );
  });

  test('uploadSong throws when dio throws', () async {
    when(dio.post(any, data: anyNamed('data')))
        .thenThrow(Exception('network down'));
    expect(
      () => ds.uploadSong(title: 'S', artist: 'A', filePath: audioPath),
      throwsA(isA<Exception>()),
    );
  });
}
