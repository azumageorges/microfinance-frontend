import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
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
  final _tauxCtrl = TextEditingController();
  final _dureeCtrl = TextEditingController();
  final _montantCibleCtrl = TextEditingController();
  final _representantCtrl = TextEditingController();

  String _typeCompte = 'EPARGNE';
  ClientModel? _clientSelectionne;
  bool _loading = false;
  String? _error;

  static const _types = {
    'EPARGNE': 'Épargne',
    'DAT':     'Dépôt à terme (DAT)',
    'CREDIT':  'Crédit',
    'ACHAT':   'Compte achat',
    'ENFANT':  'Compte enfant',
    'BLOQUE':  'Compte bloqué',
  };

  @override
  void initState() {
    super.initState();
    if (widget.clientId != null) _chargerClient(widget.clientId!);
  }

  Future<void> _chargerClient(int id) async {
    try {
      final client =
          await ref.read(clientRepositoryProvider).getClientById(id);
      if (mounted) setState(() => _clientSelectionne = client);
    } catch (_) {}
  }

  @override
  void dispose() {
    _montantCtrl.dispose();
    _tauxCtrl.dispose();
    _dureeCtrl.dispose();
    _montantCibleCtrl.dispose();
    _representantCtrl.dispose();
    super.dispose();
  }

  bool get _needsTaux =>
      _typeCompte == 'DAT' || _typeCompte == 'BLOQUE';
  bool get _needsDuree =>
      _typeCompte == 'DAT' || _typeCompte == 'BLOQUE';
  bool get _needsCible => _typeCompte == 'ACHAT';
  bool get _needsRepresentant => _typeCompte == 'ENFANT';

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_clientSelectionne == null) {
      setState(() => _error = 'Veuillez sélectionner un client');
      return;
    }
    setState(() { _loading = true; _error = null; });

    try {
      final data = <String, dynamic>{
        'clientId': _clientSelectionne!.id,
        'typeCompte': _typeCompte,
        if (_montantCtrl.text.isNotEmpty)
          'montantInitial': double.parse(_montantCtrl.text),
        if (_tauxCtrl.text.isNotEmpty)
          'tauxInteret': double.parse(_tauxCtrl.text),
        if (_dureeCtrl.text.isNotEmpty)
          'dureeEnMois': int.parse(_dureeCtrl.text),
        if (_montantCibleCtrl.text.isNotEmpty)
          'montantCible': double.parse(_montantCibleCtrl.text),
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
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Client
            _Section(title: 'Client', children: [
              _clientSelectionne == null
                  ? OutlinedButton.icon(
                      onPressed: () => _selectionnerClient(),
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
                          style:
                              const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle:
                          Text(_clientSelectionne!.numeroClient),
                      trailing: TextButton(
                        onPressed: () =>
                            setState(() => _clientSelectionne = null),
                        child: const Text('Changer'),
                      ),
                    ),
            ]),
            const SizedBox(height: 12),

            // Type de compte
            _Section(title: 'Type de compte', children: [
              DropdownButtonFormField<String>(
                // ignore: deprecated_member_use
                value: _typeCompte,
                decoration:
                    const InputDecoration(labelText: 'Sélectionnez le type'),
                items: _types.entries
                    .map((e) => DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _typeCompte = v!),
              ),
            ]),
            const SizedBox(height: 12),

            // Paramètres selon le type
            _Section(title: 'Paramètres', children: [
              // Montant initial — tous types sauf CREDIT (pas de dépôt à l'ouverture)
              if (_typeCompte != 'CREDIT')
                _NumField(
                  label: 'Montant initial (FCFA)',
                  controller: _montantCtrl,
                  hint: '0',
                ),
              // Info spéciale compte CREDIT
              if (_typeCompte == 'CREDIT')
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppTheme.primary.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline,
                          color: AppTheme.primary, size: 18),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Un compte CREDIT ouvre le droit à une demande de crédit. '
                          'Le solde sera alimenté lors du déblocage des fonds après validation.',
                          style: TextStyle(
                              fontSize: 12, color: AppTheme.primary),
                        ),
                      ),
                    ],
                  ),
                ),
              if (_needsTaux) ...[
                const SizedBox(height: 12),
                _NumField(
                  label: 'Taux d\'intérêt (%)',
                  controller: _tauxCtrl,
                  hint: 'Ex: 5.5',
                  isDouble: true,
                ),
              ],
              if (_needsDuree) ...[
                const SizedBox(height: 12),
                _NumField(
                  label: 'Durée (mois)',
                  controller: _dureeCtrl,
                  hint: 'Ex: 12',
                ),
              ],
              if (_needsCible) ...[
                const SizedBox(height: 12),
                _NumField(
                  label: 'Montant cible (FCFA)',
                  controller: _montantCibleCtrl,
                  hint: 'Ex: 500000',
                ),
              ],
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
                      ? (v) => v?.trim().isEmpty == true ? 'Requis' : null
                      : null,
                ),
              ],
            ]),

            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: AppTheme.error, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_error!,
                          style:
                              const TextStyle(color: AppTheme.error, fontSize: 13)),
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
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
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

  const _NumField({
    required this.label,
    required this.controller,
    this.hint,
    this.isDouble = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType:
          isDouble ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.number,
      inputFormatters: isDouble
          ? [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*'))]
          : [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixText: label.contains('%') ? '%' : (label.contains('FCFA') ? 'FCFA' : null),
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
                  style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
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
                      style:
                          TextStyle(color: AppTheme.textSecondary)),
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
                          style: const TextStyle(
                              fontWeight: FontWeight.w600)),
                      subtitle: Text(
                          '${c.numeroClient} • ${c.telephone}'),
                    );
                  },
                ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
