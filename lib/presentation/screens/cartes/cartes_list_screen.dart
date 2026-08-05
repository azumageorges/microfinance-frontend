import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/client_model.dart';
import '../../../providers/providers.dart';
import '../../widgets/client_avatar.dart';
import '../../widgets/loading_overlay.dart';
import '../../widgets/app_app_bar.dart';

/// Écran liste de tous les clients avec leur statut de carte membre
/// Accessible : Admin + Gestionnaire
class CartesListScreen extends ConsumerStatefulWidget {
  const CartesListScreen({super.key});

  @override
  ConsumerState<CartesListScreen> createState() => _CartesListScreenState();
}

class _CartesListScreenState extends ConsumerState<CartesListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clientsAsync = ref.watch(clientsProvider);

    return Scaffold(
      appBar: AppAppBar(
        title: 'Cartes membres',
        showSearch: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(clientsProvider),
          ),
        ],
      ),
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

          // Onglets
          TabBar(
            controller: _tabCtrl,
            labelColor: AppTheme.primary,
            unselectedLabelColor: AppTheme.textSecondary,
            indicatorColor: AppTheme.primary,
            tabs: const [
              Tab(text: 'Avec carte'),
              Tab(text: 'Sans carte'),
            ],
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
                final avecCarte = clients
                    .where((c) =>
                        c.numeroMembre != null &&
                        (_search.isEmpty ||
                            c.fullName.toLowerCase().contains(_search) ||
                            (c.numeroMembre?.toLowerCase().contains(_search) ??
                                false)))
                    .toList();

                final sansCarte = clients
                    .where((c) =>
                        c.numeroMembre == null &&
                        c.statut == 'ACTIF' &&
                        (_search.isEmpty ||
                            c.fullName.toLowerCase().contains(_search) ||
                            c.numeroClient.toLowerCase().contains(_search)))
                    .toList();

                return TabBarView(
                  controller: _tabCtrl,
                  children: [
                    _ClientCarteList(
                      clients: avecCarte,
                      avecCarte: true,
                      emptyMessage: 'Aucun client avec une carte',
                    ),
                    _ClientCarteList(
                      clients: sansCarte,
                      avecCarte: false,
                      emptyMessage:
                          'Tous les clients actifs ont une carte',
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ClientCarteList extends StatelessWidget {
  final List<ClientModel> clients;
  final bool          avecCarte;
  final String        emptyMessage;

  const _ClientCarteList({
    required this.clients,
    required this.avecCarte,
    required this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (clients.isEmpty) {
      return EmptyView(
        message: emptyMessage,
        icon: avecCarte
            ? Icons.credit_card_outlined
            : Icons.person_search_outlined,
      );
    }

    // Consumer pour accéder à ref dans un StatelessWidget
    return Consumer(
      builder: (context, ref, _) => RefreshIndicator(
        onRefresh: () async => ref.invalidate(clientsProvider),
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          itemCount: clients.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (ctx, i) {
            final client = clients[i];
            return Card(
              child: InkWell(
                onTap: () => ctx.push(
                  '/clients/${client.id}/carte',
                  extra: client,
                ),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      // Avatar
                      ClientAvatar(
                        fullName: client.fullName,
                        cheminPhoto: client.cheminPhoto,
                        radius: 22,
                      ),
                      const SizedBox(width: 12),

                      // Infos
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              client.fullName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              client.numeroClient,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.textSecondary,
                                fontFamily: 'monospace',
                              ),
                            ),
                            if (avecCarte && client.numeroMembre != null) ...[
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  const Icon(Icons.credit_card,
                                      size: 12, color: AppTheme.primary),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      client.numeroMembre as String,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.primary,
                                        fontFamily: 'monospace',
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Badge / bouton
                      avecCarte
                          ? const _BadgeActive()
                          : _BoutonGenerer(
                              onTap: () => ctx.push(
                                '/clients/${client.id}/carte',
                                extra: client,
                              ),
                            ),

                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right,
                          size: 18, color: AppTheme.textSecondary),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─── Widgets internes ─────────────────────────────────────────────────────────

class _BadgeActive extends StatelessWidget {
  const _BadgeActive();

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.success.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline,
                size: 14, color: AppTheme.success),
            SizedBox(width: 4),
            Text(
              'Active',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.success),
            ),
          ],
        ),
      );
}

class _BoutonGenerer extends StatelessWidget {
  final VoidCallback onTap;
  const _BoutonGenerer({required this.onTap});

  @override
  Widget build(BuildContext context) => ElevatedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.add_card, size: 14),
        label: const Text('Générer'),
        style: ElevatedButton.styleFrom(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          textStyle: const TextStyle(fontSize: 12),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      );
}
