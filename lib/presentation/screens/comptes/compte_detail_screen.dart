import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/compte_model.dart';
import '../../../data/models/credit_model.dart';
import '../../../data/models/transaction_model.dart';
import '../../../providers/providers.dart';
import '../../widgets/loading_overlay.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/app_app_bar.dart';

class CompteDetailScreen extends ConsumerWidget {
  final String numeroCompte;

  const CompteDetailScreen({super.key, required this.numeroCompte});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final compteAsync = ref.watch(_compteByNumeroProvider(numeroCompte));
    final txAsync = ref.watch(_txByCompteProvider(numeroCompte));
    final auth = ref.watch(authProvider);
    final canManage = auth?.isAdmin == true || auth?.isGestionnaire == true;

    return compteAsync.when(
      loading: () => const Scaffold(body: LoadingOverlay()),
      error: (err, _) => Scaffold(body: ErrorView(message: err.toString())),
      data: (compte) {
        return Scaffold(
          appBar: AppAppBar(
            title: compte.typeLabel,
            actions: [
              // Le compte CREDIT est géré exclusivement par le workflow crédit
              // Bloquer/clôturer reste accessible mais pas "Modifier"
              if (canManage && compte.typeCompte != 'CREDIT')
                PopupMenuButton<String>(
                  onSelected: (action) =>
                      _handleAction(context, ref, action, compte.statut),
                  itemBuilder: (_) => [
                    if (compte.statut == 'ACTIF')
                      const PopupMenuItem(
                        value: 'modifier',
                        child: Row(children: [
                          Icon(Icons.edit_outlined, size: 18),
                          SizedBox(width: 8),
                          Text('Modifier'),
                        ]),
                      ),
                    if (compte.statut == 'ACTIF')
                      const PopupMenuItem(
                        value: 'bloquer',
                        child: Row(children: [
                          Icon(Icons.lock_outline, size: 18),
                          SizedBox(width: 8),
                          Text('Bloquer'),
                        ]),
                      ),
                    if (compte.statut == 'BLOQUE')
                      const PopupMenuItem(
                        value: 'debloquer',
                        child: Row(children: [
                          Icon(Icons.lock_open_outlined, size: 18),
                          SizedBox(width: 8),
                          Text('Débloquer'),
                        ]),
                      ),
                    if (compte.statut != 'CLOTURE')
                      const PopupMenuItem(
                        value: 'cloturer',
                        child: Row(children: [
                          Icon(Icons.close, size: 18,
                              color: AppTheme.error),
                          SizedBox(width: 8),
                          Text('Clôturer',
                              style: TextStyle(color: AppTheme.error)),
                        ]),
                      ),
                    if (compte.statut != 'CLOTURE')
                      const PopupMenuItem(
                        value: 'supprimer',
                        child: Row(children: [
                          Icon(Icons.delete_outline, size: 18,
                              color: AppTheme.error),
                          SizedBox(width: 8),
                          Text('Supprimer',
                              style: TextStyle(color: AppTheme.error)),
                        ]),
                      ),
                  ],
                ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Carte principale : différente selon le type ───────────────
              if (compte.typeCompte == 'CREDIT')
                _CreditCompteHeader(compte: compte, ref: ref)
              else
                Card(
                  color: AppTheme.primary,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Text(
                          compte.typeCompte == 'DAT'
                              ? 'Capital déposé'
                              : 'Solde disponible',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 13),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          Formatters.currency(compte.solde),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (compte.typeCompte == 'DAT' &&
                            compte.montantAvecInterets != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            'À percevoir à l\'échéance : ${Formatters.currency(compte.montantAvecInterets)}',
                            style: const TextStyle(
                                color: Colors.white60, fontSize: 12),
                          ),
                        ],
                        const SizedBox(height: 12),
                        StatusBadge(status: compte.statut),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 12),

              // Infos
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Informations',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),
                      _InfoRow(label: 'Numéro', value: compte.numeroCompte),
                      _InfoRow(label: 'Type', value: compte.typeLabel),
                      _InfoRow(
                          label: 'Client',
                          value: compte.clientFullName),
                      if (compte.dateOuverture != null)
                        _InfoRow(
                            label: 'Ouvert le',
                            value: Formatters.date(compte.dateOuverture)),
                      if (compte.dateEcheance != null)
                        _InfoRow(
                            label: 'Échéance',
                            value: Formatters.date(compte.dateEcheance)),
                      if (compte.tauxInteret != null)
                        _InfoRow(
                            label: 'Taux d\'intérêt',
                            value: '${compte.tauxInteret}%'),
                      if (compte.dureeEnMois != null)
                        _InfoRow(
                            label: 'Durée',
                            value: '${compte.dureeEnMois} mois'),
                      if (compte.montantCible != null)
                        _InfoRow(
                            label: 'Montant cible',
                            value: Formatters.currency(compte.montantCible)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Actions rapides caissier — interdites sur les comptes CREDIT
              // Un compte CREDIT ne supporte que le cycle de vie du crédit
              if (auth?.canDoTransactions == true &&
                  compte.typeCompte != 'CREDIT' &&
                  compte.typeCompte != 'DAT') ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => context.push('/transactions/depot'),
                        icon: const Icon(Icons.add),
                        label: const Text('Dépôt'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            context.push('/transactions/retrait'),
                        icon: const Icon(Icons.remove),
                        label: const Text('Retrait'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],

              // Bannière informative pour compte CREDIT
              if (compte.typeCompte == 'CREDIT') ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.primary.withValues(alpha: 0.25)),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, color: AppTheme.primary, size: 18),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Compte crédit — Dépôts, retraits et transferts non autorisés.\n'
                          'Ce compte est géré exclusivement via le cycle de vie du crédit\n'
                          '(demande · validation · déblocage · remboursement).',
                          style: TextStyle(fontSize: 12, color: AppTheme.primary, height: 1.5),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Bannière informative pour compte DAT (capital bloqué)
              if (compte.typeCompte == 'DAT') ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.warning.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.warning.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.lock_clock, color: AppTheme.warning, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Dépôt à Terme — Capital bloqué jusqu\'au '
                          '${compte.dateEcheance != null ? compte.dateEcheance.toString().split(" ").first : "terme"}.\n'
                          'Retrait uniquement disponible à l\'échéance.',
                          style: const TextStyle(fontSize: 12, color: AppTheme.warning, height: 1.5),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Transactions
              Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text('Historique des transactions',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700)),
                    ),
                    const Divider(height: 1),
                    txAsync.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.all(16),
                        child: LinearProgressIndicator(),
                      ),
                      error: (e, _) => Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text('Erreur: $e',
                            style: const TextStyle(color: AppTheme.error)),
                      ),
                      data: (txs) {
                        if (txs.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text('Aucune transaction',
                                style: TextStyle(
                                    color: AppTheme.textSecondary)),
                          );
                        }
                        return Column(
                          children: txs
                              .take(20)
                              .map<Widget>((tx) => ListTile(
                                    dense: true,
                                    leading: Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: (tx.isCredit
                                                ? AppTheme.success
                                                : AppTheme.error)
                                            .withValues(alpha: 0.12),
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        tx.isCredit
                                            ? Icons.arrow_downward
                                            : Icons.arrow_upward,
                                        size: 16,
                                        color: tx.isCredit
                                            ? AppTheme.success
                                            : AppTheme.error,
                                      ),
                                    ),
                                    title: Text(
                                      tx.typeLabel,
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                    subtitle: Text(
                                      Formatters.date(tx.dateTransaction),
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                    trailing: Text(
                                      Formatters.currency(tx.montant),
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: tx.isCredit
                                            ? AppTheme.success
                                            : AppTheme.error,
                                      ),
                                    ),
                                  ))
                              .toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleAction(
    BuildContext context,
    WidgetRef ref,
    String action,
    String currentStatut,
  ) async {
    final repo = ref.read(compteRepositoryProvider);
    try {
      if (action == 'bloquer') {
        await repo.bloquerCompte(numeroCompte);
      } else if (action == 'debloquer') {
        await repo.debloquerCompte(numeroCompte);
      } else if (action == 'cloturer') {
        await repo.cloturerCompte(numeroCompte);
      } else if (action == 'supprimer') {
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Supprimer ce compte ?'),
            content: const Text(
              'Cette action est irréversible. Le compte sera supprimé définitivement '
              's\'il n\'a pas de transactions ni de crédits actifs.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
                child: const Text('Supprimer'),
              ),
            ],
          ),
        );
        if (ok == true && context.mounted) {
          await repo.supprimerCompte(numeroCompte);
          if (context.mounted) {
            context.pop();
          }
        }
        if (!context.mounted) return;
      } else if (action == 'modifier') {
        if (context.mounted) {
          await context.push('/comptes/$numeroCompte/modifier');
        }
        return;
      }
      ref.invalidate(comptesProvider);
      if (context.mounted) {
        AppSnackBar.success(
          context,
          action == 'supprimer' ? 'Compte supprimé' : 'Opération effectuée',
        );
      }
    } catch (e) {
      if (context.mounted) {
        AppSnackBar.error(context, e.toString());
      }
    }
  }
}

