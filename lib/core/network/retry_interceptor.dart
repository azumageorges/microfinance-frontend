import 'dart:async';
import 'package:dio/dio.dart';

/// Retry simple (sans dépendance externe) pour les erreurs réseau/transitoires.
///
/// Objectif principal : absorber un cold start du backend (Render) ou des timeouts ponctuels.
///
/// - Re-tente uniquement :
///   - les requêtes GET
///   - ou les requêtes explicitement marquées retryable via `extra['retryable']=true`
/// - Re-tente uniquement sur : timeouts / erreurs de connexion
class RetryInterceptor extends Interceptor {
  final Dio _dio;
  final int maxAttempts;
  final Duration baseDelay;

  RetryInterceptor(
    this._dio, {
    this.maxAttempts = 3,
    this.baseDelay = const Duration(seconds: 1),
  });

  bool _isRetryableRequest(RequestOptions options) {
    final method = options.method.toUpperCase();
    return method == 'GET' || options.extra['retryable'] == true;
  }

  bool _isTransientError(DioException e) {
    return e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError;
  }

  Duration _backoff(int attempt) {
    // 1s, 2s, 4s...
    final seconds = baseDelay.inSeconds * (1 << (attempt - 1));
    return Duration(seconds: seconds.clamp(1, 10));
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final options = err.requestOptions;
    final attempt = (options.extra['retry_attempt'] as int?) ?? 0;

    if (!_isRetryableRequest(options) ||
        !_isTransientError(err) ||
        attempt >= maxAttempts - 1) {
      return handler.next(err);
    }

    final nextAttempt = attempt + 1;
    options.extra['retry_attempt'] = nextAttempt;

    await Future.delayed(_backoff(nextAttempt));

    try {
      final response = await _dio.fetch(options);
      return handler.resolve(response);
    } on DioException catch (e) {
      return handler.next(e);
    } catch (e) {
      return handler.next(
        DioException(
          requestOptions: options,
          error: e,
          type: DioExceptionType.unknown,
        ),
      );
    }
  }
}

