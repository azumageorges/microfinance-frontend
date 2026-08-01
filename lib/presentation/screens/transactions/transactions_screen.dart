import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/transaction_model.dart';
import '../../../providers/providers.dart';
import '../../widgets/loading_overlay.dart';
import '../../widgets/app_app_bar.dart';
import '../../widgets/status_badge.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../core/utils/app_dialogs.dart';

class TransactionsScreen extends ConsumerWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txAsync = ref.watch(transactionsProvider);
    final auth = ref.watch(authProvider);
    final canCreate = auth?.isCaissier == true;
    final canValidate = auth?.isGestionnaire == true;
    final canExecute = auth?.isCaissier == true;

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
          if (canCreate)
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
                          child: Column(
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: _amountColor(tx)
                                          .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      _iconFor(tx),
                                      color: _amountColor(tx),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                tx.typeLabel,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                            StatusBadge(
                                              status: tx.statut,
                                              label: tx.statutLabel,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
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
                                        const SizedBox(height: 6),
                                        Text(
                                          _detailLine(tx),
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppTheme.textSecondary,
                                          ),
                                        ),
                                        if (tx.motif != null &&
                                            tx.motif!.trim().isNotEmpty)
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(top: 4),
                                            child: Text(
                                              'Motif : ${tx.motif}',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color:
                                                    AppTheme.textSecondary,
                                              ),
                                            ),
                                          ),
                                        if (tx.motifRejet != null &&
                                            tx.motifRejet!.trim().isNotEmpty)
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(top: 4),
                                            child: Text(
                                              'Rejet : ${tx.motifRejet}',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: AppTheme.error,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        Formatters.currency(tx.montant),
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: _amountColor(tx),
                                        ),
                                      ),
                                      Text(
                                        Formatters.shortDate(
                                            tx.dateExecution ??
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
                              if (tx.isPendingValidation && canValidate) ...[
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () =>
                                            _validerOperation(
                                          context,
                                          ref,
                                          tx,
                                          false,
                                        ),
                                        icon: const Icon(
                                          Icons.close,
                                          color: AppTheme.error,
                                        ),
                                        label: const Text(
                                          'Rejeter',
                                          style: TextStyle(
                                            color: AppTheme.error,
                                          ),
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          side: const BorderSide(
                                            color: AppTheme.error,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () =>
                                            _validerOperation(
                                          context,
                                          ref,
                                          tx,
                                          true,
                                        ),
                                        icon: const Icon(Icons.check),
                                        label: const Text('Valider'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              AppTheme.success,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              if (tx.isValidated && canExecute) ...[
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () =>
                                        _executerOperation(context, ref, tx),
                                    icon: const Icon(Icons.payments_outlined),
                                    label: Text(
                                      tx.typeTransaction == 'RETRAIT'
                                          ? 'Remettre les fonds'
                                          : 'Exécuter le transfert',
                                    ),
                                  ),
                                ),
                              ],
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

  Future<void> _validerOperation(
    BuildContext context,
    WidgetRef ref,
    TransactionModel tx,
    bool approuve,
  ) async {
    String? motifRejet;
    if (!approuve) {
      motifRejet = await _demanderMotifRejet(context);
      if ((motifRejet ?? '').trim().isEmpty || !context.mounted) return;
    } else {
      final ok = await AppDialogs.confirm(
        context,
        title: 'Valider cette opération ?',
        message:
            'Le ${tx.typeLabel.toLowerCase()} ${tx.reference} pourra ensuite être exécuté par le caissier.',
        confirmLabel: 'Valider',
        confirmColor: AppTheme.success,
      );
      if (!ok || !context.mounted) return;
    }

    try {
      await ref.read(transactionRepositoryProvider).validerOperation(
            tx.id,
            approuve: approuve,
            motifRejet: motifRejet,
          );
      ref.invalidate(transactionsProvider);
      ref.invalidate(dashboardProvider);
      ref.invalidate(creditsProvider);
      if (context.mounted) {
        context.showSnackBarWithColor(approuve
                ? 'Opération validée'
                : 'Opération rejetée', approuve ? AppTheme.success : AppTheme.error);
      }
    } catch (e) {
      if (context.mounted) {
        context.showErrorSnackBar(e.toString());
      }
    }
  }

  Future<void> _executerOperation(
    BuildContext context,
    WidgetRef ref,
    TransactionModel tx,
  ) async {
    final ok = await AppDialogs.confirm(
      context,
      title: 'Confirmer l’exécution',
      message: tx.typeTransaction == 'RETRAIT'
          ? 'Confirmez-vous la remise des fonds au client ?'
          : 'Confirmez-vous l’exécution définitive du transfert ?',
      confirmLabel: 'Exécuter',
    );
    if (!ok || !context.mounted) return;

    try {
      await ref.read(transactionRepositoryProvider).executerOperation(tx.id);
      ref.invalidate(transactionsProvider);
      ref.invalidate(comptesProvider);
      ref.invalidate(dashboardProvider);
      if (context.mounted) {
        context.showSuccessSnackBar('Opération exécutée avec succès');
      }
    } catch (e) {
      if (context.mounted) {
        context.showErrorSnackBar(e.toString());
      }
    }
  }

  Future<String?> _demanderMotifRejet(BuildContext context) {
    return AppDialogs.prompt(
      context,
      title: 'Motif du rejet',
      hint: 'Expliquez pourquoi la demande est rejetée',
      confirmLabel: 'Rejeter',
      confirmColor: AppTheme.error,
      maxLines: 4,
    );
  }

  String _detailLine(TransactionModel tx) {
    final details = <String>[
      tx.numeroCompte,
      if (tx.numeroCompteDestination != null &&
          tx.numeroCompteDestination!.isNotEmpty)
        'vers ${tx.numeroCompteDestination}',
      if (tx.initiePar != null && tx.initiePar!.isNotEmpty)
        'initiée par ${tx.initiePar}',
      if (tx.validePar != null && tx.validePar!.isNotEmpty)
        'validée par ${tx.validePar}',
    ];
    return details.join(' • ');
  }

  Color _amountColor(TransactionModel tx) {
    if (!tx.isExecuted && tx.isSensitive) {
      return AppTheme.warning;
    }
    return tx.isCredit ? AppTheme.success : AppTheme.error;
  }

  IconData _iconFor(TransactionModel tx) {
    return switch (tx.typeTransaction) {
      'DEPOT' => Icons.arrow_downward,
      'TRANSFERT' => Icons.swap_horiz,
      'RETRAIT' => Icons.arrow_upward,
      _ => tx.isCredit ? Icons.arrow_downward : Icons.arrow_upward,
    };
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
