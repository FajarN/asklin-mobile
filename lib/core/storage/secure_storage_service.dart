import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'auth_token';
  static const _userKey = 'user_data';
  static const _roleKey = 'user_role';

  static Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  static Future<void> saveUserRole(String role) async {
    await _storage.write(key: _roleKey, value: role);
  }

  static Future<String?> getUserRole() async {
    return await _storage.read(key: _roleKey);
  }

  static Future<void> saveUserData(String jsonString) async {
    await _storage.write(key: _userKey, value: jsonString);
  }

  static Future<String?> getUserData() async {
    return await _storage.read(key: _userKey);
  }

  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
