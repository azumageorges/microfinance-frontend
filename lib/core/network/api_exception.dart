import 'package:dio/dio.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

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

    return ApiException(msg, statusCode: e.response?.statusCode);
  }

  @override
  String toString() => message;
}
