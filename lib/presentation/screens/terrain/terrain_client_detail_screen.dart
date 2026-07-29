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

final _terrainClientProvider = FutureProvider.family<dynamic, int>(
  (ref, id) => ref.watch(clientRepositoryProvider).getClientById(id),
);

final _terrainClientComptesProvider = FutureProvider.family<dynamic, int>(
  (ref, id) =>
      ref.watch(compteRepositoryProvider).getComptesByClient(id),
);

/// Détail d'un client — interface Agent Terrain
class TerrainClientDetailScreen extends ConsumerWidget {
  final int clientId;

  const TerrainClientDetailScreen({super.key, required this.clientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientAsync = ref.watch(_terrainClientProvider(clientId));
    final comptesAsync =
        ref.watch(_terrainClientComptesProvider(clientId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fiche client',
            style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          clientAsync.when(
            data: (_) => IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Modifier',
              onPressed: () =>
                  context.push('/terrain/clients/$clientId/modifier'),
            ),
            loading: () => const SizedBox(),
            error: (_, _) => const SizedBox(),
          ),
        ],
      ),
      body: clientAsync.when(
        loading: () => const LoadingOverlay(),
        error: (err, _) => ErrorView(message: err.toString()),
        data: (client) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Avatar + identité
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        ClientAvatar(
                          fullName: client.fullName,
                          cheminPhoto: client.cheminPhoto,
                          radius: 40,
                        ),
                        StatusBadge(status: client.statut),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      client.fullName,
                      textAlign: TextAlign.center,
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
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Numéro de membre si disponible
            if (client.numeroMembre != null)
              Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: CarteTheme.cardGradient,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.credit_card,
                        color: Colors.white, size: 20),
                  ),
                  title: const Text('Carte membre',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    client.numeroMembre!,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  trailing: const Icon(Icons.verified,
                      color: AppTheme.success, size: 20),
                ),
              ),

            // Contact
            _InfoSection(title: 'Contact', rows: [
              _InfoRow(Icons.phone, 'Téléphone', client.telephone),
              if (client.email != null)
                _InfoRow(Icons.email_outlined, 'Email', client.email!),
              if (client.adresse != null)
                _InfoRow(Icons.location_on_outlined, 'Adresse',
                    client.adresse!),
              if (client.profession != null)
                _InfoRow(Icons.work_outline, 'Profession',
                    client.profession!),
            ]),
            const SizedBox(height: 12),

            // Identité
            _InfoSection(title: 'Identité', rows: [
              if (client.dateNaissance != null)
                _InfoRow(Icons.cake_outlined, 'Naissance',
                    Formatters.date(client.dateNaissance)),
              if (client.lieuNaissance != null)
                _InfoRow(Icons.place_outlined, 'Lieu de naissance',
                    client.lieuNaissance!),
              if (client.typePieceIdentite != null)
                _InfoRow(Icons.badge_outlined, 'Pièce d\'identité',
                    '${client.typePieceIdentite} — ${client.numeroPieceIdentite ?? ""}'),
            ]),
            const SizedBox(height: 12),

            // Comptes
            Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 14, 16, 8),
                    child: Text(
                      'Comptes',
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const Divider(height: 1),
                  comptesAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.all(12),
                      child: LinearProgressIndicator(),
                    ),
                    error: (e, _) => Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text('$e',
                          style:
                              const TextStyle(color: AppTheme.error)),
                    ),
                    data: (comptes) {
                      if (comptes.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'Aucun compte',
                            style:
                                TextStyle(color: AppTheme.textSecondary),
                          ),
                        );
                      }
                      return Column(
                        children: comptes
                            .map((c) => ListTile(
                                  dense: true,
                                  leading: Container(
                                    width: 34,
                                    height: 34,
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryLight,
                                      borderRadius:
                                          BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                        Icons.account_balance_wallet,
                                        color: AppTheme.primary,
                                        size: 16),
                                  ),
                                  title: Text(c.typeLabel,
                                      style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight:
                                              FontWeight.w600)),
                                  subtitle: Text(c.numeroCompte,
                                      style: const TextStyle(
                                          fontSize: 11,
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
                                          fontSize: 12,
                                        ),
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

            // Bénéficiaires
            if (client.beneficiaires.isNotEmpty) ...[
              const SizedBox(height: 12),
              _InfoSection(
                title: 'Bénéficiaires',
                rows: client.beneficiaires
                    .map((b) => _InfoRow(
                          Icons.person_outline,
                          b.lienAvecClient,
                          '${b.fullName} · ${b.telephone}',
                        ))
                    .toList(),
              ),
            ],

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String title;
  final List<_InfoRow> rows;

  const _InfoSection({required this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    final visible = rows.where((r) => r.value.isNotEmpty).toList();
    if (visible.isEmpty) return const SizedBox();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            ...visible.map((row) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(row.icon,
                          size: 16, color: AppTheme.textSecondary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(row.label,
                                style: const TextStyle(
                                    fontSize: 10,
                                    color: AppTheme.textSecondary)),
                            Text(row.value,
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500)),
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

class _InfoRow {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow(this.icon, this.label, this.value);
}
