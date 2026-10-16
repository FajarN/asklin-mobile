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

  static const _savedEmailKey = 'saved_login_email';
  static const _savedPasswordKey = 'saved_login_password';
  static const _rememberMeKey = 'remember_me_enabled';

  static Future<void> saveSavedCredentials(String email, String password) async {
    await _storage.write(key: _savedEmailKey, value: email);
    await _storage.write(key: _savedPasswordKey, value: password);
    await _storage.write(key: _rememberMeKey, value: 'true');
  }

  static Future<String?> getSavedEmail() async {
    return await _storage.read(key: _savedEmailKey);
  }

  static Future<String?> getSavedPassword() async {
    return await _storage.read(key: _savedPasswordKey);
  }

  static Future<bool> isRememberMeEnabled() async {
    final val = await _storage.read(key: _rememberMeKey);
    return val == 'true';
  }

  static Future<void> clearSavedCredentials() async {
    await _storage.delete(key: _savedEmailKey);
    await _storage.delete(key: _savedPasswordKey);
    await _storage.delete(key: _rememberMeKey);
  }

  static Future<void> clearSession() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userKey);
    await _storage.delete(key: _roleKey);
  }

  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}

