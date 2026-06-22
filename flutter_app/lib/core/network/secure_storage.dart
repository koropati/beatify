// coverage:ignore-file
// Thin wrapper over the flutter_secure_storage platform plugin — covered by
// integration tests, not unit tests.
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> saveToken(String token) async {
    await _storage.write(key: 'jwt_token', value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: 'jwt_token');
  }

  Future<void> saveUser(String userJson) async {
    await _storage.write(key: 'cached_user', value: userJson);
  }

  Future<String?> getUser() async {
    return await _storage.read(key: 'cached_user');
  }

  Future<void> deleteUser() async {
    await _storage.delete(key: 'cached_user');
  }
}
