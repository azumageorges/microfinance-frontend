import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/credit_model.dart';
import '../../../providers/providers.dart';
import '../../widgets/loading_overlay.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/app_app_bar.dart';

// ─── Provider dédié : charge directement le crédit par référence ──────────────
// Évite de charger toute la liste côté client pour trouver un seul élément.
final _creditByReferenceProvider =
    FutureProvider.family<CreditModel, String>((ref, reference) async {
  return ref.watch(creditRepositoryProvider).getCreditByReference(reference);
});

class CreditDetailScreen extends ConsumerWidget {
  final String reference;

  const CreditDetailScreen({super.key, required this.reference});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final creditAsync = ref.watch(_creditByReferenceProvider(reference));
    final auth = ref.watch(authProvider);

    return Scaffold(
      appBar: AppAppBar(
        title: 'Détail du crédit',
        actions: [
          creditAsync.maybeWhen(
            data: (_) => IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Actualiser',
              onPressed: () => ref.invalidate(_creditByReferenceProvider(reference)),
            ),
            orElse: () => const SizedBox(),
          ),
        ],
      ),
      body: creditAsync.when(
        loading: () => const LoadingOverlay(),
        error: (err, _) => ErrorView(
          message: err.toString(),
          onRetry: () => ref.invalidate(_creditByReferenceProvider(reference)),
        ),
        data: (credit) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // En-tête
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
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
                      Text(
                        credit.nomClient ?? 'Client',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        credit.referenceCredit,
                        style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                            fontFamily: 'monospace'),
                      ),
                      const SizedBox(height: 10),
                      StatusBadge(
                          status: credit.statut,
                          label: credit.statutLabel),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Barre de progression remboursement
              if (credit.statut == 'EN_COURS' || credit.statut == 'EN_RETARD')
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Progression',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600)),
                            Text(
                              '${(credit.progressionRemboursement * 100).toStringAsFixed(0)} %',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: credit.statut == 'EN_RETARD'
                                      ? AppTheme.error
                                      : AppTheme.success),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: credit.progressionRemboursement
                                .clamp(0.0, 1.0),
                            minHeight: 8,
                            backgroundColor: AppTheme.border,
                            color: credit.statut == 'EN_RETARD'
                                ? AppTheme.error
                                : AppTheme.success,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${credit.nombreEcheancesPayees}/${credit.echeances.length} échéances',
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textSecondary),
                            ),
                            if (credit.resteARembourser != null)
                              Text(
                                'Reste : ${Formatters.currency(credit.resteARembourser)}',
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
              if (credit.statut == 'EN_COURS' || credit.statut == 'EN_RETARD')
                const SizedBox(height: 12),

              // Montants
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Montants',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),
                      _Row('Montant du prêt',
                          Formatters.currency(credit.montantPret)),
                      if (credit.dateDeblocage != null)
                        _Row('Montant débloqué',
                            Formatters.currency(credit.montantPret),
                            color: AppTheme.success),
                      _Row('Frais du crédit',
                          Formatters.currency(credit.fraisCredit)),
                      if (credit.totalARembourser != null)
                        _Row('Total à rembourser',
                            Formatters.currency(credit.totalARembourser)),
                      _Row('Total remboursé',
                          Formatters.currency(credit.totalRembourse),
                          color: AppTheme.success),
                      if (credit.resteARembourser != null)
                        _Row('Reste à rembourser',
                            Formatters.currency(credit.resteARembourser),
                            color: AppTheme.error),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Conditions
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Conditions',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),
                      _Row('Type de crédit', credit.typeCreditLabel),
                      _Row('Mise quotidienne',
                          Formatters.currency(credit.miseQuotidienne)),
                      _Row('Jours de remboursement',
                          '${credit.nombreJoursRemboursement} jours'),
                      _Row('Nombre d\'échéances', '${credit.nombreEcheances}'),
                      if (credit.dateDemande != null)
                        _Row('Date demande',
                            Formatters.date(credit.dateDemande)),
                      if (credit.dateDeblocage != null)
                        _Row('Date déblocage',
                            Formatters.date(credit.dateDeblocage)),
                      if (credit.dateFin != null)
                        _Row('Date fin', Formatters.date(credit.dateFin)),
                      if (credit.motifDemande != null)
                        _Row('Motif', credit.motifDemande!),
                      if (credit.motifRejet != null)
                        _Row('Motif rejet', credit.motifRejet!,
                            color: AppTheme.error),
                    ],
                  ),
                ),
              ),

              // Actions selon rôle et statut
              ..._buildActions(context, ref, credit, auth),

              // Échéances
              if (credit.echeances.isNotEmpty) ...[
                const SizedBox(height: 12),
                _EcheancesCard(
                    echeances: credit.echeances,
                    ref: ref,
                    credit: credit,
                    auth: auth,
                    onPaid: () => ref.invalidate(
                        _creditByReferenceProvider(reference))),
              ],

              const SizedBox(height: 80),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildActions(
    BuildContext context,
    WidgetRef ref,
    CreditModel credit,
    dynamic auth,
  ) {
    final actions = <Widget>[];

    // Valider (Gestionnaire, EN_ATTENTE)
    if (credit.statut == 'EN_ATTENTE' && auth?.isGestionnaire == true) {
      actions.addAll([
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _valider(context, ref, credit.id, false),
                icon: const Icon(Icons.close, color: AppTheme.error),
                label: const Text('Rejeter',
                    style: TextStyle(color: AppTheme.error)),
                style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.error)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _valider(context, ref, credit.id, true),
                icon: const Icon(Icons.check),
                label: const Text('Approuver'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.success),
              ),
            ),
          ],
        ),
      ]);
    }

    // Débloquer (Caissier, VALIDE)
    if (credit.statut == 'VALIDE' && auth?.isCaissier == true) {
      actions.addAll([
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: () => _debloquer(context, ref, credit.id),
          icon: const Icon(Icons.lock_open),
                label: const Text('Décaisser les fonds'),
          style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary),
        ),
      ]);
    }

    return actions;
  }

  Future<void> _valider(
    BuildContext context,
    WidgetRef ref,
    int creditId,
    bool approuve,
  ) async {
    String? motifRejet;

    // Si rejet : demander le motif obligatoire dans le dialog
    if (!approuve) {
      final motifCtrl = TextEditingController();
      final formKey = GlobalKey<FormState>();
      final result = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Rejeter le crédit ?'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Le crédit sera rejeté définitivement.',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: motifCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Motif du rejet *',
                    hintText: 'Expliquez la raison du rejet...',
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Le motif est obligatoire' : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(ctx, true);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
              child: const Text('Confirmer le rejet'),
            ),
          ],
        ),
      );
      if (result != true || !context.mounted) return;
      motifRejet = motifCtrl.text.trim();
    } else {
      // Confirmation simple pour l'approbation
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Approuver le crédit ?'),
          content: const Text(
              'Le crédit sera validé et en attente de déblocage par le caissier.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
              child: const Text('Approuver'),
            ),
          ],
        ),
      );
      if (ok != true || !context.mounted) return;
    }

    try {
      await ref.read(creditRepositoryProvider).validerCredit(
            creditId,
            approuve: approuve,
            motifRejet: motifRejet,
          );
      ref.invalidate(creditsProvider);
      ref.invalidate(_creditByReferenceProvider(reference));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(approuve ? 'Crédit approuvé ✓' : 'Crédit rejeté'),
          backgroundColor:
              approuve ? AppTheme.success : AppTheme.textSecondary,
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.toString()), backgroundColor: AppTheme.error));
      }
    }
  }

  Future<void> _debloquer(
    BuildContext context,
    WidgetRef ref,
    int creditId,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Décaisser ce crédit ?'),
        content: const Text(
            'Les fonds seront remis au client après validation préalable du gestionnaire. Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary),
            child: const Text('Décaisser'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;

    try {
      await ref.read(creditRepositoryProvider).debloquerCredit(creditId);
      ref.invalidate(creditsProvider);
      ref.invalidate(_creditByReferenceProvider(reference));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Décaissement effectué'),
          backgroundColor: AppTheme.success,
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppTheme.error));
      }
    }
  }
}

