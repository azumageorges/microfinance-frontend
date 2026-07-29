import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/client_model.dart';
import '../../../data/models/compte_model.dart';
import '../../../providers/providers.dart';
import '../../widgets/loading_overlay.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/app_app_bar.dart';

// ─── Écran liste des crédits ──────────────────────────────────────────────────

class CreditsListScreen extends ConsumerStatefulWidget {
  const CreditsListScreen({super.key});

  @override
  ConsumerState<CreditsListScreen> createState() => _CreditsListScreenState();
}

class _CreditsListScreenState extends ConsumerState<CreditsListScreen> {
  String _filterStatut = 'TOUS';

  static const _statuts = [
    'TOUS', 'EN_ATTENTE', 'VALIDE', 'EN_COURS', 'REMBOURSE', 'REJETE', 'EN_RETARD'
  ];

  static const _statutLabels = {
    'TOUS':       'Tous',
    'EN_ATTENTE': 'En attente',
    'VALIDE':     'Validé',
    'EN_COURS':   'En cours',
    'REMBOURSE':  'Remboursé',
    'REJETE':     'Rejeté',
    'EN_RETARD':  'En retard',
  };

  @override
  Widget build(BuildContext context) {
    final creditsAsync = ref.watch(creditsProvider);

    return Scaffold(
      appBar: AppAppBar(
        title: 'Crédits',
        showSearch: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(creditsProvider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openDemandeCreditSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Demande de crédit'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Filtres statut
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              children: _statuts.map((s) {
                final sel = _filterStatut == s;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(_statutLabels[s] ?? s),
                    selected: sel,
                    onSelected: (_) => setState(() => _filterStatut = s),
                    selectedColor: AppTheme.primaryLight,
                    labelStyle: TextStyle(
                      color: sel ? AppTheme.primary : AppTheme.textPrimary,
                      fontWeight:
                          sel ? FontWeight.w600 : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          Expanded(
            child: creditsAsync.when(
              loading: () => const LoadingOverlay(),
              error: (err, _) => ErrorView(
                message: err.toString(),
                onRetry: () => ref.invalidate(creditsProvider),
              ),
              data: (credits) {
                final filtered = _filterStatut == 'TOUS'
                    ? credits
                    : credits.where((c) => c.statut == _filterStatut).toList();

                if (filtered.isEmpty) {
                  return const EmptyView(
                    message: 'Aucun crédit',
                    icon: Icons.credit_score_outlined,
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(creditsProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                    itemCount: filtered.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (ctx, i) {
                      final credit = filtered[i];
                      return Card(
                        child: InkWell(
                          onTap: () => context
                              .push('/credits/${credit.referenceCredit}'),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryLight,
                                        borderRadius:
                                            BorderRadius.circular(10),
                                      ),
                                      child: const Icon(Icons.credit_score,
                                          color: AppTheme.primary, size: 20),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            credit.nomClient ?? 'Client',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14),
                                          ),
                                          Text(
                                            credit.referenceCredit,
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
                                        status: credit.statut,
                                        label: credit.statutLabel),
                                  ],
                                ),
                                const Divider(height: 16),
                                Row(
                                  children: [
                                    _AmountChip(
                                      label: 'Montant prêt',
                                      value: Formatters.currency(
                                          credit.montantPret),
                                    ),
                                    if (credit.fraisCredit > 0) ...[
                                      const SizedBox(width: 8),
                                      _AmountChip(
                                        label: 'Frais',
                                        value: Formatters.currency(
                                            credit.fraisCredit),
                                        color: AppTheme.success,
                                      ),
                                    ],
                                    const Spacer(),
                                    Text(
                                      '${credit.typeCreditLabel} • ${credit.nombreEcheances} échéances',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.textSecondary),
                                    ),
                                  ],
                                ),
                                if (credit.statut == 'EN_COURS' &&
                                    credit.totalARembourser != null) ...[
                                  const SizedBox(height: 8),
                                  LinearProgressIndicator(
                                    value: credit.progressionRemboursement
                                        .clamp(0.0, 1.0),
                                    backgroundColor:
                                        AppTheme.primary.withValues(alpha: 0.15),
                                    color: AppTheme.primary,
                                    minHeight: 6,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Remboursé: ${Formatters.currency(credit.totalRembourse)}',
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: AppTheme.textSecondary),
                                      ),
                                      Text(
                                        'Reste: ${Formatters.currency(credit.resteARembourser)}',
                                        style: const TextStyle(
                                            fontSize: 11, color: AppTheme.error),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
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

  void _openDemandeCreditSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _DemandeCreditSheet(),
    );
  }
}

// ─── Chip montant ─────────────────────────────────────────────────────────────

class _AmountChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _AmountChip({
    required this.label,
    required this.value,
    this.color = AppTheme.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 10, color: AppTheme.textSecondary)),
        Text(value,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: color)),
      ],
    );
  }
}

// ─── Sheet demande de crédit — flux guidé 3 étapes ───────────────────────────
//
//  Étape 1 : Choisir le client
//  Étape 2 : Choisir / créer le compte CREDIT
//  Étape 3 : Saisir les paramètres et soumettre

class _DemandeCreditSheet extends ConsumerStatefulWidget {
  const _DemandeCreditSheet();

  @override
  ConsumerState<_DemandeCreditSheet> createState() =>
      _DemandeCreditSheetState();
}

class _DemandeCreditSheetState extends ConsumerState<_DemandeCreditSheet> {
  int _step = 1;

  ClientModel? _client;
  CompteModel? _compteCreditSelectionne;

  final _formKey = GlobalKey<FormState>();
  final _miseCtrl = TextEditingController();
  final _motifCtrl = TextEditingController();
  String _typeCredit = 'QUINZAINE';
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _miseCtrl.dispose();
    _motifCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Poignée
            const _SheetHandle(),
            // Header avec indicateur d'étapes
            _SheetHeader(step: _step, onClose: () => Navigator.pop(context)),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollCtrl,
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 16,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 32,
                ),
                child: _buildStep(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep() {
    return switch (_step) {
      1 => _StepClient(
          onSelected: (c) => setState(() {
            _client = c;
            _compteCreditSelectionne = null;
            _step = 2;
          }),
        ),
      2 => _StepCompte(
          ref: ref,
          client: _client!,
          selected: _compteCreditSelectionne,
          onChangeClient: () => setState(() => _step = 1),
          onCompteSelected: (c) => setState(() => _compteCreditSelectionne = c),
          onContinue: () => setState(() => _step = 3),
        ),
      3 => _StepParametres(
          ref: ref,
          formKey: _formKey,
          typeCredit: _typeCredit,
          onTypeCreditChanged: (value) => setState(() => _typeCredit = value),
          miseCtrl: _miseCtrl,
          motifCtrl: _motifCtrl,
          client: _client!,
          compte: _compteCreditSelectionne!,
          loading: _loading,
          error: _error,
          onChangeClient: () => setState(() => _step = 1),
          onChangeCompte: () => setState(() => _step = 2),
          onChanged: () => setState(() {}),
          onSubmit: _submit,
        ),
      _ => const SizedBox(),
    };
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(creditRepositoryProvider).demandeCredit({
        'numeroCompte': _compteCreditSelectionne!.numeroCompte,
        'typeCredit': _typeCredit,
        'miseQuotidienne': double.parse(_miseCtrl.text.trim()),
        if (_motifCtrl.text.isNotEmpty)
          'motifDemande': _motifCtrl.text.trim(),
      });
      ref.invalidate(creditsProvider);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Demande de crédit soumise ✓'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

// ─── Étape 1 : Sélection du client ───────────────────────────────────────────

class _StepClient extends ConsumerStatefulWidget {
  final void Function(ClientModel) onSelected;
  const _StepClient({required this.onSelected});

  @override
  ConsumerState<_StepClient> createState() => _StepClientState();
}

class _StepClientState extends ConsumerState<_StepClient> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final clientsAsync = ref.watch(clientsProvider);

    return clientsAsync.when(
      loading: () => const Center(
          child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator())),
      error: (e, _) => ErrorView(message: e.toString()),
      data: (clients) {
        final filtered = _search.isEmpty
            ? clients
            : clients.where((c) =>
                c.fullName.toLowerCase().contains(_search) ||
                c.telephone.contains(_search) ||
                c.numeroClient.contains(_search)).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Rechercher un client…',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) => setState(() => _search = v.toLowerCase()),
            ),
            const SizedBox(height: 8),
            if (filtered.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text('Aucun résultat',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.textSecondary)),
              )
            else
              ...filtered.map((c) => ListTile(
                    onTap: () => widget.onSelected(c),
                    contentPadding: const EdgeInsets.symmetric(vertical: 2),
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primaryLight,
                      child: Text(c.fullName.isNotEmpty ? c.fullName[0].toUpperCase() : '?',
                          style: const TextStyle(
                              color: AppTheme.primary, fontWeight: FontWeight.w700)),
                    ),
                    title: Text(c.fullName,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('${c.numeroClient} • ${c.telephone}',
                        style: const TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right,
                        color: AppTheme.textSecondary),
                  )),
          ],
        );
      },
    );
  }
}

