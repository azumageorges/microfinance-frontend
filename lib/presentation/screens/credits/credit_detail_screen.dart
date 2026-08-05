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
                      if (credit.dateDemandeDeblocage != null)
                        _Row('Date demande déblocage',
                            Formatters.date(credit.dateDemandeDeblocage)),
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
                      if (credit.motifRejetDeblocage != null)
                        _Row('Motif rejet déblocage',
                            credit.motifRejetDeblocage!,
                            color: AppTheme.error),
                      if (credit.debloquePar != null)
                        _Row('Initié par', credit.debloquePar!),
                      if (credit.deblocageValidePar != null)
                        _Row('Validé par', credit.deblocageValidePar!),
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

    // Demander déblocage (Caissier, VALIDE)
    if (credit.statut == 'VALIDE' && auth?.isCaissier == true) {
      actions.addAll([
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: () => _demanderDeblocage(context, ref, credit.id),
          icon: const Icon(Icons.send),
          label: const Text('Demander déblocage'),
          style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary),
        ),
      ]);
    }

    // Valider déblocage (Gestionnaire, DEBLOCAGE_EN_ATTENTE)
    if (credit.statut == 'DEBLOCAGE_EN_ATTENTE' && auth?.isGestionnaire == true) {
      actions.addAll([
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _validerDeblocage(context, ref, credit.id, false),
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
                onPressed: () => _validerDeblocage(context, ref, credit.id, true),
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

    // Exécuter déblocage (Caissier, VALIDE après validation)
    if (credit.statut == 'VALIDE' && 
        credit.motifRejetDeblocage == null &&
        credit.deblocageValidePar != null &&
        auth?.isCaissier == true) {
      actions.addAll([
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: () => _executerDeblocage(context, ref, credit.id),
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
        if (approuve) {
          AppSnackBar.success(context, 'Crédit approuvé ✓');
        } else {
          AppSnackBar.info(context, 'Crédit rejeté');
        }
      }
    } catch (e) {
      if (context.mounted) {
        AppSnackBar.error(context, e.toString());
      }
    }
  }

  Future<void> _demanderDeblocage(
    BuildContext context,
    WidgetRef ref,
    int creditId,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Demander le déblocage ?'),
        content: const Text(
            'Cette action créera une demande de déblocage qui devra être validée par le gestionnaire.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;

    try {
      await ref.read(creditRepositoryProvider).demanderDeblocage(creditId);
      ref.invalidate(creditsProvider);
      ref.invalidate(_creditByReferenceProvider(reference));
      if (context.mounted) {
        AppSnackBar.success(context, 'Demande de déblocage envoyée ✓');
      }
    } catch (e) {
      if (context.mounted) {
        AppSnackBar.error(context, e.toString());
      }
    }
  }

  Future<void> _validerDeblocage(
    BuildContext context,
    WidgetRef ref,
    int creditId,
    bool approuve,
  ) async {
    String? motifRejet;

    if (!approuve) {
      final motifCtrl = TextEditingController();
      final formKey = GlobalKey<FormState>();
      final result = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Rejeter le déblocage ?'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Le déblocage sera rejeté. Le caissier devra en faire une nouvelle demande.',
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
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Approuver le déblocage ?'),
          content: const Text(
              'Le caissier pourra ensuite décaisser les fonds au client.'),
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
      await ref.read(creditRepositoryProvider).validerDeblocage(
            creditId,
            approuve: approuve,
            motifRejet: motifRejet,
          );
      ref.invalidate(creditsProvider);
      ref.invalidate(_creditByReferenceProvider(reference));
      if (context.mounted) {
        if (approuve) {
          AppSnackBar.success(context, 'Déblocage approuvé ✓');
        } else {
          AppSnackBar.info(context, 'Déblocage rejeté');
        }
      }
    } catch (e) {
      if (context.mounted) {
        AppSnackBar.error(context, e.toString());
      }
    }
  }

  Future<void> _executerDeblocage(
    BuildContext context,
    WidgetRef ref,
    int creditId,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Décaisser les fonds ?'),
        content: const Text(
            'Les fonds seront crédités sur le compte du client. Cette action est irréversible.'),
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
      await ref.read(creditRepositoryProvider).executerDeblocage(creditId);
      ref.invalidate(creditsProvider);
      ref.invalidate(_creditByReferenceProvider(reference));
      if (context.mounted) {
        AppSnackBar.success(context, 'Décaissement effectué ✓');
      }
    } catch (e) {
      if (context.mounted) {
        AppSnackBar.error(context, e.toString());
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
    // Sépare les échéances payées des non-payées pour un meilleur affichage
    final nonPayees  = echeances.where((e) => !e.paye).toList();
    final payees     = echeances.where((e) =>  e.paye).toList();
    final canPay     = (credit.statut == 'EN_COURS' || credit.statut == 'EN_RETARD')
        && (auth?.isCaissier == true || auth?.isAdmin == true);

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── En-tête ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                const Text('Échéancier',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700)),
                const Spacer(),
                // Compteur payées / total
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: credit.nombreEcheancesPayees == echeances.length
                        ? AppTheme.success.withValues(alpha: 0.12)
                        : AppTheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${credit.nombreEcheancesPayees}/${echeances.length} payées',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: credit.nombreEcheancesPayees == echeances.length
                            ? AppTheme.success
                            : AppTheme.primary),
                  ),
                ),
              ],
            ),
          ),

          // ── Info case à cocher (caissier uniquement) ─────────────────
          if (canPay && nonPayees.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  Icon(Icons.touch_app_outlined,
                      size: 14,
                      color: AppTheme.textSecondary.withValues(alpha: 0.6)),
                  const SizedBox(width: 4),
                  Text(
                    'Cochez une échéance pour enregistrer le paiement',
                    style: TextStyle(
                        fontSize: 11,
                        color:
                            AppTheme.textSecondary.withValues(alpha: 0.7),
                        fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),

          const Divider(height: 1),

          // ── Échéances non payées ──────────────────────────────────────
          if (nonPayees.isNotEmpty) ...[
            ...nonPayees.map<Widget>((e) => _EcheanceTile(
                  echeance: e,
                  ref: ref,
                  onPaid: onPaid,
                  canPay: canPay,
                )),
          ],

          // ── Séparateur si les deux sections sont présentes ───────────
          if (nonPayees.isNotEmpty && payees.isNotEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('Payées',
                        style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.success,
                            fontWeight: FontWeight.w600)),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
            ),

          // ── Échéances payées ──────────────────────────────────────────
          if (payees.isNotEmpty)
            ...payees.map<Widget>((e) => _EcheanceTile(
                  echeance: e,
                  ref: ref,
                  onPaid: onPaid,
                  canPay: false,
                )),
        ],
      ),
    );
  }
}

