import 'package:dio/dio.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  factory ApiException.fromDioError(DioException e) {
    final data = e.response?.data;
    String msg = 'Une erreur est survenue';

    if (data is Map) {
      // Cas 1 : erreur de validation Spring — les détails sont dans data['data'] (Map<champ, message>)
      final validationData = data['data'];
      if (validationData is Map && validationData.isNotEmpty) {
        // Concatène tous les messages de validation en une seule chaîne lisible
        msg = validationData.values
            .map((v) => v.toString())
            .join('\n');
      } else if (data['message'] != null) {
        // Cas 2 : erreur métier avec message direct
        msg = data['message'].toString();
      }
    }

    if (msg == 'Une erreur est survenue') {
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
          if (code == 401) {
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
