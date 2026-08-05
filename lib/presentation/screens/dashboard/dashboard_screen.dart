import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/transaction_model.dart';
import '../../../providers/providers.dart';
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
      backgroundColor: Colors.grey[50],
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
          final canCreate = auth?.canDoTransactions == true;
          final canValidate = auth?.isGestionnaire == true;
          
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(dashboardProvider),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                // Actions rapides
                if (canCreate || canValidate) ...[
                  _QuickActions(
                    canCreate: canCreate,
                    canValidate: canValidate,
                    creditsEnAttente: dashboard.creditsEnAttente,
                  ),
                  const SizedBox(height: 20),
                ],

                // Grille de stats principale
                _SectionTitle(title: 'Vue générale'),
                const SizedBox(height: 12),
                _StatsGrid(isWide: isWide, children: [
                  _ModernStatCard(
                    label: 'Clients',
                    value: '${dashboard.totalClients}',
                    icon: Icons.people,
                    color: AppTheme.primary,
                    subtitle: '${dashboard.clientsActifs} actifs',
                    onTap: () => context.go('/clients'),
                  ),
                  _ModernStatCard(
                    label: 'Comptes',
                    value: '${dashboard.totalComptes}',
                    icon: Icons.account_balance_wallet,
                    color: AppTheme.accent,
                    onTap: () => context.go('/comptes'),
                  ),
                  _ModernStatCard(
                    label: 'Épargne totale',
                    value: Formatters.currency(dashboard.totalEpargne),
                    icon: Icons.savings,
                    color: AppTheme.success,
                  ),
                  _ModernStatCard(
                    label: 'DAT total',
                    value: Formatters.currency(dashboard.totalDat),
                    icon: Icons.lock_clock,
                    color: const Color(0xFF8B5CF6),
                  ),
                ]),

                const SizedBox(height: 24),
                _SectionTitle(title: 'Crédits'),
                const SizedBox(height: 12),
                _StatsGrid(isWide: isWide, children: [
                  _ModernStatCard(
                    label: 'En cours',
                    value: '${dashboard.creditsEnCours}',
                    icon: Icons.credit_score,
                    color: AppTheme.primary,
                    onTap: () => context.go('/credits'),
                  ),
                  _ModernStatCard(
                    label: 'En attente',
                    value: '${dashboard.creditsEnAttente}',
                    icon: Icons.pending_actions,
                    color: AppTheme.warning,
                    onTap: () => context.go('/credits'),
                    showBadge: dashboard.creditsEnAttente > 0,
                  ),
                  _ModernStatCard(
                    label: 'Montant débloqué',
                    value: Formatters.currency(dashboard.totalCreditsAccordes),
                    icon: Icons.attach_money,
                    color: AppTheme.success,
                  ),
                  _ModernStatCard(
                    label: 'Encours',
                    value: Formatters.currency(dashboard.totalEncours),
                    icon: Icons.trending_up,
                    color: AppTheme.error,
                  ),
                ]),

                const SizedBox(height: 24),
                _SectionTitle(title: "Aujourd'hui"),
                const SizedBox(height: 12),
                _StatsGrid(isWide: isWide, crossAxisCount: 2, children: [
                  _ModernStatCard(
                    label: 'Dépôts',
                    value: Formatters.currency(dashboard.totalDepotsJour),
                    icon: Icons.arrow_downward,
                    color: AppTheme.success,
                  ),
                  _ModernStatCard(
                    label: 'Retraits',
                    value: Formatters.currency(dashboard.totalRetraitsJour),
                    icon: Icons.arrow_upward,
                    color: AppTheme.error,
                  ),
                ]),

                // Graphiques
                const SizedBox(height: 24),
                if (isWide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 1,
                        child: _ChartCard(
                          title: 'Activité',
                          child: ActiviteChart(dashboard: dashboard),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 1,
                        child: _ChartCard(
                          title: 'Répartition',
                          child: RepartitionChart(dashboard: dashboard),
                        ),
                      ),
                    ],
                  )
                else ...[
                  _ChartCard(
                    title: 'Activité',
                    child: ActiviteChart(dashboard: dashboard),
                  ),
                  const SizedBox(height: 12),
                  _ChartCard(
                    title: 'Répartition',
                    child: RepartitionChart(dashboard: dashboard),
                  ),
                ],

                // Transactions récentes
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const _SectionTitle(title: 'Transactions récentes'),
                    TextButton.icon(
                      onPressed: () => context.go('/transactions'),
                      icon: const Icon(Icons.arrow_forward, size: 16),
                      label: const Text('Voir tout'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _TransactionsCard(transactions: dashboard.transactionsRecentes),
                const SizedBox(height: 24),
              ],
            ),
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
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppTheme.textPrimary,
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final bool isWide;
  final List<Widget> children;
  final int? crossAxisCount;

  const _StatsGrid({required this.isWide, required this.children, this.crossAxisCount});

  @override
  Widget build(BuildContext context) {
    final effectiveCrossAxisCount = crossAxisCount ?? (isWide ? 4 : 2);
    return GridView.count(
      crossAxisCount: effectiveCrossAxisCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: isWide ? 1.8 : 1.5,
      children: children,
    );
  }
}

