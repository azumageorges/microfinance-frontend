import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/providers.dart';
import '../../widgets/client_avatar.dart';
import '../../widgets/loading_overlay.dart';
import '../../widgets/status_badge.dart';

/// Écran liste des clients — interface Agent Terrain (mobile)
class TerrainClientsScreen extends ConsumerStatefulWidget {
  const TerrainClientsScreen({super.key});

  @override
  ConsumerState<TerrainClientsScreen> createState() =>
      _TerrainClientsScreenState();
}

class _TerrainClientsScreenState
    extends ConsumerState<TerrainClientsScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final clientsAsync = ref.watch(clientsProvider);

    return Column(
      children: [
        // Barre de recherche
        Container(
          color: AppTheme.surface,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Rechercher un client...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _search.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _search = ''),
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (v) => setState(() => _search = v.toLowerCase()),
          ),
        ),

        // Stats rapides
        clientsAsync.when(
          loading: () => const SizedBox(),
          error: (_, _) => const SizedBox(),
          data: (clients) {
            final actifs =
                clients.where((c) => c.statut == 'ACTIF').length;
            return Container(
              color: AppTheme.surface,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  _QuickStat(
                    value: '${clients.length}',
                    label: 'Total',
                    color: AppTheme.primary,
                  ),
                  const SizedBox(width: 12),
                  _QuickStat(
                    value: '$actifs',
                    label: 'Actifs',
                    color: AppTheme.success,
                  ),
                  const SizedBox(width: 12),
                  _QuickStat(
                    value: '${clients.length - actifs}',
                    label: 'Autres',
                    color: AppTheme.textSecondary,
                  ),
                ],
              ),
            );
          },
        ),

        Expanded(
          child: clientsAsync.when(
            loading: () => const LoadingOverlay(),
            error: (err, _) => ErrorView(
              message: err.toString(),
              onRetry: () => ref.invalidate(clientsProvider),
            ),
            data: (clients) {
              final filtered = _search.isEmpty
                  ? clients
                  : clients.where((c) {
                      return c.fullName
                              .toLowerCase()
                              .contains(_search) ||
                          c.telephone.contains(_search) ||
                          c.numeroClient
                              .toLowerCase()
                              .contains(_search);
                    }).toList();

              if (filtered.isEmpty) {
                return EmptyView(
                  message: _search.isEmpty
                      ? 'Aucun client\nenregistré'
                      : 'Aucun résultat pour\n"$_search"',
                  icon: Icons.person_search,
                  action: ElevatedButton.icon(
                    onPressed: () =>
                        context.push('/terrain/clients/nouveau'),
                    icon: const Icon(Icons.add),
                    label: const Text('Nouveau client'),
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async =>
                    ref.invalidate(clientsProvider),
                child: ListView.separated(
                  padding:
                      const EdgeInsets.fromLTRB(16, 8, 16, 80),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: 8),
                  itemBuilder: (ctx, i) {
                    final c = filtered[i];
                    return Card(
                      child: InkWell(
                        onTap: () =>
                            context.push('/terrain/clients/${c.id}'),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              ClientAvatar(
                                fullName: c.fullName,
                                cheminPhoto: c.cheminPhoto,
                                radius: 24,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      c.fullName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Row(
                                      children: [
                                        const Icon(Icons.badge_outlined,
                                            size: 12,
                                            color:
                                                AppTheme.textSecondary),
                                        const SizedBox(width: 4),
                                        Text(
                                          c.numeroClient,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color:
                                                AppTheme.textSecondary,
                                            fontFamily: 'monospace',
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        const Icon(Icons.phone,
                                            size: 12,
                                            color:
                                                AppTheme.textSecondary),
                                        const SizedBox(width: 4),
                                        Text(
                                          c.telephone,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color:
                                                AppTheme.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.end,
                                children: [
                                  StatusBadge(status: c.statut),
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                          Icons
                                              .account_balance_wallet_outlined,
                                          size: 12,
                                          color:
                                              AppTheme.textSecondary),
                                      const SizedBox(width: 3),
                                      Text(
                                        '${c.nombreComptes}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _QuickStat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _QuickStat({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: color),
          ),
        ],
      ),
    );
  }
}