// ─── Ligne d'info ─────────────────────────────────────────────────────────────

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _Row(this.label, this.value, {this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
              width: 150,
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 13, color: AppTheme.textSecondary))),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color ?? AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Card échéancier ──────────────────────────────────────────────────────────

class _EcheancesCard extends StatelessWidget {
  final List<EcheanceModel> echeances;
  final WidgetRef ref;
  final CreditModel credit;
  final dynamic auth;
  final VoidCallback onPaid;

  const _EcheancesCard({
    required this.echeances,
    required this.ref,
    required this.credit,
    required this.auth,
    required this.onPaid,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Échéancier',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700)),
                Text(
                  '${credit.nombreEcheancesPayees}/${echeances.length} payées',
                  style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...echeances.map((e) => _EcheanceTile(
                echeance: e,
                ref: ref,
                onPaid: onPaid,
                canPay: (credit.statut == 'EN_COURS' ||
                        credit.statut == 'EN_RETARD') &&
                    !e.paye &&
                    auth?.isCaissier == true,
              )),
        ],
      ),
    );
  }
}

// ─── Tuile échéance ───────────────────────────────────────────────────────────

class _EcheanceTile extends StatelessWidget {
  final EcheanceModel echeance;
  final WidgetRef ref;
  final bool canPay;
  final VoidCallback onPaid;

