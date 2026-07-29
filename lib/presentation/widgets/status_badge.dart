import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final String? label;

  const StatusBadge({super.key, required this.status, this.label});

  @override
  Widget build(BuildContext context) {
    final config = _config(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: config.bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label ?? _defaultLabel(status),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: config.text,
        ),
      ),
    );
  }

  static _BadgeConfig _config(String status) {
    switch (status.toUpperCase()) {
      case 'ACTIF':
      case 'VALIDE':
      case 'REMBOURSE':
        return _BadgeConfig(
          bg: AppTheme.success.withValues(alpha: 0.12),
          text: AppTheme.success,
        );
      case 'INACTIF':
      case 'CLOTURE':
      case 'REJETE':
        return _BadgeConfig(
          bg: AppTheme.textSecondary.withValues(alpha: 0.12),
          text: AppTheme.textSecondary,
        );
      case 'BLOQUE':
      case 'SUSPENDU':
      case 'EN_RETARD':
      case 'CONTENTIEUX':
        return _BadgeConfig(
          bg: AppTheme.error.withValues(alpha: 0.12),
          text: AppTheme.error,
        );
      case 'EN_ATTENTE':
        return _BadgeConfig(
          bg: AppTheme.warning.withValues(alpha: 0.12),
          text: AppTheme.warning,
        );
      case 'EN_COURS':
        return _BadgeConfig(
          bg: AppTheme.primary.withValues(alpha: 0.12),
          text: AppTheme.primary,
        );
      default:
        return _BadgeConfig(
          bg: AppTheme.info.withValues(alpha: 0.12),
          text: AppTheme.info,
        );
    }
  }

  static String _defaultLabel(String status) {
    const labels = {
      'ACTIF': 'Actif',
      'INACTIF': 'Inactif',
      'SUSPENDU': 'Suspendu',
      'BLOQUE': 'Bloqué',
      'CLOTURE': 'Clôturé',
      'EN_ATTENTE': 'En attente',
      'EN_COURS': 'En cours',
      'VALIDE': 'Validé',
      'REJETE': 'Rejeté',
      'REMBOURSE': 'Remboursé',
      'EN_RETARD': 'En retard',
      'CONTENTIEUX': 'Contentieux',
    };
    return labels[status.toUpperCase()] ?? status;
  }
}

class _BadgeConfig {
  final Color bg;
  final Color text;
  const _BadgeConfig({required this.bg, required this.text});
}