// ─── Étape 2 : Sélection / création compte CREDIT ────────────────────────────

class _StepCompte extends ConsumerStatefulWidget {
  final WidgetRef ref;
  final ClientModel client;
  final CompteModel? selected;
  final VoidCallback onChangeClient;
  final void Function(CompteModel) onCompteSelected;
  final VoidCallback onContinue;

  const _StepCompte({
    required this.ref,
    required this.client,
    required this.selected,
    required this.onChangeClient,
    required this.onCompteSelected,
    required this.onContinue,
  });

  @override
  ConsumerState<_StepCompte> createState() => _StepCompteState();
}

class _StepCompteState extends ConsumerState<_StepCompte> {
  bool _creating = false;
  CompteModel? _localSelected;

  @override
  void initState() {
    super.initState();
    _localSelected = widget.selected;
  }

  Future<void> _creerCompte() async {
    setState(() => _creating = true);
    try {
      await widget.ref.read(compteRepositoryProvider).createCompte({
        'clientId': widget.client.id,
        'typeCompte': 'CREDIT',
      });
      widget.ref.invalidate(comptesProvider);
      // Force rebuild du FutureBuilder
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Erreur : $e'),
            backgroundColor: AppTheme.error));
      }
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<CompteModel>>(
      future: widget.ref.read(compteRepositoryProvider)
          .getComptesByClient(widget.client.id),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: Padding(padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator()));
        }

        final comptesCredit = (snap.data ?? [])
            .where((c) => c.typeCompte == 'CREDIT' && c.statut == 'ACTIF')
            .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Client sélectionné
            _ClientTile(client: widget.client, onTap: widget.onChangeClient),
            const SizedBox(height: 16),

            if (comptesCredit.isEmpty) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.warning.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.info_outline, color: AppTheme.warning, size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Ce client n\'a pas de compte CREDIT actif.',
                            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _creating ? null : _creerCompte,
                      icon: _creating
                          ? const SizedBox(width: 16, height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.add),
                      label: Text(_creating
                          ? 'Création…'
                          : 'Créer un compte CREDIT'),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Text('Sélectionner le compte CREDIT',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary.withValues(alpha: 0.8))),
              const SizedBox(height: 8),
              ...comptesCredit.map((c) => _CompteCreditTile(
                    compte: c,
                    selected: _localSelected?.id == c.id,
                    onTap: () {
                      setState(() => _localSelected = c);
                      widget.onCompteSelected(c);
                    },
                  )),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _creating ? null : _creerCompte,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Nouveau compte CREDIT',
                    style: TextStyle(fontSize: 13)),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _localSelected == null ? null : widget.onContinue,
                child: const Text('Continuer'),
              ),
            ],
          ],
        );
      },
    );
  }
}

