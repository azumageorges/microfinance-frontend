import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: AppTheme.primary),
    );
  }
}

class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorView({super.key, required this.message, this.onRetry});

  /// Détermine l'icône et le titre selon le contenu du message
  _ErrorMeta _meta() {
    final m = message.toLowerCase();
    if (m.contains('connexion') || m.contains('réseau') ||
        m.contains('serveur') || m.contains('timeout') ||
        m.contains('connect')) {
      return _ErrorMeta(
        icon: Icons.wifi_off_rounded,
        title: 'Problème de connexion',
        color: AppTheme.warning,
      );
    }
    if (m.contains('autorisé') || m.contains('accès') ||
        m.contains('permission') || m.contains('403')) {
      return _ErrorMeta(
        icon: Icons.lock_outline,
        title: 'Accès refusé',
        color: AppTheme.error,
      );
    }
    if (m.contains('introuvable') || m.contains('404') ||
        m.contains('non trouvé')) {
      return _ErrorMeta(
        icon: Icons.search_off_rounded,
        title: 'Données introuvables',
        color: AppTheme.textSecondary,
      );
    }
    return _ErrorMeta(
      icon: Icons.error_outline,
      title: 'Une erreur est survenue',
      color: AppTheme.error,
    );
  }

  @override
  Widget build(BuildContext context) {
    final meta = _meta();
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: meta.color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(meta.icon, size: 36, color: meta.color),
            ),
            const SizedBox(height: 16),
            Text(
              meta.title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: meta.color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: meta.color,
                  side: BorderSide(color: meta.color.withValues(alpha: 0.5)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ErrorMeta {
  final IconData icon;
  final String title;
  final Color color;
  const _ErrorMeta({required this.icon, required this.title, required this.color});
}

class EmptyView extends StatelessWidget {
  final String message;
  final IconData icon;
  final Widget? action;

  const EmptyView({
    super.key,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: AppTheme.textSecondary.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 15),
            ),
            if (action != null) ...[
              const SizedBox(height: 16),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Widget d'erreur inline pour les formulaires (remplace le Container rouge répété partout)
class InlineError extends StatelessWidget {
  final String message;

  const InlineError({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    // Sépare les lignes (messages de validation multiples)
    final lines = message.split('\n').where((l) => l.trim().isNotEmpty).toList();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(Icons.error_outline, color: AppTheme.error, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: lines.length == 1
                ? Text(lines.first,
                    style: const TextStyle(color: AppTheme.error, fontSize: 13))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: lines
                        .map((l) => Padding(
                              padding: const EdgeInsets.only(bottom: 2),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('• ',
                                      style: TextStyle(
                                          color: AppTheme.error,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600)),
                                  Expanded(
                                    child: Text(l,
                                        style: const TextStyle(
                                            color: AppTheme.error, fontSize: 13)),
                                  ),
                                ],
                              ),
                            ))
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }
}

/// Helper statique pour afficher des SnackBars cohérents dans toute l'app
class AppSnackBar {
  AppSnackBar._();

  static void success(BuildContext context, String message) {
    _show(context, message, AppTheme.success, Icons.check_circle_outline);
  }

  static void error(BuildContext context, String message) {
    _show(context, message, AppTheme.error, Icons.error_outline,
        duration: const Duration(seconds: 5));
  }

  static void warning(BuildContext context, String message) {
    _show(context, message, AppTheme.warning, Icons.warning_amber_outlined,
        duration: const Duration(seconds: 4));
  }

  static void info(BuildContext context, String message) {
    _show(context, message, AppTheme.primary, Icons.info_outline);
  }

  static void _show(
    BuildContext context,
    String message,
    Color color,
    IconData icon, {
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: color,
          duration: duration,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        ),
      );
  }
}