class _QuickActions extends StatelessWidget {
  final bool canCreate;
  final bool canValidate;
  final int creditsEnAttente;

  const _QuickActions({
    required this.canCreate,
    required this.canValidate,
    required this.creditsEnAttente,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Actions rapides',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                if (canCreate) ...[
                  _ActionButton(
                    icon: Icons.add_circle_outline,
                    label: 'Dépôt',
                    color: AppTheme.success,
                    onTap: () => context.push('/transactions/depot'),
                  ),
                  _ActionButton(
                    icon: Icons.remove_circle_outline,
                    label: 'Retrait',
                    color: AppTheme.error,
                    onTap: () => context.push('/transactions/retrait'),
                  ),
                  _ActionButton(
                    icon: Icons.swap_horiz,
                    label: 'Transfert',
                    color: AppTheme.primary,
                    onTap: () => context.push('/transactions/transfert'),
                  ),
                  _ActionButton(
                    icon: Icons.credit_card,
                    label: 'Crédit',
                    color: AppTheme.accent,
                    onTap: () => context.push('/credits'),
                  ),
                ],
                if (canValidate && creditsEnAttente > 0)
                  _ActionButton(
                    icon: Icons.pending_actions,
                    label: 'Crédits en attente',
                    color: AppTheme.warning,
                    badge: creditsEnAttente,
                    onTap: () => context.push('/credits'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final int? badge;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, color: color, size: 20),
                if (badge != null)
                  Positioned(
                    right: -8,
                    top: -8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppTheme.error,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$badge',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModernStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool showBadge;

  const _ModernStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
    this.onTap,
    this.showBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(icon, color: color, size: 20),
                      ),
                      const Spacer(),
                      if (showBadge)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.error,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'Nouveau',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 1),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppTheme.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _ChartCard({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 240,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: child,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TransactionsCard extends StatelessWidget {
  final List<TransactionModel> transactions;

  const _TransactionsCard({required this.transactions});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: transactions.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.receipt_long,
                      size: 48,
                      color: AppTheme.textSecondary.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Aucune transaction',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: transactions
                  .take(8)
                  .map<Widget>((tx) => _ModernTransactionTile(tx: tx))
                  .toList(),
            ),
    );
  }
}

class _ModernTransactionTile extends StatelessWidget {
  final TransactionModel tx;
  const _ModernTransactionTile({required this.tx});

  @override
  Widget build(BuildContext context) {
    final isCredit = tx.isCredit;
    final color = !tx.isExecuted && tx.isSensitive
        ? AppTheme.warning
        : (isCredit ? AppTheme.success : AppTheme.error);
    final icon = tx.typeTransaction == 'TRANSFERT'
        ? Icons.swap_horiz
        : (isCredit ? Icons.arrow_downward : Icons.arrow_upward);
    
    return InkWell(
      onTap: () => context.push('/transactions/${tx.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tx.typeLabel,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tx.nomClient ?? tx.numeroCompte,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  Formatters.currency(tx.montant),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  Formatters.timeAgo(tx.dateTransaction),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
