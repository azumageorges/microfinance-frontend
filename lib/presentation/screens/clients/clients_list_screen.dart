import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/providers.dart';
import '../../widgets/client_avatar.dart';
import '../../widgets/loading_overlay.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/app_app_bar.dart';

class ClientsListScreen extends ConsumerStatefulWidget {
  const ClientsListScreen({super.key});

  @override
  ConsumerState<ClientsListScreen> createState() => _ClientsListScreenState();
}

class _ClientsListScreenState extends ConsumerState<ClientsListScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final clientsAsync = ref.watch(clientsProvider);
    final auth = ref.watch(authProvider);

    final canCreate = auth?.isAdmin == true ||
        auth?.isAgentTerrain == true ||
        auth?.isGestionnaire == true;

    return Scaffold(
      appBar: AppAppBar(
        title: 'Clients',
        showSearch: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(clientsProvider),
          ),
        ],
      ),
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/clients/nouveau'),
              icon: const Icon(Icons.add),
              label: const Text('Nouveau client'),
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
            )
          : null,
      body: Column(
        children: [
          // Barre de recherche
          Padding(
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
              ),
              onChanged: (v) => setState(() => _search = v.toLowerCase()),
            ),
          ),

          // Liste
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
                            c.numeroClient.toLowerCase().contains(_search);
                      }).toList();
                if (filtered.isEmpty) {
                  return EmptyView(
                    message: _search.isEmpty
                        ? 'Aucun client enregistré'
                        : 'Aucun client trouvé pour "$_search"',
                    icon: Icons.person_search,
                    action: canCreate
                        ? ElevatedButton.icon(
                            onPressed: () => context.push('/clients/nouveau'),
                            icon: const Icon(Icons.add),
                            label: const Text('Créer un client'),
                          )
                        : null,
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(clientsProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (ctx, i) {
                      final client = filtered[i];
                      return Card(
                        child: InkWell(
                          onTap: () =>
                              context.push('/clients/${client.id}'),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                ClientAvatar(
                                  fullName: client.fullName,
                                  cheminPhoto: client.cheminPhoto,
                                  radius: 22,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        client.fullName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        client.numeroClient,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.textSecondary,
                                          fontFamily: 'monospace',
                                        ),
                                      ),
                                      if (client.telephone.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            const Icon(Icons.phone,
                                                size: 12,
                                                color:
                                                    AppTheme.textSecondary),
                                            const SizedBox(width: 4),
                                            Text(
                                              client.telephone,
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  color:
                                                      AppTheme.textSecondary),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    StatusBadge(status: client.statut),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${client.nombreComptes} compte(s)',
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: AppTheme.textSecondary),
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
      ),
    );
  }
}