// ─── Étape 3 : Paramètres du crédit ──────────────────────────────────────────

class _StepParametres extends StatelessWidget {
  final WidgetRef ref;
  final GlobalKey<FormState> formKey;
  final String typeCredit;
  final ValueChanged<String> onTypeCreditChanged;
  final TextEditingController miseCtrl;
  final TextEditingController motifCtrl;
  final ClientModel client;
  final CompteModel compte;
  final bool loading;
  final String? error;
  final VoidCallback onChangeClient;
  final VoidCallback onChangeCompte;
  final VoidCallback onChanged;
  final VoidCallback onSubmit;

  const _StepParametres({
    required this.ref,
    required this.formKey,
    required this.typeCredit,
    required this.onTypeCreditChanged,
    required this.miseCtrl,
    required this.motifCtrl,
    required this.client,
    required this.compte,
    required this.loading,
    required this.error,
    required this.onChangeClient,
    required this.onChangeCompte,
    required this.onChanged,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final mise = double.tryParse(miseCtrl.text.trim());
    final jours = typeCredit == 'QUINZAINE' ? 15 : 30;
    final frais = mise == null
        ? null
        : mise * (typeCredit == 'QUINZAINE' ? 1 : 1.5);
    final montantPret = mise == null ? null : mise * jours;
    final total = montantPret == null || frais == null
        ? null
        : montantPret + frais;
    final nombreEcheances = jours + 1;

    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ClientTile(client: client, onTap: onChangeClient),
          const SizedBox(height: 8),
          _CompteResumeTile(compte: compte, onTap: onChangeCompte),
          const SizedBox(height: 20),

          DropdownButtonFormField<String>(
            value: typeCredit,
            decoration: const InputDecoration(
              labelText: 'Type de crédit *',
              prefixIcon: Icon(Icons.category_outlined),
            ),
            items: const [
              DropdownMenuItem(
                value: 'QUINZAINE',
                child: Text('Quinzaine'),
              ),
              DropdownMenuItem(
                value: 'MENSUEL',
                child: Text('Mensuel'),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                onTypeCreditChanged(value);
                onChanged();
              }
            },
          ),
          const SizedBox(height: 12),

          TextFormField(
            controller: miseCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Mise quotidienne (FCFA) *',
              prefixIcon: Icon(Icons.payments_outlined),
            ),
            onChanged: (_) => onChanged(),
            validator: (v) {
              if (v?.trim().isEmpty == true) return 'Requis';
              if ((double.tryParse(v!) ?? 0) <= 0) return 'Montant invalide';
              return null;
            },
          ),
          const SizedBox(height: 12),

          // Motif
          TextFormField(
            controller: motifCtrl,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Motif de la demande',
              prefixIcon: Icon(Icons.description_outlined),
            ),
          ),

