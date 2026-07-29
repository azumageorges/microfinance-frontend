import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/carte_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../providers/providers.dart';
import '../../widgets/client_avatar.dart';
import '../../widgets/loading_overlay.dart';
import '../../widgets/status_badge.dart';
import 'beneficiaires_screen.dart';

class ClientDetailScreen extends ConsumerWidget {
  final int clientId;

  const ClientDetailScreen({super.key, required this.clientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientAsync = ref.watch(_clientProvider(clientId));
    final comptesAsync = ref.watch(_clientComptesProvider(clientId));
    final auth = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détail client',
            style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          // Bouton carte — Gestionnaire + Admin uniquement
          if (auth?.isAdmin == true || auth?.isGestionnaire == true)
            clientAsync.when(
              data: (client) => IconButton(
                icon: const Icon(Icons.credit_card_outlined),
                tooltip: 'Carte membre',
                onPressed: () => context.push(
                  '/clients/$clientId/carte',
                  extra: client,
                ),
              ),
              loading: () => const SizedBox(),
              error: (_, _) => const SizedBox(),
            ),
          // Bouton modifier — Admin + Agent terrain
          if (auth?.isAdmin == true || auth?.isAgentTerrain == true || auth?.isGestionnaire == true)
            clientAsync.when(
              data: (_) => IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Modifier',
                onPressed: () => context.push('/clients/$clientId/modifier'),
              ),
              loading: () => const SizedBox(),
              error: (_, _) => const SizedBox(),
            ),
        ],
      ),
      body: clientAsync.when(
        loading: () => const LoadingOverlay(),
        error: (err, _) => ErrorView(message: err.toString()),
        data: (client) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // En-tête client
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      ClientAvatar(
                        fullName: client.fullName,
                        cheminPhoto: client.cheminPhoto,
                        radius: 36,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        client.fullName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        client.numeroClient,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(height: 10),
                      StatusBadge(status: client.statut),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Informations personnelles
              _InfoCard(title: 'Informations personnelles', items: [
                if (client.telephone.isNotEmpty)
                  _InfoItem(
                      icon: Icons.phone,
                      label: 'Téléphone',
                      value: client.telephone),
                if (client.email != null)
                  _InfoItem(
                      icon: Icons.email_outlined,
                      label: 'Email',
                      value: client.email!),
                if (client.adresse != null)
                  _InfoItem(
                      icon: Icons.location_on_outlined,
                      label: 'Adresse',
                      value: client.adresse!),
                if (client.profession != null)
                  _InfoItem(
                      icon: Icons.work_outline,
                      label: 'Profession',
                      value: client.profession!),
                if (client.dateNaissance != null)
                  _InfoItem(
                      icon: Icons.cake_outlined,
                      label: 'Date de naissance',
                      value: Formatters.date(client.dateNaissance)),
                if (client.lieuNaissance != null)
                  _InfoItem(
                      icon: Icons.place_outlined,
                      label: 'Lieu de naissance',
                      value: client.lieuNaissance!),
              ]),
              const SizedBox(height: 12),

              // Pièce d'identité
              if (client.typePieceIdentite != null)
                _InfoCard(title: "Pièce d'identité", items: [
                  _InfoItem(
                      icon: Icons.badge_outlined,
                      label: 'Type',
                      value: client.typePieceIdentite!),
                  if (client.numeroPieceIdentite != null)
                    _InfoItem(
                        icon: Icons.numbers,
                        label: 'Numéro',
                        value: client.numeroPieceIdentite!),
                  if (client.dateExpirationPiece != null)
                    _InfoItem(
                        icon: Icons.event_outlined,
                        label: 'Expiration',
                        value: Formatters.date(client.dateExpirationPiece)),
                ]),

              const SizedBox(height: 12),

              // Comptes
              Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Comptes',
                              style: TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w700)),
                          if (auth?.isAdmin == true ||
                              auth?.isGestionnaire == true)
                            TextButton.icon(
                              onPressed: () => context.push(
                                  '/comptes/nouveau?clientId=$clientId'),
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('Ajouter'),
                            ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    comptesAsync.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.all(16),
                        child: LinearProgressIndicator(),
                      ),
                      error: (e, _) => Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text('Erreur: $e',
                            style: const TextStyle(color: AppTheme.error)),
                      ),
                      data: (comptes) {
                        if (comptes.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text('Aucun compte',
                                style: TextStyle(
                                    color: AppTheme.textSecondary)),
                          );
                        }
                        return Column(
                          children: comptes
                              .map((c) => ListTile(
                                    onTap: () => context.push(
                                        '/comptes/${c.numeroCompte}'),
                                    leading: Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryLight,
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                          Icons.account_balance_wallet,
                                          color: AppTheme.primary,
                                          size: 18),
                                    ),
                                    title: Text(c.typeLabel,
                                        style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600)),
                                    subtitle: Text(c.numeroCompte,
                                        style: const TextStyle(
                                            fontSize: 12,
                                            fontFamily: 'monospace')),
                                    trailing: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          Formatters.currency(c.solde),
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13),
                                        ),
                                        StatusBadge(status: c.statut),
                                      ],
                                    ),
                                  ))
                              .toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // ── Bénéficiaires (interactif) ──────────────────────────
              const SizedBox(height: 12),
              _BeneficiairesCard(
                clientId: clientId,
                clientName: client.fullName,
              ),

              // ── Carte membre ──────────────────────────────────────────
              if (auth?.isAdmin == true || auth?.isGestionnaire == true) ...[
                const SizedBox(height: 12),
                _CarteMiniCard(
                  client: client,
                  onViewCarte: () => context.push(
                    '/clients/$clientId/carte',
                    extra: client,
                  ),
                ),
              ],

              const SizedBox(height: 80),
            ],
          );
        },
      ),
    );
  }
}

