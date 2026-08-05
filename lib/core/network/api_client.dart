import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import 'retry_interceptor.dart';

/// Callback appelé quand le token est expiré (401) pour déclencher le logout
typedef OnUnauthorized = void Function();

class ApiClient {
  late final Dio _dio;
  OnUnauthorized? onUnauthorized;

  ApiClient() {
    final baseUrl = AppConstants.baseUrl;
    if (kDebugMode) {
      debugPrint('[API BASE URL] $baseUrl');
    }

    final connectTimeout = const Duration(seconds: 45);
    final receiveTimeout = const Duration(seconds: 60);

    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: connectTimeout,
      receiveTimeout: receiveTimeout,
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(_AuthInterceptor(this));
    _dio.interceptors.add(RetryInterceptor(_dio));
    if (kDebugMode) _dio.interceptors.add(_LogInterceptor());
  }

  Dio get dio => _dio;
}

/// Injecte automatiquement le JWT dans chaque requête
/// et gère la déconnexion automatique sur 401
class _AuthInterceptor extends Interceptor {
  final ApiClient _client;

  _AuthInterceptor(this._client);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.tokenKey);
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    if (kDebugMode) {
      debugPrint(
        '[API AUTH] ${token != null && token.isNotEmpty ? 'token-present' : 'token-missing'} ${options.path}',
      );
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final statusCode = err.response?.statusCode;
    final path = err.requestOptions.path;
    final isAuthEndpoint = path.startsWith('/api/auth/');
    if (!isAuthEndpoint && (statusCode == 401 || statusCode == 403)) {
      _client.onUnauthorized?.call();
    }
    handler.next(err);
  }
}

/// Logs détaillés en mode debug uniquement
class _LogInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    debugPrint('┌─────────────────────────────────────────────');
    debugPrint('│ [API →] ${options.method} ${options.baseUrl}${options.path}');
    if (options.queryParameters.isNotEmpty) {
      debugPrint('│ Query:  ${options.queryParameters}');
    }
    if (options.data != null) {
      debugPrint('│ Body:   ${options.data}');
    }
    debugPrint('└─────────────────────────────────────────────');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    debugPrint('┌─────────────────────────────────────────────');
    debugPrint(
        '│ [API ✓] ${response.statusCode} ${response.requestOptions.method} ${response.requestOptions.path}');
    debugPrint('│ Body:   ${response.data}');
    debugPrint('└─────────────────────────────────────────────');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    debugPrint('┌─────────────────────────────────────────────');
    debugPrint(
        '│ [API ✗] ${err.response?.statusCode} ${err.requestOptions.method} ${err.requestOptions.path}');
    debugPrint('│ Type:   ${err.type}');
    debugPrint('│ Msg:    ${err.message}');
    if (err.response?.data != null) {
      debugPrint('│ Body:   ${err.response?.data}');
    }
    debugPrint('└─────────────────────────────────────────────');
    handler.next(err);
  }
}
