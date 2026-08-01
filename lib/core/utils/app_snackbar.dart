import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Notifications utilisateur uniformes (succès / erreur / info).
extension AppSnackBar on BuildContext {
  void showSuccessSnackBar(String message) =>
      _show(message, AppTheme.success);

  void showErrorSnackBar(Object error) =>
      _show(error.toString(), AppTheme.error);

  void showInfoSnackBar(String message) => _show(message, AppTheme.info);

  void showSnackBarWithColor(String message, Color background) =>
      _show(message, background);

  void _show(String message, Color background) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: background),
    );
  }
}