// Providers paramétrés pour éviter les FutureProvider imbriqués
final _clientProvider = FutureProvider.family<dynamic, int>(
  (ref, id) => ref.watch(clientRepositoryProvider).getClientById(id),
);

final _clientComptesProvider = FutureProvider.family<dynamic, int>(
  (ref, id) => ref.watch(compteRepositoryProvider).getComptesByClient(id),
);

// ─── Widgets internes ─────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final String title;
  final List<_InfoItem> items;

  const _InfoCard({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            ...items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(item.icon,
                          size: 16, color: AppTheme.textSecondary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.label,
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textSecondary),
                            ),
                            Text(
                              item.value,
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class _InfoItem {
  final IconData icon;
  final String label;
  final String value;

  const _InfoItem(
      {required this.icon, required this.label, required this.value});
}

// ─── Carte mini-card ──────────────────────────────────────────────────────────

class _CarteMiniCard extends StatelessWidget {
  final dynamic client;
  final VoidCallback onViewCarte;

  const _CarteMiniCard({required this.client, required this.onViewCarte});

  @override
  Widget build(BuildContext context) {
    final hasCarte = client.numeroMembre != null;

    return Card(
      child: InkWell(
        onTap: onViewCarte,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: hasCarte ? CarteTheme.cardGradient : null,
                  color: hasCarte ? null : AppTheme.border,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.credit_card,
                  color: hasCarte ? Colors.white : AppTheme.textSecondary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Carte membre',
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    hasCarte
                        ? Text(
                            client.numeroMembre,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.primary,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        : const Text(
                            'Aucune carte générée',
                            style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary),
                          ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: hasCarte
                      ? AppTheme.success.withValues(alpha: 0.1)
                      : AppTheme.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  hasCarte ? 'Active' : 'Générer',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: hasCarte ? AppTheme.success : AppTheme.warning,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right,
                  size: 18, color: AppTheme.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget carte bénéficiaires — bouton qui ouvre le bottom sheet de gestion
class _BeneficiairesCard extends StatelessWidget {
  final int clientId;
  final String clientName;

  const _BeneficiairesCard({
    required this.clientId,
    required this.clientName,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          builder: (_) => BeneficiairesSheet(
            clientId: clientId,
            clientName: clientName,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.people_outline,
                    color: AppTheme.primary, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Bénéficiaires',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700)),
                    Text('Gérer les bénéficiaires du client',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right,
                  color: AppTheme.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