  const _EcheanceTile({
    required this.echeance,
    required this.ref,
    required this.canPay,
    required this.onPaid,
  });

  @override
  Widget build(BuildContext context) {
    final isRetard = echeance.statut == 'EN_RETARD' ||
        (!echeance.paye && echeance.datePrevue.isBefore(DateTime.now()));
    final montantAffiche = echeance.montantDu;

    return ListTile(
      dense: true,
      leading: CircleAvatar(
        radius: 16,
        backgroundColor: echeance.paye
            ? AppTheme.success.withValues(alpha: 0.15)
            : (isRetard
                ? AppTheme.error.withValues(alpha: 0.12)
                : AppTheme.textSecondary.withValues(alpha: 0.1)),
        child: Icon(
          echeance.paye
              ? Icons.check
              : (isRetard ? Icons.warning_amber : Icons.schedule),
          size: 16,
          color: echeance.paye
              ? AppTheme.success
              : (isRetard ? AppTheme.error : AppTheme.textSecondary),
        ),
      ),
      title: Text(
        'Échéance ${echeance.numeroEcheance}',
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        '${Formatters.date(echeance.datePrevue)} • ${echeance.statutLabel}'
        '${echeance.soldeRestant != null ? ' • Reste ${Formatters.currency(echeance.soldeRestant)}' : ''}',
        style: TextStyle(
          fontSize: 11,
          color: isRetard && !echeance.paye
              ? AppTheme.error
              : AppTheme.textSecondary,
        ),
      ),
      // Montant TOUJOURS visible + bouton Payer si canPay
      trailing: canPay
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  Formatters.currency(montantAffiche),
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => _confirmerPaiement(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    minimumSize: Size.zero,
                  ),
                  child: const Text('Payer'),
                ),
              ],
            )
          : Text(
              Formatters.currency(montantAffiche),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: echeance.paye
                    ? AppTheme.success
                    : (isRetard ? AppTheme.error : AppTheme.textPrimary),
              ),
            ),
    );
  }

  Future<void> _confirmerPaiement(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmer le paiement'),
        content: Text(
          'Enregistrer le remboursement de l\'échéance ${echeance.numeroEcheance} '
          '(${Formatters.currency(echeance.montantDu)}) ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.success),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;

    try {
      await ref
          .read(creditRepositoryProvider)
          .rembourserEcheance(echeance.id);
      ref.invalidate(creditsProvider);
      onPaid();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Échéance remboursée ✓'),
          backgroundColor: AppTheme.success,
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppTheme.error));
      }
    }
  }
}
