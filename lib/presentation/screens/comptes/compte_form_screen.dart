import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/client_model.dart';
import '../../../providers/providers.dart';

class CompteFormScreen extends ConsumerStatefulWidget {
  /// Si fourni, le client est pré-sélectionné
  final int? clientId;

  const CompteFormScreen({super.key, this.clientId});

  @override
  ConsumerState<CompteFormScreen> createState() => _CompteFormScreenState();
}

class _CompteFormScreenState extends ConsumerState<CompteFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _montantCtrl = TextEditingController();
  final _tauxCtrl    = TextEditingController();
  final _dureeCtrl   = TextEditingController();
  final _representantCtrl = TextEditingController();

  String _typeCompte = 'EPARGNE';
  ClientModel? _clientSelectionne;
  bool _loading = false;
  String? _error;

  // ── Résultat de simulation DAT (calculé en temps réel) ─────────────────────
  double? _simCapital;
  double? _simTaux;
  int?    _simDuree;
  double? _simInterets;
  double? _simMontantFinal;

  static const _types = {
    'EPARGNE': 'Épargne',
    'DAT':     'Dépôt à terme (DAT)',
    'CREDIT':  'Crédit',
    'ENFANT':  'Compte enfant',
  };

  @override
  void initState() {
    super.initState();
    if (widget.clientId != null) _chargerClient(widget.clientId!);
    // Écouter les changements en temps réel pour le calcul DAT
    _montantCtrl.addListener(_calculerDAT);
    _tauxCtrl.addListener(_calculerDAT);
    _dureeCtrl.addListener(_calculerDAT);
  }

  Future<void> _chargerClient(int id) async {
    try {
      final client = await ref.read(clientRepositoryProvider).getClientById(id);
      if (mounted) setState(() => _clientSelectionne = client);
    } catch (_) {}
  }

  @override
  void dispose() {
    _montantCtrl.removeListener(_calculerDAT);
    _tauxCtrl.removeListener(_calculerDAT);
    _dureeCtrl.removeListener(_calculerDAT);
    _montantCtrl.dispose();
    _tauxCtrl.dispose();
    _dureeCtrl.dispose();
    _representantCtrl.dispose();
    super.dispose();
  }

  // ── Calcul automatique des intérêts DAT ─────────────────────────────────────
  // Formule : intérêts = capital × (taux/100) × (duréeMois/12)
  // Exemple : 100 000 × 8% × 12 mois = 8 000  → total = 108 000
  //           100 000 × 8% × 6  mois = 4 000  → total = 104 000
  void _calculerDAT() {
    if (_typeCompte != 'DAT') return;
    final capital = double.tryParse(_montantCtrl.text.trim());
    final taux    = double.tryParse(_tauxCtrl.text.trim());
    final duree   = int.tryParse(_dureeCtrl.text.trim());

    if (capital != null && capital > 0 && taux != null && taux > 0 && duree != null && duree > 0) {
      final interets    = capital * (taux / 100) * (duree / 12);
      final montantFinal = capital + interets;
      if (mounted) {
        setState(() {
          _simCapital     = capital;
          _simTaux        = taux;
          _simDuree       = duree;
          _simInterets    = interets;
          _simMontantFinal = montantFinal;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _simCapital     = null;
          _simTaux        = null;
          _simDuree       = null;
          _simInterets    = null;
          _simMontantFinal = null;
        });
      }
    }
  }

  bool get _needsTaux          => _typeCompte == 'DAT';
  bool get _needsDuree         => _typeCompte == 'DAT';
  bool get _needsRepresentant  => _typeCompte == 'ENFANT';
  bool get _needsMontantInitial =>
      _typeCompte == 'EPARGNE' || _typeCompte == 'ENFANT' || _typeCompte == 'DAT';

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_clientSelectionne == null) {
      setState(() => _error = 'Veuillez sélectionner un client');
      return;
    }

    setState(() { _loading = true; _error = null; });

    try {
      final data = <String, dynamic>{
        'clientId':   _clientSelectionne!.id,
        'typeCompte': _typeCompte,
        if (_montantCtrl.text.isNotEmpty)
          'montantInitial': double.parse(_montantCtrl.text),
        if (_tauxCtrl.text.isNotEmpty)
          'tauxInteret': double.parse(_tauxCtrl.text),
        if (_dureeCtrl.text.isNotEmpty)
          'dureeEnMois': int.parse(_dureeCtrl.text),
        if (_representantCtrl.text.isNotEmpty)
          'representantLegal': _representantCtrl.text.trim(),
      };

      await ref.read(compteRepositoryProvider).createCompte(data);
      ref.invalidate(comptesProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Compte créé avec succès'),
            backgroundColor: AppTheme.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouveau compte',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Client ────────────────────────────────────────────────────────
            _Section(title: 'Client', children: [
              _clientSelectionne == null
                  ? OutlinedButton.icon(
                      onPressed: _selectionnerClient,
                      icon: const Icon(Icons.person_search),
                      label: const Text('Sélectionner un client'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                    )
                  : ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.primaryLight,
                        child: Text(
                          _clientSelectionne!.fullName[0].toUpperCase(),
                          style: const TextStyle(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                      title: Text(_clientSelectionne!.fullName,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(_clientSelectionne!.numeroClient),
                      trailing: TextButton(
                        onPressed: () => setState(() => _clientSelectionne = null),
                        child: const Text('Changer'),
                      ),
                    ),
            ]),
            const SizedBox(height: 12),

            // ── Type de compte ─────────────────────────────────────────────────
            _Section(title: 'Type de compte', children: [
              DropdownButtonFormField<String>(
                value: _typeCompte,
                decoration: const InputDecoration(labelText: 'Sélectionnez le type'),
                items: _types.entries
                    .map<DropdownMenuItem<String>>((e) => DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value),
                        ))
                    .toList(),
                onChanged: (v) {
                  setState(() {
                    _typeCompte = v!;
                    // Réinitialiser la simulation quand on change de type
                    _simCapital = _simTaux = _simDuree =
                        _simInterets = _simMontantFinal = null;
                  });
                  _calculerDAT();
                },
              ),
            ]),
            const SizedBox(height: 12),

            // ── Paramètres ─────────────────────────────────────────────────────
            _Section(title: 'Paramètres', children: [
              // Montant initial
              if (_needsMontantInitial) ...[
                _NumField(
                  label: _typeCompte == 'DAT'
                      ? 'Capital à déposer (FCFA) *'
                      : 'Montant initial (FCFA) *',
                  controller: _montantCtrl,
                  hint: _typeCompte == 'DAT' ? 'Ex: 100 000' : 'Min: 5 000',
                  isDouble: true,
                  validator: Validators.combine([
                    Validators.required(),
                    // positif (strictement > 0)
                    Validators.positiveNumber(
                      isRequired: false,
                      messageInvalid: 'Montant invalide',
                      min: 0,
                    ),
                    (v) {
                      final value = double.tryParse((v ?? '').trim());
                      if (value == null) return null;
                      if ((_typeCompte == 'EPARGNE' || _typeCompte == 'ENFANT') &&
                          value < 5000) {
                        return 'Minimum 5 000 FCFA';
                      }
                      return null;
                    },
                  ]),
                ),
              ],

              // Info spéciale compte CREDIT
              if (_typeCompte == 'CREDIT')
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, color: AppTheme.primary, size: 18),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Un compte CREDIT ouvre le droit à une demande de crédit. '
                          'Le solde sera alimenté lors du déblocage des fonds après validation.',
                          style: TextStyle(fontSize: 12, color: AppTheme.primary),
                        ),
                      ),
                    ],
                  ),
                ),

              // Taux d'intérêt (DAT)
              if (_needsTaux) ...[
                const SizedBox(height: 12),
                _NumField(
                  label: 'Taux d\'intérêt annuel (%)',
                  controller: _tauxCtrl,
                  hint: 'Ex: 8',
                  isDouble: true,
                  validator: Validators.combine([
                    Validators.required(),
                    Validators.positiveNumber(
                      isRequired: false,
                      min: 0,
                      max: 100,
                      messageInvalid: 'Taux entre 0 et 100',
                    ),
                  ]),
                ),
              ],

              // Durée (DAT)
              if (_needsDuree) ...[
                const SizedBox(height: 12),
                _NumField(
                  label: 'Durée (mois) *',
                  controller: _dureeCtrl,
                  hint: 'Min: 12',
                  validator: Validators.combine([
                    Validators.required(),
                    Validators.integer(
                      isRequired: false,
                      min: 12,
                      max: 360,
                      messageInvalid: 'Durée min. 12 mois',
                    ),
                  ]),
                ),
              ],

              // Représentant légal (ENFANT)
              if (_needsRepresentant) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _representantCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Représentant légal *',
                    hintText: 'Nom du parent ou tuteur',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: _needsRepresentant
                      ? Validators.combine([
                          Validators.required(),
                          Validators.maxLength(100,
                              message: 'Max 100 caractères'),
                        ])
                      : null,
                ),
              ],
            ]),

            // ── Récapitulatif DAT en temps réel ───────────────────────────────
            if (_typeCompte == 'DAT') ...[
              const SizedBox(height: 12),
              _DatSimulationCard(
                capital:      _simCapital,
                taux:         _simTaux,
                duree:        _simDuree,
                interets:     _simInterets,
                montantFinal: _simMontantFinal,
              ),
            ],

            // ── Erreur ─────────────────────────────────────────────────────────
            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppTheme.error, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_error!,
                          style: const TextStyle(color: AppTheme.error, fontSize: 13)),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Créer le compte'),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _selectionnerClient() {
    final clientsAsync = ref.read(clientsProvider);
    clientsAsync.whenData((clients) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => _ClientPickerSheet(
          clients: clients,
          onSelected: (c) {
            setState(() => _clientSelectionne = c);
            Navigator.pop(context);
          },
        ),
      );
    });
  }
}