          if (montantPret != null && frais != null && total != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppTheme.primary.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calculate_outlined,
                      color: AppTheme.primary, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Simulation automatique',
                            style: TextStyle(
                                fontSize: 11, color: AppTheme.textSecondary)),
                        Text(
                          typeCredit == 'QUINZAINE'
                              ? 'Crédit quinzaine'
                              : 'Crédit mensuel',
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Prêt : ${Formatters.currency(montantPret)} • '
                          'Frais : ${Formatters.currency(frais)}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'Total : ${Formatters.currency(total)}\n'
                    '$nombreEcheances échéances',
                    style: const TextStyle(
                        fontSize: 11, color: AppTheme.textSecondary),
                    textAlign: TextAlign.right,
                  ),
                ],
              ),
            ),
          ],

          // Erreur
          if (error != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline,
                      color: AppTheme.error, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(error!,
                        style: const TextStyle(
                            color: AppTheme.error, fontSize: 12)),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: loading ? null : onSubmit,
            icon: loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.send_outlined),
            label: Text(loading ? 'Envoi…' : 'Soumettre la demande'),
          ),
        ],
      ),
    );
  }
}

// ─── Widgets partagés du sheet ────────────────────────────────────────────────

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 4),
      child: Center(
        child: Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: AppTheme.border,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  final int step;
  final VoidCallback onClose;

  const _SheetHeader({required this.step, required this.onClose});

  static const _labels = ['Client', 'Compte', 'Paramètres'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Nouvelle demande de crédit',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: onClose,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Indicateur d'étapes
          Row(
            children: List.generate(_labels.length, (i) {
              final active = i + 1 == step;
              final done   = i + 1 < step;
              final color  = (active || done) ? AppTheme.primary : AppTheme.border;

              return Expanded(
                child: Row(
                  children: [
                    if (i > 0)
                      Expanded(
                        child: Container(height: 2,
                            color: done ? AppTheme.primary : AppTheme.border),
                      ),
                    Column(
                      children: [
                        Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle, color: color),
                          child: Center(
                            child: done
                                ? const Icon(Icons.check,
                                    color: Colors.white, size: 14)
                                : Text('${i + 1}',
                                    style: TextStyle(
                                      color: active
                                          ? Colors.white
                                          : AppTheme.textSecondary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    )),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(_labels[i],
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: active
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: active
                                    ? AppTheme.primary
                                    : AppTheme.textSecondary)),
                      ],
                    ),
                    if (i < _labels.length - 1)
                      const Expanded(child: SizedBox()),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

/// Tuile client (cliquable pour revenir à l'étape 1)
class _ClientTile extends StatelessWidget {
  final ClientModel client;
  final VoidCallback onTap;

  const _ClientTile({required this.client, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.primaryLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppTheme.primary,
              child: Text(
                client.fullName.isNotEmpty
                    ? client.fullName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(client.fullName,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, color: AppTheme.primary)),
                  Text(client.numeroClient,
                      style: const TextStyle(
                          fontSize: 11, color: AppTheme.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.edit_outlined, size: 16, color: AppTheme.primary),
          ],
        ),
      ),
    );
  }
}

/// Tuile compte CREDIT sélectionnable
class _CompteCreditTile extends StatelessWidget {
  final CompteModel compte;
  final bool selected;
  final VoidCallback onTap;

  const _CompteCreditTile({
    required this.compte,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
            color: selected ? AppTheme.primary : Colors.transparent, width: 2),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: selected ? AppTheme.primary : AppTheme.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.credit_card,
                    color: selected ? Colors.white : AppTheme.primary,
                    size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(compte.numeroCompte,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontFamily: 'monospace',
                            fontSize: 13)),
                    Text('Solde : ${Formatters.currency(compte.solde)}',
                        style: const TextStyle(
                            fontSize: 11, color: AppTheme.textSecondary)),
                  ],
                ),
              ),
              if (selected)
                const Icon(Icons.check_circle,
                    color: AppTheme.primary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

/// Résumé compact du compte sélectionné (étape 3)
class _CompteResumeTile extends StatelessWidget {
  final CompteModel compte;
  final VoidCallback onTap;

  const _CompteResumeTile({required this.compte, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.primaryLight,
          borderRadius: BorderRadius.circular(8),
          border:
              Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            const Icon(Icons.credit_card, size: 16, color: AppTheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(compte.numeroCompte,
                  style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary)),
            ),
            const Icon(Icons.edit_outlined, size: 14, color: AppTheme.primary),
          ],
        ),
      ),
    );
  }
}