// ─── Tuile échéance ───────────────────────────────────────────────────────────

class _EcheanceTile extends StatefulWidget {
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
  State<_EcheanceTile> createState() => _EcheanceTileState();
}

class _EcheanceTileState extends State<_EcheanceTile> {
  bool _processing = false;

  @override
  Widget build(BuildContext context) {
    final e = widget.echeance;
    final isRetard = !e.paye &&
        (e.statut == 'EN_RETARD' || e.datePrevue.isBefore(DateTime.now()));

    // Couleur selon le statut
    final Color rowColor;
    if (e.paye) {
      rowColor = AppTheme.success;
    } else if (isRetard) {
      rowColor = AppTheme.error;
    } else {
      rowColor = AppTheme.textSecondary;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: e.paye
            ? AppTheme.success.withValues(alpha: 0.04)
            : (isRetard
                ? AppTheme.error.withValues(alpha: 0.03)
                : Colors.transparent),
      ),
      child: ListTile(
        dense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 2),

        // ── Case à cocher ──────────────────────────────────────────────
        leading: _processing
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppTheme.primary,
                ),
              )
            : Checkbox(
                value: e.paye,
                tristate: false,
                activeColor: AppTheme.success,
                checkColor: Colors.white,
                side: BorderSide(
                  color: e.paye
                      ? AppTheme.success
                      : (isRetard ? AppTheme.error : AppTheme.textSecondary),
                  width: 2,
                ),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4)),
                onChanged: widget.canPay && !e.paye
                    ? (_) => _confirmerPaiement(context)
                    : null,
              ),

        // ── Numéro + date ──────────────────────────────────────────────
        title: Row(
          children: [
            Text(
              'Échéance ${e.numeroEcheance}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: e.paye ? AppTheme.success : AppTheme.textPrimary,
                decoration: e.paye ? TextDecoration.lineThrough : null,
                decorationColor: AppTheme.success,
              ),
            ),
            if (isRetard) ...[
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('En retard',
                    style: TextStyle(
                        fontSize: 10,
                        color: AppTheme.error,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ],
        ),

        // ── Date + statut ──────────────────────────────────────────────
        subtitle: Text(
          e.paye && e.datePaiement != null
              ? 'Payée le ${Formatters.date(e.datePaiement)} • ${Formatters.currency(e.montantDu)}'
              : '${Formatters.date(e.datePrevue)} • ${e.statutLabel}',
          style: TextStyle(
            fontSize: 11,
            color: isRetard ? AppTheme.error : AppTheme.textSecondary,
          ),
        ),

        // ── Montant + solde restant ────────────────────────────────────
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              Formatters.currency(e.montantDu),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: rowColor,
              ),
            ),
            if (e.soldeRestant != null && !e.paye) ...[
              const SizedBox(height: 2),
              Text(
                'Reste ${Formatters.currency(e.soldeRestant)}',
                style: const TextStyle(
                    fontSize: 10, color: AppTheme.textSecondary),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _confirmerPaiement(BuildContext context) async {
    final e = widget.echeance;

    // Dialog de confirmation avec récapitulatif clair
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.success.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.check_circle_outline,
                  color: AppTheme.success, size: 22),
            ),
            const SizedBox(width: 12),
            const Text('Valider le paiement',
                style: TextStyle(fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Récapitulatif
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  _DialogRow(
                      label: 'Échéance',
                      value: '${e.numeroEcheance}'),
                  const SizedBox(height: 4),
                  _DialogRow(
                      label: 'Date prévue',
                      value: Formatters.date(e.datePrevue)),
                  const SizedBox(height: 4),
                  _DialogRow(
                      label: 'Montant',
                      value: Formatters.currency(e.montantDu),
                      valueColor: AppTheme.success),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Le montant sera prélevé sur le compte épargne du client. '
              'Cette action est irréversible.',
              style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                  height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.success,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.check, size: 18),
            label: const Text('Confirmer le paiement'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;

    setState(() => _processing = true);
    try {
      await widget.ref
          .read(creditRepositoryProvider)
          .rembourserEcheance(e.id);
      widget.ref.invalidate(creditsProvider);
      widget.onPaid();
      if (context.mounted) {
        AppSnackBar.success(
            context, 'Échéance ${e.numeroEcheance} remboursée ✓');
      }
    } catch (err) {
      if (context.mounted) {
        AppSnackBar.error(context, err.toString());
      }
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }
}

// ─── Ligne du dialog de confirmation ─────────────────────────────────────────

class _DialogRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _DialogRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12, color: AppTheme.textSecondary)),
        Text(value,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: valueColor ?? AppTheme.textPrimary)),
      ],
    );
  }
}
