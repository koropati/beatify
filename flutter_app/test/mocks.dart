import 'package:dio/dio.dart';
import 'package:mockito/annotations.dart';
import 'package:flutter_app/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:flutter_app/features/music_player/data/datasources/music_remote_data_source.dart';
import 'package:flutter_app/features/music_player/data/datasources/music_local_data_source.dart';
import 'package:flutter_app/core/network/secure_storage.dart';
import 'package:flutter_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:flutter_app/features/music_player/data/repositories/music_repository_impl.dart';

@GenerateMocks([
  AuthRemoteDataSource,
  MusicRemoteDataSource,
  MusicLocalDataSource,
  SecureStorage,
  AuthRepositoryImpl,
  MusicRepositoryImpl,
  Dio,
])
void main() {}
