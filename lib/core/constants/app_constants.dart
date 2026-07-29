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

    if (kIsWeb) {
      return 'http://localhost:8081';
    }

    // Android émulateur : 10.0.2.2 = localhost de la machine hôte.
    return 'http://10.0.2.2:8081';
  }

  static const String tokenKey = 'jwt_token';
  static const String userKey = 'user_data';

  // Pagination
  static const int pageSize = 20;
}
