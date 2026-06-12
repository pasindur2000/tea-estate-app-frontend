import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/estate.dart';

class SecureStorageService {
  static const _tokenKey = 'auth_token';
  static const _estateKey = 'selected_estate';

  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  // ── Auth token ──────────────────────────────────────────────────────────
  Future<void> saveToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  Future<String?> getToken() => _storage.read(key: _tokenKey);

  Future<void> deleteToken() => _storage.delete(key: _tokenKey);

  // ── Selected estate ─────────────────────────────────────────────────────
  Future<void> saveEstate(Estate estate) => _storage.write(
        key: _estateKey,
        value: jsonEncode({
          'estateId': estate.estateId,
          'name': estate.name,
          'location': estate.location,
          'status': estate.status,
        }),
      );

  Future<Estate?> loadEstate() async {
    final raw = await _storage.read(key: _estateKey);
    if (raw == null) return null;
    return Estate.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> deleteEstate() => _storage.delete(key: _estateKey);
}