// Providers paramétrés
final _compteByNumeroProvider = FutureProvider.family<CompteModel, String>(
  (ref, numero) =>
      ref.watch(compteRepositoryProvider).getCompteByNumero(numero),
);

final _txByCompteProvider =
    FutureProvider.family<List<TransactionModel>, String>(
  (ref, numero) =>
      ref.watch(transactionRepositoryProvider).getTransactionsByCompte(numero),
);

// Provider pour charger le crédit associé à un compte CREDIT
final _creditByCompteProvider =
    FutureProvider.family<List<CreditModel>, int>((ref, clientId) async {
  return ref.watch(creditRepositoryProvider).getCreditsByClient(clientId);
});

// ─── Header spécial pour compte CREDIT ───────────────────────────────────────

class _CreditCompteHeader extends ConsumerWidget {
  final CompteModel compte;
  final WidgetRef ref;

  const _CreditCompteHeader({required this.compte, required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final creditsAsync = ref.watch(_creditByCompteProvider(compte.clientId));

    return creditsAsync.when(
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (Object e, _) => _CreditCompteHeaderStatic(compte: compte),
      data: (credits) {
        final creditActif = credits
            .where((c) =>
                c.numeroCompte == compte.numeroCompte &&
                c.statut != 'REMBOURSE' &&
                c.statut != 'REJETE')
            .firstOrNull;
        final creditRembourse = credits
            .where((c) =>
                c.numeroCompte == compte.numeroCompte &&
                c.statut == 'REMBOURSE')
            .lastOrNull;
        final credit = creditActif ?? creditRembourse;

        if (credit == null) {
          return Card(
            color: AppTheme.textSecondary.withValues(alpha: 0.06),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                  color: AppTheme.textSecondary.withValues(alpha: 0.2)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.credit_score,
                        color: AppTheme.primary, size: 28),
                  ),
                  const SizedBox(height: 12),
                  Text(compte.numeroCompte,
                      style: const TextStyle(
                          fontSize: 13,
                          fontFamily: 'monospace',
                          color: AppTheme.textSecondary)),
                  const SizedBox(height: 8),
                  StatusBadge(status: compte.statut),
                  const SizedBox(height: 12),
                  const Text(
                    'Aucun crédit actif — en attente de demande',
                    style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        final (headerColor, statusText) = switch (credit.statut) {
          'EN_ATTENTE'           => (AppTheme.warning, 'En attente de validation'),
          'VALIDE'               => (AppTheme.primary, 'Validé — en attente de déblocage'),
          'DEBLOCAGE_EN_ATTENTE' => (AppTheme.primary, 'Déblocage en attente'),
          'EN_COURS'             => (AppTheme.success, 'En cours de remboursement'),
          'EN_RETARD'            => (AppTheme.error, 'En retard'),
          'REMBOURSE'            => (AppTheme.success, 'Intégralement remboursé'),
          'REJETE'               => (AppTheme.error, 'Rejeté'),
          _                      => (AppTheme.primary, credit.statutLabel),
        };

        return Card(
          color: headerColor.withValues(alpha: 0.06),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: headerColor.withValues(alpha: 0.3)),
          ),
          child: InkWell(
            onTap: () => context.push('/credits/${credit.referenceCredit}'),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: headerColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.credit_score, color: headerColor, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(credit.referenceCredit,
                                style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600)),
                            Text(statusText,
                                style: TextStyle(fontSize: 12, color: headerColor)),
                          ],
                        ),
                      ),
                      StatusBadge(status: credit.statut, label: credit.statutLabel),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _CreditStat(
                          label: 'Montant prêt',
                          value: Formatters.currency(credit.montantPret),
                          color: AppTheme.primary),
                      _CreditStat(
                          label: 'Remboursé',
                          value: Formatters.currency(credit.totalRembourse),
                          color: AppTheme.success),
                      if (credit.resteARembourser != null)
                        _CreditStat(
                            label: 'Restant',
                            value: Formatters.currency(credit.resteARembourser),
                            color: credit.statut == 'EN_RETARD'
                                ? AppTheme.error
                                : AppTheme.textPrimary),
                    ],
                  ),
                  if (credit.statut == 'EN_COURS' || credit.statut == 'EN_RETARD') ...[
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: credit.progressionRemboursement.clamp(0.0, 1.0),
                        minHeight: 6,
                        backgroundColor: headerColor.withValues(alpha: 0.15),
                        color: headerColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${credit.nombreEcheancesPayees}/${credit.nombreEcheances} échéances',
                          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                        ),
                        Text(
                          '${(credit.progressionRemboursement * 100).toStringAsFixed(0)} %',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: headerColor),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.open_in_new, size: 14, color: headerColor),
                      const SizedBox(width: 4),
                      Text('Voir le détail du crédit',
                          style: TextStyle(
                              fontSize: 12,
                              color: headerColor,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CreditCompteHeaderStatic extends StatelessWidget {
  final CompteModel compte;
  const _CreditCompteHeaderStatic({required this.compte});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.primary,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text('Compte Crédit',
                style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 8),
            Text(compte.numeroCompte,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            StatusBadge(status: compte.statut),
          ],
        ),
      ),
    );
  }
}

class _CreditStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _CreditStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }
}

// ─── _InfoRow ─────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 13, color: AppTheme.textSecondary)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
