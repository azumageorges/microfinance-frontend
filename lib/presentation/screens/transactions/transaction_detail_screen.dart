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

class TransactionDetailScreen extends ConsumerStatefulWidget {
  final int transactionId;

  const TransactionDetailScreen({
    super.key,
    required this.transactionId,
  });

  @override
  ConsumerState<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState
    extends ConsumerState<TransactionDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final txAsync = ref.watch(
      FutureProvider.family<TransactionModel, int>(
        (ref, id) => ref.watch(transactionRepositoryProvider).getTransactionById(id),
      )(widget.transactionId),
    );

    return Scaffold(
      appBar: AppAppBar(
        title: 'Détails Transaction',
      ),
      body: txAsync.when(
        loading: () => const LoadingOverlay(),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppTheme.error),
              const SizedBox(height: 16),
              Text('Erreur: $e'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('Retour'),
              ),
            ],
          ),
        ),
        data: (tx) => _buildDetail(context, tx),
      ),
    );
  }

  Widget _buildDetail(BuildContext context, TransactionModel tx) {
    final auth = ref.watch(authProvider);
    final canValidate = auth?.canValidateSensitiveTransactions == true;
    final canExecute = auth?.canExecuteSensitiveTransactions == true;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Carte principale
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: _amountColor(tx).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          _iconFor(tx),
                          color: _amountColor(tx),
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tx.typeLabel,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              tx.reference,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ),
                      StatusBadge(
                        status: tx.statut,
                        label: tx.statutLabel,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    Formatters.currency(tx.montant),
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: _amountColor(tx),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Informations détaillées
          _Section(
            title: 'Informations',
            children: [
              _InfoRow(
                label: 'Compte',
                value: tx.numeroCompte,
                icon: Icons.account_balance,
              ),
              if (tx.numeroCompteDestination != null)
                _InfoRow(
                  label: 'Compte destination',
                  value: tx.numeroCompteDestination ?? 'N/A',
                  icon: Icons.arrow_forward,
                ),
              _InfoRow(
                label: 'Client',
                value: tx.nomClient ?? 'N/A',
                icon: Icons.person,
              ),
              _InfoRow(
                label: 'Date transaction',
                value: Formatters.dateTime(tx.dateTransaction),
                icon: Icons.calendar_today,
              ),
              if (tx.dateValidation != null)
                _InfoRow(
                  label: 'Date validation',
                  value: Formatters.dateTime(tx.dateValidation),
                  icon: Icons.check_circle,
                ),
              if (tx.dateExecution != null)
                _InfoRow(
                  label: 'Date exécution',
                  value: Formatters.dateTime(tx.dateExecution),
                  icon: Icons.play_arrow,
                ),
            ],
          ),

          const SizedBox(height: 20),

          // Soldes
          if (tx.soldeAvant != null || tx.soldeApres != null)
            _Section(
              title: 'Soldes',
              children: [
                if (tx.soldeAvant != null)
                  _InfoRow(
                    label: 'Solde avant',
                    value: Formatters.currency(tx.soldeAvant),
                    icon: Icons.trending_up,
                  ),
                if (tx.soldeApres != null)
                  _InfoRow(
                    label: 'Solde après',
                    value: Formatters.currency(tx.soldeApres),
                    icon: Icons.trending_down,
                  ),
              ],
            ),

          const SizedBox(height: 20),

          // Participants
          _Section(
            title: 'Participants',
            children: [
              if (tx.initiePar != null)
                _InfoRow(
                  label: 'Initié par',
                  value: tx.initiePar ?? 'N/A',
                  icon: Icons.person_add,
                ),
              if (tx.effectuePar != null)
                _InfoRow(
                  label: 'Effectué par',
                  value: tx.effectuePar ?? 'N/A',
                  icon: Icons.done,
                ),
              if (tx.validePar != null)
                _InfoRow(
                  label: 'Validé par',
                  value: tx.validePar ?? 'N/A',
                  icon: Icons.verified,
                ),
            ],
          ),

          const SizedBox(height: 20),

          // Motif
          if (tx.motif != null && tx.motif!.isNotEmpty)
            _Section(
              title: 'Motif',
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    tx.motif!,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),

          // Motif de rejet
          if (tx.motifRejet != null && tx.motifRejet!.isNotEmpty)
            _Section(
              title: 'Motif de rejet',
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    tx.motifRejet!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.error,
                    ),
                  ),
                ),
              ],
            ),

          const SizedBox(height: 20),

          // Actions
          if (tx.statut == 'EN_ATTENTE' && canValidate)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _validerOperation(context, ref, tx, true),
                    icon: const Icon(Icons.check),
                    label: const Text('Valider'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.success,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _validerOperation(context, ref, tx, false),
                    icon: const Icon(Icons.close),
                    label: const Text('Rejeter'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.error,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),

          if (tx.statut == 'VALIDEE' && canExecute)
            ElevatedButton.icon(
              onPressed: () => _executerOperation(context, ref, tx),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Exécuter'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
              ),
            ),

          const SizedBox(height: 40),
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
            'Le ${tx.typeLabel.toLowerCase()} ${tx.reference} pourra ensuite être exécuté.',
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
      if (context.mounted) {
        if (approuve) {
          AppSnackBar.success(context, 'Opération validée');
        } else {
          AppSnackBar.error(context, 'Opération rejetée');
        }
        context.pop();
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
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
            ),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;

    try {
      await ref.read(transactionRepositoryProvider).executerOperation(tx.id);
      ref.invalidate(transactionsProvider);
      ref.invalidate(dashboardProvider);
      if (context.mounted) {
        AppSnackBar.success(context, 'Opération exécutée');
        context.pop();
      }
    } catch (e) {
      if (context.mounted) {
        AppSnackBar.error(context, e.toString());
      }
    }
  }

  Future<String?> _demanderMotifRejet(BuildContext context) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Motif du rejet'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Entrez le motif du rejet',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  Color _amountColor(TransactionModel tx) {
    switch (tx.typeTransaction) {
      case 'DEPOT':
        return AppTheme.success;
      case 'RETRAIT':
      case 'TRANSFERT':
        return AppTheme.error;
      default:
        return AppTheme.primary;
    }
  }

  IconData _iconFor(TransactionModel tx) {
    switch (tx.typeTransaction) {
      case 'DEPOT':
        return Icons.add_circle;
      case 'RETRAIT':
        return Icons.remove_circle;
      case 'TRANSFERT':
        return Icons.swap_horiz;
      default:
        return Icons.receipt;
    }
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Section({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
