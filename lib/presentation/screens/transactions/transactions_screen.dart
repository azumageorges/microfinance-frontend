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

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  String _selectedFilter = 'TOUS';
  String _searchQuery = '';

  static const _filters = ['TOUS', 'DEPOT', 'RETRAIT', 'TRANSFERT'];
  static const _filterLabels = {
    'TOUS': 'Tous',
    'DEPOT': 'Dépôts',
    'RETRAIT': 'Retraits',
    'TRANSFERT': 'Transferts',
  };

  @override
  void initState() {
    super.initState();
    // Écouter les notifications WebSocket pour rafraîchir automatiquement
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(webSocketServiceProvider).notifications.listen((notification) {
        if (notification.type.startsWith('TRANSACTION')) {
          ref.invalidate(transactionsProvider);
          ref.invalidate(comptesProvider);
          ref.invalidate(dashboardProvider);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final txAsync = ref.watch(transactionsProvider);
    final auth = ref.watch(authProvider);
    final canCreate = auth?.canDoTransactions == true;
    final canValidate = auth?.canValidateSensitiveTransactions == true;
    final canExecute = auth?.canExecuteSensitiveTransactions == true;

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
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
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

          // Filtres et recherche
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              children: [
                // Filtres par type
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: _filters.map<Widget>((filter) {
                      final isSelected = _selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(_filterLabels[filter] ?? filter),
                      selected: isSelected,
                      onSelected: (_) => setState(() => _selectedFilter = filter),
                      selectedColor: AppTheme.primaryLight,
                      labelStyle: TextStyle(
                        color: isSelected ? AppTheme.primary : AppTheme.textPrimary,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        fontSize: 13,
                      ),
                      backgroundColor: Colors.grey[100],
                    ),
                  );
                }).toList(),
                  ),
                ),
                const SizedBox(height: 8),
                // Barre de recherche
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Rechercher une transaction...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => setState(() => _searchQuery = ''),
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
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
                // Filtrer les transactions
                var filteredTxs = txs;
                if (_selectedFilter != 'TOUS') {
                  filteredTxs = txs.where((tx) => tx.typeTransaction == _selectedFilter).toList();
                }
                if (_searchQuery.isNotEmpty) {
                  final query = _searchQuery.toLowerCase();
                  filteredTxs = filteredTxs.where((tx) =>
                      tx.reference.toLowerCase().contains(query) ||
                      (tx.nomClient?.toLowerCase().contains(query) ?? false) ||
                      tx.numeroCompte.toLowerCase().contains(query) ||
                      (tx.numeroCompteDestination?.toLowerCase().contains(query) ?? false)
                  ).toList();
                }

                if (filteredTxs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: AppTheme.textSecondary.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Aucune transaction trouvée',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async =>
                      ref.invalidate(transactionsProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: filteredTxs.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: 10),
                    itemBuilder: (ctx, i) {
                      final tx = filteredTxs[i];
                      return _TransactionCard(
                        tx: tx,
                        canValidate: canValidate,
                        canExecute: canExecute,
                        onValidate: (approuve) => _validerOperation(context, ref, tx, approuve),
                        onExecute: () => _executerOperation(context, ref, tx),
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
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Valider cette opération ?'),
          content: Text(
            'Le ${tx.typeLabel.toLowerCase()} ${tx.reference} pourra ensuite être exécuté par le caissier ou le gestionnaire.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.success,
              ),
              child: const Text('Valider'),
            ),
          ],
        ),
      );
      if (ok != true || !context.mounted) return;
    }

    try {
      await ref.read(transactionRepositoryProvider).validerOperation(
            tx.id,
            approuve: approuve,
            motifRejet: motifRejet,
          );
      ref.invalidate(transactionsProvider);
      ref.invalidate(comptesProvider);
      ref.invalidate(dashboardProvider);
      ref.invalidate(creditsProvider);
      if (context.mounted) {
        if (approuve) {
          AppSnackBar.success(context, 'Opération validée');
        } else {
          AppSnackBar.error(context, 'Opération rejetée');
        }
      }
    } catch (e) {
      if (context.mounted) {
        AppSnackBar.error(context, e.toString());
      }
    }
  }

  Future<void> _executerOperation(
    BuildContext context,
    WidgetRef ref,
    TransactionModel tx,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirmer l'exécution"),
        content: Text(
          tx.typeTransaction == 'RETRAIT'
              ? 'Confirmez-vous la remise des fonds au client ?'
              : "Confirmez-vous l'exécution définitive du transfert ?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Exécuter'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;

    try {
      await ref.read(transactionRepositoryProvider).executerOperation(tx.id);
      ref.invalidate(transactionsProvider);
      ref.invalidate(comptesProvider);
      ref.invalidate(dashboardProvider);
      if (context.mounted) {
        AppSnackBar.success(context, 'Opération exécutée avec succès');
      }
    } catch (e) {
      if (context.mounted) {
        AppSnackBar.error(context, e.toString());
      }
    }
  }

  Future<String?> _demanderMotifRejet(BuildContext context) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Motif du rejet'),
        content: TextField(
          controller: controller,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Expliquez pourquoi la demande est rejetée',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
            ),
            child: const Text('Rejeter'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }
}

class _TransactionCard extends StatelessWidget {
  final TransactionModel tx;
  final bool canValidate;
  final bool canExecute;
  final Function(bool) onValidate;
  final VoidCallback onExecute;

  const _TransactionCard({
    required this.tx,
    required this.canValidate,
    required this.canExecute,
    required this.onValidate,
    required this.onExecute,
  });

  Color _amountColor() {
    if (!tx.isExecuted && tx.isSensitive) {
      return AppTheme.warning;
    }
    return tx.isCredit ? AppTheme.success : AppTheme.error;
  }

  IconData _iconFor() {
    return switch (tx.typeTransaction) {
      'DEPOT' => Icons.arrow_downward,
      'TRANSFERT' => Icons.swap_horiz,
      'RETRAIT' => Icons.arrow_upward,
      _ => tx.isCredit ? Icons.arrow_downward : Icons.arrow_upward,
    };
  }

  String _detailLine() {
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

  @override
  Widget build(BuildContext context) {
    final amountColor = _amountColor();
    final icon = _iconFor();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/transactions/${tx.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: amountColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      color: amountColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                tx.typeLabel,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
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
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
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
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        Formatters.currency(tx.montant),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: amountColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        Formatters.shortDate(
                            tx.dateExecution ?? tx.dateTransaction),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _detailLine(),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
              if (tx.motif != null && tx.motif!.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Motif : ${tx.motif}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
              if (tx.motifRejet != null && tx.motifRejet!.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: AppTheme.error,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Rejet : ${tx.motifRejet}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (tx.isPendingValidation && canValidate) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => onValidate(false),
                        icon: const Icon(
                          Icons.close,
                          color: AppTheme.error,
                          size: 18,
                        ),
                        label: const Text(
                          'Rejeter',
                          style: TextStyle(
                            color: AppTheme.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppTheme.error),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => onValidate(true),
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text(
                          'Valider',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.success,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              if (tx.isValidated && canExecute) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onExecute,
                    icon: const Icon(Icons.payments_outlined, size: 18),
                    label: Text(
                      tx.typeTransaction == 'RETRAIT'
                          ? 'Remettre les fonds'
                          : 'Exécuter le transfert',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
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
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                  fontSize: 13,
                  color: color,
                  fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
