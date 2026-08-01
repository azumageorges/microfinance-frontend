import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';

/// Stockage du JWT et du profil utilisateur.
///
/// Le JWT est conservé dans le stockage chiffré de la plateforme
/// (EncryptedSharedPreferences / Keychain / WebCrypto) et non plus en clair
/// dans `SharedPreferences`.
class SecureSessionStorage {
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  const SecureSessionStorage();

  Future<String?> readToken() async {
    await _migrateLegacyPlainStorage();
    return _storage.read(key: AppConstants.tokenKey);
  }

  Future<String?> readUser() async {
    await _migrateLegacyPlainStorage();
    return _storage.read(key: AppConstants.userKey);
  }

  Future<void> writeSession({
    required String token,
    required String userJson,
  }) async {
    await _storage.write(key: AppConstants.tokenKey, value: token);
    await _storage.write(key: AppConstants.userKey, value: userJson);
  }

  Future<void> clear() async {
    await _storage.delete(key: AppConstants.tokenKey);
    await _storage.delete(key: AppConstants.userKey);
    await _removeLegacyPlainStorage();
  }

  static Future<void>? _migration;

  /// Reprend une session écrite par une version antérieure de l'application
  /// (JWT en clair dans `SharedPreferences`) puis efface la copie en clair.
  /// La migration n'est tentée qu'une fois par lancement.
  Future<void> _migrateLegacyPlainStorage() =>
      _migration ??= _runLegacyMigration();

  Future<void> _runLegacyMigration() async {
    final prefs = await SharedPreferences.getInstance();
    final legacyToken = prefs.getString(AppConstants.tokenKey);
    final legacyUser = prefs.getString(AppConstants.userKey);
    if (legacyToken == null && legacyUser == null) return;

    if (legacyToken != null && legacyToken.isNotEmpty && legacyUser != null) {
      await writeSession(token: legacyToken, userJson: legacyUser);
    }
    await _removeLegacyPlainStorage();
  }

  Future<void> _removeLegacyPlainStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.tokenKey);
    await prefs.remove(AppConstants.userKey);
  }
}
