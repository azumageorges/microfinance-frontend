import 'dart:convert';
import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../core/storage/secure_session_storage.dart';
import '../models/auth_model.dart';

class AuthRepository {
  final ApiClient _apiClient;
  final SecureSessionStorage sessionStorage;

  AuthRepository(
    this._apiClient, {
    this.sessionStorage = const SecureSessionStorage(),
  });

  Future<AuthResponse> login(String email, String password) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/auth/login',
        data: {'email': email, 'motDePasse': password},
      );
      final data = response.data['data'] as Map<String, dynamic>;
      final auth = AuthResponse.fromJson(data);

      // Persister le token (stockage chiffré) et le profil utilisateur.
      // Le profil est sérialisé sans le JWT pour ne pas le dupliquer.
      await sessionStorage.writeSession(
        token: auth.token,
        userJson: jsonEncode(auth.toJson(includeToken: false)),
      );

      return auth;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<AuthResponse?> getStoredUser() async {
    final token = await sessionStorage.readToken();
    final userJson = await sessionStorage.readUser();

    // Evite un faux état "connecté" si l'utilisateur est en cache
    // mais que le JWT n'est plus présent.
    if (token == null || token.isEmpty || userJson == null) {
      await clearLocalSession();
      return null;
    }

    final user = jsonDecode(userJson) as Map<String, dynamic>;
    return AuthResponse.fromJson({...user, 'token': token});
  }

  Future<void> clearLocalSession() => sessionStorage.clear();

  /// Révoque le token JWT côté serveur puis supprime les données locales.
  Future<void> logout() async {
    // 1. Révoquer le token côté backend (blacklist JWT)
    try {
      final token = await sessionStorage.readToken();
      if (token != null && token.isNotEmpty) {
        await _apiClient.dio.post(
          '/api/auth/logout',
          options: Options(headers: {'Authorization': 'Bearer $token'}),
        );
      }
    } catch (_) {
      // Echec réseau toléré — on nettoie quand même localement
    }
    // 2. Supprimer les données locales
    await clearLocalSession();
  }
}
