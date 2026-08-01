import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Journalisation centralisée de l'application.
///
/// Permet de tracer les erreurs (avec leur stack trace) même lorsqu'elles sont
/// volontairement absorbées, au lieu de les perdre silencieusement.
class AppLogger {
  AppLogger._();

  static final Logger _logger = Logger(
    level: kReleaseMode ? Level.warning : Level.debug,
    printer: PrettyPrinter(methodCount: 0, errorMethodCount: 8),
  );

  static void debug(String message) => _logger.d(message);

  static void warning(String message, [Object? error, StackTrace? stackTrace]) =>
      _logger.w(message, error: error, stackTrace: stackTrace);

  static void error(String message, Object error, [StackTrace? stackTrace]) =>
      _logger.e(message, error: error, stackTrace: stackTrace);
}
