import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/providers.dart';

/// Affiché quand un utilisateur web (Admin/Gestionnaire/Caissier)
/// essaie d'accéder depuis un appareil mobile, ou inversement.
class AccesRefuseScreen extends ConsumerWidget {
  final bool webUserOnMobile;

  const AccesRefuseScreen({
    super.key,
    required this.webUserOnMobile,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.devices_outlined,
                  size: 40,
                  color: AppTheme.warning,
                ),
              ),
              const SizedBox(height: 24),

              Text(
                webUserOnMobile
                    ? 'Interface non disponible'
                    : 'Accès restreint',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),

              Text(
                webUserOnMobile
                    ? 'Votre rôle (${_roleLabel(auth?.role ?? '')}) nécessite un accès depuis un navigateur web.\n\nConnectez-vous sur :\nlocalhost:3000'
                    : 'L\'interface mobile est réservée aux agents terrain.\n\nConnectez-vous avec un compte Agent terrain.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppTheme.textSecondary,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 40),

              OutlinedButton.icon(
                onPressed: () =>
                    ref.read(authProvider.notifier).logout(),
                icon: const Icon(Icons.logout),
                label: const Text('Se déconnecter'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _roleLabel(String role) {
    const labels = {
      'ADMIN': 'Administrateur',
      'GESTIONNAIRE_COMPTE': 'Gestionnaire',
      'CAISSIER': 'Caissier',
      'AGENT_TERRAIN': 'Agent terrain',
    };
    return labels[role] ?? role;
  }
}
