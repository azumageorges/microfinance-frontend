import 'package:dio/dio.dart';

import '../utils/app_logger.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  /// Erreur d'origine (DioException, TypeError de parsing, ...) conservée pour
  /// le diagnostic : le message affiché à l'utilisateur reste lisible.
  final Object? cause;
  final StackTrace? stackTrace;

  const ApiException(
    this.message, {
    this.statusCode,
    this.cause,
    this.stackTrace,
  });

  factory ApiException.fromDioError(DioException e) {
    final data = e.response?.data;
    String msg = 'Une erreur est survenue';

    if (data is Map && data['message'] != null) {
      msg = data['message'].toString();
    } else {
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          msg = 'Délai de connexion dépassé';
          break;
        case DioExceptionType.connectionError:
          msg = 'Impossible de se connecter au serveur';
          break;
        case DioExceptionType.cancel:
          msg = 'Requête annulée';
          break;
        case DioExceptionType.badResponse:
          final code = e.response?.statusCode;
          // Essaie d'abord d'extraire le message du body
          if (data is Map && data['message'] != null) {
            msg = data['message'].toString();
          } else if (code == 401) {
            msg = 'Email ou mot de passe incorrect';
          } else if (code == 403) {
            msg = 'Accès non autorisé';
          } else if (code == 404) {
            msg = 'Ressource introuvable';
          } else if (code == 500) {
            msg = 'Erreur interne du serveur';
          }
          break;
        default:
          msg = e.message ?? msg;
      }
    }

    return ApiException(
      msg,
      statusCode: e.response?.statusCode,
      cause: e,
      stackTrace: e.stackTrace,
    );
  }

  /// Normalise n'importe quelle erreur en [ApiException].
  ///
  /// Les erreurs non réseau (réponse mal formée, cast invalide, ...) étaient
  /// jusqu'ici propagées telles quelles jusqu'à l'UI, qui affichait le
  /// `toString()` brut de l'exception Dart. Elles sont désormais tracées puis
  /// converties en message lisible.
  factory ApiException.from(Object error, StackTrace stackTrace) {
    if (error is ApiException) return error;
    if (error is DioException) return ApiException.fromDioError(error);

    AppLogger.error('Erreur inattendue lors d\'un appel API', error, stackTrace);
    return ApiException(
      'Réponse inattendue du serveur',
      cause: error,
      stackTrace: stackTrace,
    );
  }

  @override
  String toString() => message;
}
