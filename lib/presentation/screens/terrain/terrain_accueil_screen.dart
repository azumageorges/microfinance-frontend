import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../providers/providers.dart';
import '../../widgets/client_avatar.dart';
import '../../widgets/loading_overlay.dart';

/// Page d'accueil de l'agent terrain — remplace terrain/clients
/// comme point d'entrée principal
class TerrainAccueilScreen extends ConsumerWidget {
  const TerrainAccueilScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final clientsAsync = ref.watch(clientsProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(clientsProvider),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 80),
        children: [
          // Bonjour
          Text(
            'Bonjour, ${auth?.prenom ?? ''} 👋',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          Text(
            Formatters.date(DateTime.now()),
            style: const TextStyle(
                fontSize: 13, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 20),

          // Stats rapides
          clientsAsync.when(
            loading: () => const LoadingOverlay(),
            error: (_, _) => const SizedBox(),
            data: (clients) {
              final actifs =
                  clients.where((c) => c.statut == 'ACTIF').length;
              final sansCompte =
                  clients.where((c) => c.nombreComptes == 0).length;
              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _StatTile(
                          value: '${clients.length}',
                          label: 'Clients',
                          icon: Icons.people,
                          color: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatTile(
                          value: '$actifs',
                          label: 'Actifs',
                          icon: Icons.check_circle_outline,
                          color: AppTheme.success,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (sansCompte > 0)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color:
                                AppTheme.warning.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline,
                              color: AppTheme.warning, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '$sansCompte client(s) sans compte bancaire',
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // Actions rapides
          const Text(
            'Actions rapides',
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ActionTile(
                  icon: Icons.person_add_outlined,
                  label: 'Nouveau client',
                  color: AppTheme.primary,
                  onTap: () =>
                      context.push('/terrain/clients/nouveau'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionTile(
                  icon: Icons.search,
                  label: 'Rechercher',
                  color: AppTheme.accent,
                  onTap: () => context.go('/terrain/clients'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Derniers clients enregistrés
          const Text(
            'Clients récents',
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          clientsAsync.when(
            loading: () => const LoadingOverlay(),
            error: (e, _) => ErrorView(message: e.toString()),
            data: (clients) {
              // Trier par date de création décroissante (les plus récents en premier)
              final sorted = [...clients]..sort((a, b) {
                  if (a.createdAt == null && b.createdAt == null) return 0;
                  if (a.createdAt == null) return 1;
                  if (b.createdAt == null) return -1;
                  return b.createdAt!.compareTo(a.createdAt!);
                });
              final recents = sorted.take(5).toList();
              if (recents.isEmpty) {
                return const Center(
                  child: Text(
                    'Aucun client enregistré',
                    style:
                        TextStyle(color: AppTheme.textSecondary),
                  ),
                );
              }
              return Column(
                children: recents
                    .map((c) => Card(
                          margin:
                              const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            onTap: () => context.push(
                                '/terrain/clients/${c.id}'),
                            leading: ClientAvatar(
                              fullName: c.fullName,
                              cheminPhoto: c.cheminPhoto,
                            ),
                            title: Text(c.fullName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14)),
                            subtitle: Text(c.telephone,
                                style: const TextStyle(
                                    fontSize: 12)),
                            trailing: Text(
                              '${c.nombreComptes} cpt',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary),
                            ),
                          ),
                        ))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String value, label;
  final IconData icon;
  final Color color;

  const _StatTile({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: color)),
              Text(label,
                  style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(
            vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 13,
                    color: color,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
