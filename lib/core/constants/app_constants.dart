import 'package:flutter/foundation.dart';

class AppConstants {
  static const String _apiBaseUrlOverride =
      String.fromEnvironment('API_BASE_URL');

  /// URL du backend.
  /// Peut être surchargée avec :
  /// `--dart-define=API_BASE_URL=http://host:port`
  static String get baseUrl {
    if (_apiBaseUrlOverride.isNotEmpty) {
      return _apiBaseUrlOverride;
    }

    // Sécurité : en release, on ne veut pas "tomber" sur une URL locale silencieusement.
    // Si `API_BASE_URL` n'est pas fourni au build, on force une erreur explicite
    // (sinon l'appli paraît "cassée" sur téléphone réel).
    if (kReleaseMode) {
      throw StateError(
        'API_BASE_URL manquant. Rebuild avec --dart-define=API_BASE_URL=https://...',
      );
    }

    if (kIsWeb) return 'http://localhost:8081';

    // Android émulateur : 10.0.2.2 = localhost de la machine hôte (debug uniquement).
    return 'http://10.0.2.2:8081';
  }

  static const String tokenKey = 'jwt_token';
  static const String userKey = 'user_data';

  // Pagination
  static const int pageSize = 20;
}
