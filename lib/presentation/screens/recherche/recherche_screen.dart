import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/providers.dart';
import '../../widgets/client_avatar.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/loading_overlay.dart';

// Nombre de résultats affichés avant "Voir plus"
const _kPageSize = 5;

class RechercheScreen extends ConsumerStatefulWidget {
  const RechercheScreen({super.key});

  @override
  ConsumerState<RechercheScreen> createState() => _RechercheScreenState();
}

class _RechercheScreenState extends ConsumerState<RechercheScreen> {
  final _ctrl = TextEditingController();
  String _query = '';

  // Limites d'affichage par section (augmente à chaque "Voir plus")
  int _limitClients = _kPageSize;
  int _limitComptes = _kPageSize;
  int _limitCredits = _kPageSize;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onQueryChanged(String v) {
    setState(() {
      _query = v.trim();
      // Réinitialise les limites à chaque nouvelle recherche
      _limitClients = _kPageSize;
      _limitComptes = _kPageSize;
      _limitCredits = _kPageSize;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Nom, téléphone, numéro de compte, référence crédit...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: AppTheme.textSecondary),
          ),
          style: const TextStyle(fontSize: 16),
          onChanged: _onQueryChanged,
        ),
        actions: [
          if (_query.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _ctrl.clear();
                _onQueryChanged('');
              },
            ),
        ],
      ),
      body: _query.length < 2 ? _buildHints() : _buildResults(),
    );
  }

  Widget _buildHints() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search,
              size: 56,
              color: AppTheme.textSecondary.withValues(alpha: 0.3)),
          const SizedBox(height: 12),
          const Text(
            'Saisissez au moins 2 caractères\npour lancer la recherche',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            children: [
              _HintChip(label: 'Clients', icon: Icons.people_outline),
              _HintChip(label: 'Comptes', icon: Icons.account_balance_wallet_outlined),
              _HintChip(label: 'Crédits', icon: Icons.credit_score_outlined),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    final clientsAsync = ref.watch(clientsProvider);
    final comptesAsync = ref.watch(comptesProvider);
    final creditsAsync = ref.watch(creditsProvider);
    final q = _query.toLowerCase();

    // Gestion des états de chargement/erreur globaux
    if (clientsAsync.isLoading || comptesAsync.isLoading || creditsAsync.isLoading) {
      return const LoadingOverlay();
    }

    final clients = clientsAsync.valueOrNull ?? [];
    final comptes = comptesAsync.valueOrNull ?? [];
    final credits = creditsAsync.valueOrNull ?? [];

    final matchClients = clients.where((c) =>
        c.fullName.toLowerCase().contains(q) ||
        c.telephone.contains(q) ||
        c.numeroClient.toLowerCase().contains(q) ||
        (c.email?.toLowerCase().contains(q) ?? false)).toList();

    final matchComptes = comptes.where((c) =>
        c.numeroCompte.toLowerCase().contains(q) ||
        c.clientFullName.toLowerCase().contains(q)).toList();

    final matchCredits = credits.where((c) =>
        c.referenceCredit.toLowerCase().contains(q) ||
        (c.nomClient?.toLowerCase().contains(q) ?? false) ||
        c.numeroCompte.toLowerCase().contains(q)).toList();

    final total =
        matchClients.length + matchComptes.length + matchCredits.length;

    if (total == 0) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off,
                size: 48,
                color: AppTheme.textSecondary.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            Text('Aucun résultat pour "$_query"',
                style: const TextStyle(color: AppTheme.textSecondary)),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Clients ──────────────────────────────────────────────────
        if (matchClients.isNotEmpty) ...[
          _SectionHeader(label: 'Clients', count: matchClients.length),
          const SizedBox(height: 8),
          ...matchClients.take(_limitClients).map<Widget>((c) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  onTap: () => context.push('/clients/${c.id}'),
                  leading: ClientAvatar(
                      fullName: c.fullName, cheminPhoto: c.cheminPhoto),
                  title: Text(c.fullName,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('${c.numeroClient} • ${c.telephone}',
                      style: const TextStyle(fontSize: 12)),
                  trailing: StatusBadge(status: c.statut),
                ),
              )),
          if (matchClients.length > _limitClients)
            _VoirPlusButton(
              restant: matchClients.length - _limitClients,
              onTap: () => setState(() => _limitClients += _kPageSize),
            ),
          const SizedBox(height: 8),
        ],

        // ── Comptes ───────────────────────────────────────────────────
        if (matchComptes.isNotEmpty) ...[
          _SectionHeader(label: 'Comptes', count: matchComptes.length),
          const SizedBox(height: 8),
          ...matchComptes.take(_limitComptes).map<Widget>((c) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  onTap: () => context.push('/comptes/${c.numeroCompte}'),
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.account_balance_wallet,
                        color: AppTheme.primary, size: 20),
                  ),
                  title: Text(c.typeLabel,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('${c.numeroCompte} • ${c.clientFullName}',
                      style: const TextStyle(fontSize: 12)),
                  trailing: StatusBadge(status: c.statut),
                ),
              )),
          if (matchComptes.length > _limitComptes)
            _VoirPlusButton(
              restant: matchComptes.length - _limitComptes,
              onTap: () => setState(() => _limitComptes += _kPageSize),
            ),
          const SizedBox(height: 8),
        ],

        // ── Crédits ───────────────────────────────────────────────────
        if (matchCredits.isNotEmpty) ...[
          _SectionHeader(label: 'Crédits', count: matchCredits.length),
          const SizedBox(height: 8),
          ...matchCredits.take(_limitCredits).map<Widget>((c) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  onTap: () =>
                      context.push('/credits/${c.referenceCredit}'),
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.credit_score,
                        color: AppTheme.primary, size: 20),
                  ),
                  title: Text(c.referenceCredit,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontFamily: 'monospace',
                          fontSize: 13)),
                  subtitle: Text(
                      '${c.nomClient ?? ''} • ${c.numeroCompte}',
                      style: const TextStyle(fontSize: 12)),
                  trailing: StatusBadge(status: c.statut, label: c.statutLabel),
                ),
              )),
          if (matchCredits.length > _limitCredits)
            _VoirPlusButton(
              restant: matchCredits.length - _limitCredits,
              onTap: () => setState(() => _limitCredits += _kPageSize),
            ),
        ],
      ],
    );
  }
}

// ─── Widgets internes ─────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  final int count;

  const _SectionHeader({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.textSecondary)),
        const SizedBox(width: 6),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: AppTheme.primaryLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppTheme.primary),
          ),
        ),
      ],
    );
  }
}

class _VoirPlusButton extends StatelessWidget {
  final int restant;
  final VoidCallback onTap;

  const _VoirPlusButton({required this.restant, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.expand_more, size: 18),
      label: Text(
        'Voir $restant résultat${restant > 1 ? 's' : ''} de plus',
        style: const TextStyle(fontSize: 13),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 4),
        minimumSize: const Size(double.infinity, 36),
      ),
    );
  }
}

class _HintChip extends StatelessWidget {
  final String label;
  final IconData icon;

  const _HintChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 16, color: AppTheme.primary),
      label: Text(label,
          style: const TextStyle(
              fontSize: 12, color: AppTheme.primary)),
      backgroundColor: AppTheme.primaryLight,
      side: BorderSide.none,
    );
  }
}
