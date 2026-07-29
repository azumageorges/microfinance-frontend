import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../providers/providers.dart';
import '../../widgets/loading_overlay.dart';
import '../../widgets/app_app_bar.dart';

class TransactionsScreen extends ConsumerWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txAsync = ref.watch(transactionsProvider);
    final auth = ref.watch(authProvider);
    final canOperate = auth?.isAdmin == true || auth?.isCaissier == true;

    return Scaffold(
      appBar: AppAppBar(
        title: 'Transactions',
        showSearch: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(transactionsProvider),
          ),
        ],
      ),
      body: Column(
        children: [
          // Boutons d'opération
          if (canOperate)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  Expanded(
                    child: _OpButton(
                      label: 'Dépôt',
                      icon: Icons.add_circle_outline,
                      color: AppTheme.success,
                      onTap: () => context.push('/transactions/depot'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _OpButton(
                      label: 'Retrait',
                      icon: Icons.remove_circle_outline,
                      color: AppTheme.error,
                      onTap: () => context.push('/transactions/retrait'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _OpButton(
                      label: 'Transfert',
                      icon: Icons.swap_horiz,
                      color: AppTheme.primary,
                      onTap: () =>
                          context.push('/transactions/transfert'),
                    ),
                  ),
                ],
              ),
            ),

          Expanded(
            child: txAsync.when(
              loading: () => const LoadingOverlay(),
              error: (err, _) => ErrorView(
                message: err.toString(),
                onRetry: () => ref.invalidate(transactionsProvider),
              ),
              data: (txs) {
                if (txs.isEmpty) {
                  return const EmptyView(
                    message: 'Aucune transaction',
                    icon: Icons.swap_horiz,
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async =>
                      ref.invalidate(transactionsProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: txs.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: 8),
                    itemBuilder: (ctx, i) {
                      final tx = txs[i];
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: (tx.isCredit
                                          ? AppTheme.success
                                          : AppTheme.error)
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  tx.isCredit
                                      ? Icons.arrow_downward
                                      : Icons.arrow_upward,
                                  color: tx.isCredit
                                      ? AppTheme.success
                                      : AppTheme.error,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tx.typeLabel,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      tx.nomClient ?? tx.numeroCompte,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                    Text(
                                      tx.reference,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.textSecondary,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    Formatters.currency(tx.montant),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: tx.isCredit
                                          ? AppTheme.success
                                          : AppTheme.error,
                                    ),
                                  ),
                                  Text(
                                    Formatters.shortDate(
                                        tx.dateTransaction),
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

class _OpButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _OpButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
