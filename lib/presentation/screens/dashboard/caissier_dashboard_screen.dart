import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../providers/providers.dart';
import '../../widgets/loading_overlay.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/app_app_bar.dart';

/// Dashboard simplifié pour le Caissier
/// Montre les opérations du jour + accès rapide aux actions
class CaissierDashboardScreen extends ConsumerWidget {
  const CaissierDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txAsync = ref.watch(transactionsProvider);
    final creditsAsync = ref.watch(creditsProvider);
    final auth = ref.watch(authProvider);
    final isWide = MediaQuery.of(context).size.width >= 700;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppAppBar(
        titleWidget: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Caisse',
                style:
                    TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
            if (auth != null)
              Text(
                'Bonjour, ${auth.prenom}',
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.textSecondary),
              ),
          ],
        ),
        showSearch: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(transactionsProvider);
              ref.invalidate(creditsProvider);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(transactionsProvider);
          ref.invalidate(creditsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Actions rapides en haut
            _SectionTitle(title: 'Opérations'),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: isWide ? 4 : 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: isWide ? 2.0 : 1.6,
              children: [
                _ActionCard(
                  icon: Icons.arrow_downward,
                  label: 'Dépôt',
                  color: AppTheme.success,
                  onTap: () => context.push('/transactions/depot'),
                ),
                _ActionCard(
                  icon: Icons.arrow_upward,
                  label: 'Retrait',
                  color: AppTheme.error,
                  onTap: () => context.push('/transactions/retrait'),
                ),
                _ActionCard(
                  icon: Icons.swap_horiz,
                  label: 'Transfert',
                  color: AppTheme.primary,
                  onTap: () => context.push('/transactions/transfert'),
                ),
                _ActionCard(
                  icon: Icons.lock_open_outlined,
                  label: 'Déblocage crédit',
                  color: const Color(0xFF8B5CF6),
                  onTap: () => context.go('/credits'),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Résumé transactions du jour
            txAsync.when(
              loading: () => const LoadingOverlay(),
              error: (e, _) =>
                  ErrorView(message: e.toString()),
              data: (txs) {
                final today = DateTime.now();
                final txAujourdhui = txs.where((tx) {
                  final d = tx.dateTransaction;
                  return d.year == today.year &&
                      d.month == today.month &&
                      d.day == today.day;
                }).toList();

                final depots = txAujourdhui
                    .where((t) => t.typeTransaction == 'DEPOT')
                    .fold(0.0, (s, t) => s + t.montant);
                final retraits = txAujourdhui
                    .where((t) => t.typeTransaction == 'RETRAIT')
                    .fold(0.0, (s, t) => s + t.montant);
                final transferts = txAujourdhui
                    .where((t) => t.typeTransaction == 'TRANSFERT')
                    .fold(0.0, (s, t) => s + t.montant);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionTitle(
                        title:
                            "Résumé du ${Formatters.date(today)}"),
                    const SizedBox(height: 10),
                    GridView.count(
                      crossAxisCount: isWide ? 3 : 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: isWide ? 2.2 : 1.6,
                      children: [
                        StatCard(
                          label: 'Dépôts',
                          value: Formatters.currency(depots),
                          icon: Icons.arrow_downward,
                          color: AppTheme.success,
                          subtitle: '${txAujourdhui.where((t) => t.typeTransaction == 'DEPOT').length} opération(s)',
                        ),
                        StatCard(
                          label: 'Retraits',
                          value: Formatters.currency(retraits),
                          icon: Icons.arrow_upward,
                          color: AppTheme.error,
                          subtitle: '${txAujourdhui.where((t) => t.typeTransaction == 'RETRAIT').length} opération(s)',
                        ),
                        StatCard(
                          label: 'Transferts',
                          value: Formatters.currency(transferts),
                          icon: Icons.swap_horiz,
                          color: AppTheme.primary,
                          subtitle: '${txAujourdhui.where((t) => t.typeTransaction == 'TRANSFERT').length} opération(s)',
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Transactions récentes du jour
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const _SectionTitle(
                            title: "Opérations d'aujourd'hui"),
                        TextButton(
                          onPressed: () => context.go('/transactions'),
                          child: const Text('Tout voir'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    txAujourdhui.isEmpty
                        ? Card(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Center(
                                child: Column(
                                  children: [
                                    Icon(Icons.inbox_outlined,
                                        size: 36,
                                        color: AppTheme.textSecondary
                                            .withValues(alpha: 0.4)),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Aucune opération aujourd\'hui',
                                      style: TextStyle(
                                          color: AppTheme.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                        : Card(
                            child: Column(
                              children: txAujourdhui
                                  .take(10)
                                  .map((tx) => _TxTile(tx: tx))
                                  .toList(),
                            ),
                          ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),

            // Crédits à débloquer ou à rembourser
            creditsAsync.when(
              loading: () => const SizedBox(),
              error: (_, _) => const SizedBox(),
              data: (credits) {
                final aDebloquer = credits
                    .where((c) => c.statut == 'VALIDE')
                    .toList();
                final enRetard = credits
                    .where((c) => c.statut == 'EN_RETARD')
                    .toList();

                if (aDebloquer.isEmpty && enRetard.isEmpty) {
                  return const SizedBox();
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionTitle(title: 'Crédits — Actions requises'),
                    const SizedBox(height: 10),
                    if (aDebloquer.isNotEmpty)
                      _AlertBanner(
                        icon: Icons.lock_open_outlined,
                        color: const Color(0xFF8B5CF6),
                        message:
                            '${aDebloquer.length} crédit(s) validé(s) en attente de déblocage',
                        onTap: () => context.go('/credits'),
                      ),
                    if (enRetard.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _AlertBanner(
                        icon: Icons.warning_amber_outlined,
                        color: AppTheme.error,
                        message:
                            '${enRetard.length} crédit(s) en retard de remboursement',
                        onTap: () => context.go('/credits'),
                      ),
                    ],
                  ],
                );
              },
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// ─── Widgets internes ─────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppTheme.textPrimary,
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TxTile extends StatelessWidget {
  final dynamic tx;
  const _TxTile({required this.tx});

  @override
  Widget build(BuildContext context) {
    final isCredit = tx.isCredit;
    return ListTile(
      dense: true,
      leading: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: (isCredit ? AppTheme.success : AppTheme.error)
              .withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          isCredit ? Icons.arrow_downward : Icons.arrow_upward,
          color: isCredit ? AppTheme.success : AppTheme.error,
          size: 16,
        ),
      ),
      title: Text(
        tx.typeLabel,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        tx.nomClient ?? tx.numeroCompte,
        style: const TextStyle(fontSize: 11),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            Formatters.currency(tx.montant),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isCredit ? AppTheme.success : AppTheme.error,
            ),
          ),
          Text(
            Formatters.timeAgo(tx.dateTransaction),
            style: const TextStyle(
                fontSize: 10, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _AlertBanner extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String message;
  final VoidCallback onTap;

  const _AlertBanner({
    required this.icon,
    required this.color,
    required this.message,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w600),
              ),
            ),
            Icon(Icons.chevron_right, color: color, size: 18),
          ],
        ),
      ),
    );
  }
}
