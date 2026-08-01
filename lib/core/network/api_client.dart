import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../constants/app_constants.dart';
import '../storage/secure_session_storage.dart';
import 'retry_interceptor.dart';

/// Callback appelÃƒÆ’Ã‚Â© quand le token est expirÃƒÆ’Ã‚Â© (401) pour dÃƒÆ’Ã‚Â©clencher le logout
typedef OnUnauthorized = void Function();

class ApiClient {
  late final Dio _dio;
  OnUnauthorized? onUnauthorized;

  ApiClient() {
    // URL du backend selon la plateforme, avec possibilitÃƒÆ’Ã‚Â© de surcharge
    // via `--dart-define=API_BASE_URL=...`.
    final baseUrl = AppConstants.baseUrl;
    if (kDebugMode) {
      debugPrint('[API BASE URL] $baseUrl');
    }

    // Sur Flutter Web, le "premier appel" peut subir un dÃƒÆ’Ã‚Â©lai important
    // (ex: cold start du backend). On tolÃƒÆ’Ã‚Â¨re donc un connectTimeout plus long.
    final connectTimeout = kIsWeb
        ? const Duration(seconds: 45)
        : const Duration(seconds: 15);
    final receiveTimeout = kIsWeb
        ? const Duration(seconds: 60)
        : const Duration(seconds: 30);

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

/// Injecte automatiquement le JWT dans chaque requÃƒÆ’Ã‚Âªte
/// et gÃƒÆ’Ã‚Â¨re la dÃƒÆ’Ã‚Â©connexion automatique sur 401
class _AuthInterceptor extends Interceptor {
  final ApiClient _client;
  final SecureSessionStorage sessionStorage = const SecureSessionStorage();

  _AuthInterceptor(this._client);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await sessionStorage.readToken();
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
    // Token expirÃƒÆ’Ã‚Â© ou invalide ÃƒÂ¢Ã¢â‚¬Â Ã¢â‚¬â„¢ dÃƒÆ’Ã‚Â©clencher le logout
    final statusCode = err.response?.statusCode;
    final path = err.requestOptions.path;
    final isAuthEndpoint = path.startsWith('/api/auth/');
    if (!isAuthEndpoint && (statusCode == 401 || statusCode == 403)) {
      _client.onUnauthorized?.call();
    }
    handler.next(err);
  }
}

/// Logs en mode debug uniquement
class _LogInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    debugPrint('[API ÃƒÂ¢Ã¢â‚¬â€œÃ‚Â¶] ${options.method} ${options.path}');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    debugPrint('[API ÃƒÂ¢Ã…â€œÃ¢â‚¬Å“] ${response.statusCode} ${response.requestOptions.path}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    debugPrint('[API ÃƒÂ¢Ã…â€œÃ¢â‚¬â€] ${err.response?.statusCode} ${err.message}');
    handler.next(err);
  }
}



