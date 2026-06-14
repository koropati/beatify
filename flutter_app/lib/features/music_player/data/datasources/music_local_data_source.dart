// coverage:ignore-file
// Wraps on_audio_query + permission_handler platform plugins; exercised on
// device, not in unit tests.
import 'package:on_audio_query/on_audio_query.dart' hide SongModel;
import 'package:on_audio_query/on_audio_query.dart' as oaq show SongModel;
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
      return songs
          .where(_isRealMusic)
          .map((song) => SongModel(
                id: song.id.toString(),
                title: song.title,
                artist: song.artist ?? "Unknown Artist",
                album: song.album,
                duration: (song.duration ?? 0) ~/ 1000,
                uri: song.data,
                isLocal: true,
              ))
          .toList();
    } catch (e) {
      throw Exception("Failed to query local songs: $e");
    }
  }

  // Keep only actual songs — drop ringtones, alarms, notifications, recordings,
  // app voice notes, and short system/UI sounds that MediaStore also reports.
  bool _isRealMusic(oaq.SongModel song) {
    if (song.isMusic != true) return false;
    if (song.isAlarm == true ||
        song.isNotification == true ||
        song.isRingtone == true) {
      return false;
    }
    if ((song.duration ?? 0) < 30000) return false; // < 30s = not a song
    return !_isNonMusicPath(song.data);
  }

  bool _isNonMusicPath(String? path) {
    if (path == null) return false;
    final lower = path.toLowerCase();
    return lower.contains('/recordings/') ||
        lower.contains('/recording/') ||
        lower.contains('/voicerecorder/') ||
        lower.contains('/voice_recorder/') ||
        lower.contains('/voice recorder/') ||
        lower.contains('/audiorecorder/') ||
        lower.contains('/callrecording') ||
        lower.contains('/call_recording') ||
        lower.contains('sound_recorder') ||
        lower.contains('/captured/') ||
        lower.contains('/notifications/') ||
        lower.contains('/ringtones/') ||
        lower.contains('/alarms/') ||
        lower.contains('/whatsapp/') ||
        lower.contains('/whatsapp business/') ||
        lower.contains('/telegram/') ||
        lower.contains('voice notes') ||
        lower.contains('/android/media/');
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
