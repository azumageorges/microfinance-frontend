import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../providers/providers.dart';
import '../../widgets/loading_overlay.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/app_app_bar.dart';

class ComptesListScreen extends ConsumerStatefulWidget {
  const ComptesListScreen({super.key});

  @override
  ConsumerState<ComptesListScreen> createState() => _ComptesListScreenState();
}

class _ComptesListScreenState extends ConsumerState<ComptesListScreen> {
  String _search = '';
  String _filterType = 'TOUS';

  static const _types = [
    'TOUS', 'EPARGNE', 'DAT', 'CREDIT', 'ACHAT', 'ENFANT', 'BLOQUE'
  ];

  static const _typeLabels = {
    'TOUS': 'Tous',
    'EPARGNE': 'Épargne',
    'DAT': 'DAT',
    'CREDIT': 'Crédit',
    'ACHAT': 'Achat',
    'ENFANT': 'Enfant',
    'BLOQUE': 'Bloqué',
  };

  @override
  Widget build(BuildContext context) {
    final comptesAsync = ref.watch(comptesProvider);
    final auth = ref.watch(authProvider);
    final canCreate =
        auth?.isAdmin == true || auth?.isGestionnaire == true;

    return Scaffold(
      appBar: AppAppBar(
        title: 'Comptes',
        showSearch: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(comptesProvider),
          ),
        ],
      ),
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/comptes/nouveau'),
              icon: const Icon(Icons.add),
              label: const Text('Nouveau compte'),
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
            )
          : null,
      body: Column(
        children: [
          // Filtres
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Rechercher par numéro, client...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _search.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _search = ''),
                      )
                    : null,
              ),
              onChanged: (v) => setState(() => _search = v.toLowerCase()),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: _types.map((type) {
                final isSelected = _filterType == type;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(_typeLabels[type] ?? type),
                    selected: isSelected,
                    onSelected: (_) =>
                        setState(() => _filterType = type),
                    selectedColor: AppTheme.primaryLight,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? AppTheme.primary
                          : AppTheme.textPrimary,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),

          Expanded(
            child: comptesAsync.when(
              loading: () => const LoadingOverlay(),
              error: (err, _) => ErrorView(
                message: err.toString(),
                onRetry: () => ref.invalidate(comptesProvider),
              ),
              data: (comptes) {
                final filtered = comptes.where((c) {
                  final matchType =
                      _filterType == 'TOUS' || c.typeCompte == _filterType;
                  final matchSearch = _search.isEmpty ||
                      c.numeroCompte.toLowerCase().contains(_search) ||
                      c.clientFullName.toLowerCase().contains(_search);
                  return matchType && matchSearch;
                }).toList();

                if (filtered.isEmpty) {
                  return const EmptyView(
                    message: 'Aucun compte trouvé',
                    icon: Icons.account_balance_wallet_outlined,
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(comptesProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (ctx, i) {
                      final compte = filtered[i];
                      return Card(
                        child: InkWell(
                          onTap: () => context
                              .push('/comptes/${compte.numeroCompte}'),
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
                                      child: const Icon(
                                        Icons.account_balance_wallet,
                                        color: AppTheme.primary,
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
                                            compte.typeLabel,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                            ),
                                          ),
                                          Text(
                                            compte.numeroCompte,
                                            style: const TextStyle(
                                              fontSize: 12,
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
                                          Formatters.currency(compte.solde),
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: AppTheme.textPrimary,
                                          ),
                                        ),
                                        StatusBadge(status: compte.statut),
                                      ],
                                    ),
                                  ],
                                ),
                                const Divider(height: 16),
                                Row(
                                  children: [
                                    const Icon(Icons.person_outline,
                                        size: 14,
                                        color: AppTheme.textSecondary),
                                    const SizedBox(width: 4),
                                    Text(
                                      compte.clientFullName,
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.textSecondary),
                                    ),
                                    if (compte.dateOuverture != null) ...[
                                      const Spacer(),
                                      Text(
                                        'Ouvert le ${Formatters.date(compte.dateOuverture)}',
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: AppTheme.textSecondary),
                                      ),
                                    ],
                                  ],
                                ),
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
}
class _CreateCompteSheet extends ConsumerStatefulWidget {
  const _CreateCompteSheet();

  @override
  ConsumerState<_CreateCompteSheet> createState() =>
      _CreateCompteSheetState();
}

class _CreateCompteSheetState
    extends ConsumerState<_CreateCompteSheet> {
  final _formKey = GlobalKey<FormState>();
  final _clientIdCtrl = TextEditingController();
  final _montantCtrl = TextEditingController();
  String _typeCompte = 'EPARGNE';
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _clientIdCtrl.dispose();
    _montantCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Nouveau compte',
                style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              // ignore: deprecated_member_use
              value: _typeCompte,
              decoration: const InputDecoration(labelText: 'Type de compte'),
              items: const [
                DropdownMenuItem(value: 'EPARGNE', child: Text('Épargne')),
                DropdownMenuItem(
                    value: 'DAT', child: Text('Dépôt à terme')),
                DropdownMenuItem(value: 'ACHAT', child: Text('Achat')),
                DropdownMenuItem(value: 'ENFANT', child: Text('Enfant')),
              ],
              onChanged: (v) => setState(() => _typeCompte = v!),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _clientIdCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'ID du client *'),
              validator: (v) =>
                  v?.trim().isEmpty == true ? 'Requis' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _montantCtrl,
              keyboardType: TextInputType.number,
              decoration:
                  const InputDecoration(labelText: 'Montant initial (FCFA)'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!,
                  style: const TextStyle(color: AppTheme.error)),
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Créer le compte'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(compteRepositoryProvider).createCompte({
        'clientId': int.parse(_clientIdCtrl.text.trim()),
        'typeCompte': _typeCompte,
        if (_montantCtrl.text.isNotEmpty)
          'montantInitial': double.parse(_montantCtrl.text.trim()),
      });
      ref.invalidate(comptesProvider);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
