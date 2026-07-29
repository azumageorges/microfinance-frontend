import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../core/constants/app_constants.dart';
import '../models/auth_model.dart';

class AuthRepository {
  final ApiClient _apiClient;

  AuthRepository(this._apiClient);

  Future<AuthResponse> login(String email, String password) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/auth/login',
        data: {'email': email, 'motDePasse': password},
      );
      final data = response.data['data'] as Map<String, dynamic>;
      final auth = AuthResponse.fromJson(data);

      // Persister le token et les infos utilisateur
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.tokenKey, auth.token);
      await prefs.setString(AppConstants.userKey, jsonEncode(auth.toJson()));

      return auth;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<AuthResponse?> getStoredUser() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.tokenKey);
    final userJson = prefs.getString(AppConstants.userKey);

    // Evite un faux état "connecté" si l'utilisateur est en cache
    // mais que le JWT n'est plus présent.
    if (token == null || token.isEmpty || userJson == null) {
      await prefs.remove(AppConstants.tokenKey);
      await prefs.remove(AppConstants.userKey);
      return null;
    }

    return AuthResponse.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
  }

  Future<void> clearLocalSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.tokenKey);
    await prefs.remove(AppConstants.userKey);
  }

  /// Révoque le token JWT côté serveur puis supprime les données locales.
  Future<void> logout() async {
    // 1. Révoquer le token côté backend (blacklist JWT)
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.tokenKey);
      if (token != null) {
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
