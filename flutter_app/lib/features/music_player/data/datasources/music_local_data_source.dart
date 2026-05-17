import 'package:on_audio_query/on_audio_query.dart' hide SongModel;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/song_model.dart';

abstract class MusicLocalDataSource {
  Future<List<SongModel>> getLocalSongs();
}

class MusicLocalDataSourceImpl implements MusicLocalDataSource {
  final OnAudioQuery _audioQuery = OnAudioQuery();

  @override
  Future<List<SongModel>> getLocalSongs() async {
    if (kIsWeb) return [];

    final hasPermission = await _checkPermission();
    if (!hasPermission) throw Exception("Permission denied to read local storage");

    try {
      final songs = await _audioQuery.querySongs(
        sortType: null,
        orderType: OrderType.ASC_OR_SMALLER,
        uriType: UriType.EXTERNAL,
        ignoreCase: true,
      );
      return songs.map((song) => SongModel(
        id: song.id.toString(),
        title: song.title,
        artist: song.artist ?? "Unknown Artist",
        album: song.album,
        duration: (song.duration ?? 0) ~/ 1000,
        uri: song.data,
        isLocal: true,
      )).toList();
    } catch (e) {
      throw Exception("Failed to query local songs: $e");
    }
  }

  Future<bool> _checkPermission() async {
    var status = await Permission.storage.status;
    if (status.isDenied) status = await Permission.storage.request();

    if (status.isDenied || status.isPermanentlyDenied) {
      var audioStatus = await Permission.audio.status;
      if (audioStatus.isDenied) audioStatus = await Permission.audio.request();
      return audioStatus.isGranted;
    }

    return status.isGranted;
  }
}