// ─── Carte de simulation DAT ─────────────────────────────────────────────────

class _DatSimulationCard extends StatelessWidget {
  final double? capital;
  final double? taux;
  final int?    duree;
  final double? interets;
  final double? montantFinal;

  const _DatSimulationCard({
    this.capital,
    this.taux,
    this.duree,
    this.interets,
    this.montantFinal,
  });

  @override
  Widget build(BuildContext context) {
    final hasData = capital != null && taux != null && duree != null &&
        interets != null && montantFinal != null;

    return Card(
      color: hasData
          ? AppTheme.success.withValues(alpha: 0.06)
          : Colors.grey[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: hasData
              ? AppTheme.success.withValues(alpha: 0.4)
              : Colors.grey.withValues(alpha: 0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calculate_outlined,
                  color: hasData ? AppTheme.success : AppTheme.textSecondary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Simulation — Rendement à l\'échéance',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: hasData ? AppTheme.success : AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (!hasData)
              const Text(
                'Renseignez le capital, le taux annuel et la durée\npour voir le calcul en temps réel.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              )
            else ...[
              _SimRow(
                label: 'Capital investi',
                value: Formatters.currency(capital!),
                bold: false,
              ),
              _SimRow(
                label: 'Taux annuel',
                value: '${taux!.toStringAsFixed(2)} %',
                bold: false,
              ),
              _SimRow(
                label: 'Durée',
                value: '$duree mois',
                bold: false,
              ),
              const Divider(height: 20),
              _SimRow(
                label: 'Intérêts gagnés',
                value: '+ ${Formatters.currency(interets!)}',
                color: AppTheme.success,
                bold: false,
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Montant total à percevoir',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      Formatters.currency(montantFinal!),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.success,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SimRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  final bool bold;

  const _SimRow({
    required this.label,
    required this.value,
    this.color,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              color: color ?? AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section wrapper ──────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary)),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

// ─── Champ numérique ─────────────────────────────────────────────────────────

class _NumField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hint;
  final bool isDouble;
  final String? Function(String?)? validator;

  const _NumField({
    required this.label,
    required this.controller,
    this.hint,
    this.isDouble = false,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: isDouble
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.number,
      inputFormatters: isDouble
          ? [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*'))]
          : [FilteringTextInputFormatter.digitsOnly],
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixText: label.contains('%')
            ? '%'
            : (label.contains('FCFA') ? 'FCFA' : null),
      ),
    );
  }
}

// ─── Sélecteur de client ──────────────────────────────────────────────────────

class _ClientPickerSheet extends StatefulWidget {
  final List<ClientModel> clients;
  final void Function(ClientModel) onSelected;

  const _ClientPickerSheet({
    required this.clients,
    required this.onSelected,
  });

  @override
  State<_ClientPickerSheet> createState() => _ClientPickerSheetState();
}

class _ClientPickerSheetState extends State<_ClientPickerSheet> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final filtered = _search.isEmpty
        ? widget.clients
        : widget.clients
            .where((c) =>
                c.fullName.toLowerCase().contains(_search) ||
                c.telephone.contains(_search) ||
                c.numeroClient.contains(_search))
            .toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              const Text('Sélectionner un client',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: TextField(
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Rechercher...',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (v) => setState(() => _search = v.toLowerCase()),
          ),
        ),
        Flexible(
          child: filtered.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('Aucun client trouvé',
                      style: TextStyle(color: AppTheme.textSecondary)),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: filtered.length,
                  itemBuilder: (_, i) {
                    final c = filtered[i];
                    return ListTile(
                      onTap: () => widget.onSelected(c),
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.primaryLight,
                        child: Text(
                          c.fullName.isNotEmpty
                              ? c.fullName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                      title: Text(c.fullName,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('${c.numeroClient} • ${c.telephone}'),
                    );
                  },
                ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
