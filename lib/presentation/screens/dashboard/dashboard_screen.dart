import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../providers/providers.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/loading_overlay.dart';
import '../../widgets/app_app_bar.dart';
import '../../widgets/activite_chart.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashAsync = ref.watch(dashboardProvider);
    final auth = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppAppBar(
        titleWidget: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tableau de bord',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
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
            onPressed: () => ref.invalidate(dashboardProvider),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: dashAsync.when(
        loading: () => const LoadingOverlay(),
        error: (err, _) => ErrorView(
          message: err.toString(),
          onRetry: () => ref.invalidate(dashboardProvider),
        ),
        data: (dashboard) {
          final isWide = MediaQuery.of(context).size.width >= 700;
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(dashboardProvider),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Grille de stats
                _SectionTitle(title: 'Vue générale'),
                const SizedBox(height: 10),
                _StatsGrid(isWide: isWide, children: [
                  StatCard(
                    label: 'Clients',
                    value: '${dashboard.totalClients}',
                    icon: Icons.people,
                    color: AppTheme.primary,
                    subtitle: '${dashboard.clientsActifs} actifs',
                    onTap: () => context.go('/clients'),
                  ),
                  StatCard(
                    label: 'Comptes',
                    value: '${dashboard.totalComptes}',
                    icon: Icons.account_balance_wallet,
                    color: AppTheme.accent,
                    onTap: () => context.go('/comptes'),
                  ),
                  StatCard(
                    label: 'Épargne totale',
                    value: Formatters.currency(dashboard.totalEpargne),
                    icon: Icons.savings,
                    color: AppTheme.success,
                  ),
                  StatCard(
                    label: 'DAT total',
                    value: Formatters.currency(dashboard.totalDat),
                    icon: Icons.lock_clock,
                    color: const Color(0xFF8B5CF6),
                  ),
                ]),

                const SizedBox(height: 20),
                _SectionTitle(title: 'Crédits'),
                const SizedBox(height: 10),
                _StatsGrid(isWide: isWide, children: [
                  StatCard(
                    label: 'En cours',
                    value: '${dashboard.creditsEnCours}',
                    icon: Icons.credit_score,
                    color: AppTheme.primary,
                    onTap: () => context.go('/credits'),
                  ),
                  StatCard(
                    label: 'En attente',
                    value: '${dashboard.creditsEnAttente}',
                    icon: Icons.pending_actions,
                    color: AppTheme.warning,
                    onTap: () => context.go('/credits'),
                  ),
                  StatCard(
                    label: 'Montant débloqué',
                    value: Formatters.currency(dashboard.totalCreditsAccordes),
                    icon: Icons.attach_money,
                    color: AppTheme.success,
                  ),
                  StatCard(
                    label: 'Encours',
                    value: Formatters.currency(dashboard.totalEncours),
                    icon: Icons.trending_up,
                    color: AppTheme.error,
                  ),
                ]),

                const SizedBox(height: 20),
                _SectionTitle(title: "Aujourd'hui"),
                const SizedBox(height: 10),
                _StatsGrid(isWide: isWide, children: [
                  StatCard(
                    label: 'Dépôts',
                    value: Formatters.currency(dashboard.totalDepotsJour),
                    icon: Icons.arrow_downward,
                    color: AppTheme.success,
                  ),
                  StatCard(
                    label: 'Retraits',
                    value: Formatters.currency(dashboard.totalRetraitsJour),
                    icon: Icons.arrow_upward,
                    color: AppTheme.error,
                  ),
                ]),

                // Transactions récentes
                const SizedBox(height: 20),

                // Graphiques
                if (isWide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: ActiviteChart(dashboard: dashboard)),
                      const SizedBox(width: 12),
                      Expanded(child: RepartitionChart(dashboard: dashboard)),
                    ],
                  )
                else ...[
                  ActiviteChart(dashboard: dashboard),
                  const SizedBox(height: 12),
                  RepartitionChart(dashboard: dashboard),
                ],

                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const _SectionTitle(title: 'Transactions récentes'),
                    TextButton(
                      onPressed: () => context.go('/transactions'),
                      child: const Text('Voir tout'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Card(
                  child: dashboard.transactionsRecentes.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(
                            child: Text('Aucune transaction',
                                style: TextStyle(
                                    color: AppTheme.textSecondary)),
                          ),
                        )
                      : Column(
                          children: dashboard.transactionsRecentes
                              .take(8)
                              .map((tx) => _TransactionTile(tx: tx))
                              .toList(),
                        ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}

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

class _StatsGrid extends StatelessWidget {
  final bool isWide;
  final List<Widget> children;

  const _StatsGrid({required this.isWide, required this.children});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: isWide ? 4 : 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: isWide ? 1.8 : 1.5,
      children: children,
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final dynamic tx;
  const _TransactionTile({required this.tx});

  @override
  Widget build(BuildContext context) {
    final isCredit = tx.isCredit;
    return ListTile(
      dense: true,
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: (isCredit ? AppTheme.success : AppTheme.error)
              .withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          isCredit ? Icons.arrow_downward : Icons.arrow_upward,
          color: isCredit ? AppTheme.success : AppTheme.error,
          size: 18,
        ),
      ),
      title: Text(
        tx.typeLabel,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        tx.nomClient ?? tx.numeroCompte,
        style: const TextStyle(fontSize: 12),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            Formatters.currency(tx.montant),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isCredit ? AppTheme.success : AppTheme.error,
            ),
          ),
          Text(
            Formatters.timeAgo(tx.dateTransaction),
            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}
