import 'package:dio/dio.dart';
import 'package:mockito/annotations.dart';
import 'package:flutter_app/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:flutter_app/features/music_player/data/datasources/music_remote_data_source.dart';
import 'package:flutter_app/features/music_player/data/datasources/music_local_data_source.dart';
import 'package:flutter_app/features/music_player/data/datasources/local_song_override_data_source.dart';
import 'package:flutter_app/core/network/secure_storage.dart';
import 'package:flutter_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:flutter_app/features/music_player/data/repositories/music_repository_impl.dart';
import 'package:flutter_app/features/reading_book/data/datasources/book_file_data_source.dart';
import 'package:flutter_app/features/reading_book/data/datasources/book_library_data_source.dart';
import 'package:flutter_app/features/reading_book/data/repositories/reading_book_repository_impl.dart';

@GenerateMocks([
  AuthRemoteDataSource,
  MusicRemoteDataSource,
  MusicLocalDataSource,
  LocalSongOverrideDataSource,
  SecureStorage,
  AuthRepositoryImpl,
  MusicRepositoryImpl,
  BookFileDataSource,
  BookLibraryDataSource,
  ReadingBookRepositoryImpl,
  Dio,
])
void main() {}
