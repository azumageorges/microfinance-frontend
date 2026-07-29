import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../providers/providers.dart';
import '../../widgets/loading_overlay.dart';
import '../../widgets/app_app_bar.dart';

/// Écran de rapport / statistiques mensuel
/// Accessible : Admin + Gestionnaire
class RapportScreen extends ConsumerStatefulWidget {
  const RapportScreen({super.key});

  @override
  ConsumerState<RapportScreen> createState() => _RapportScreenState();
}

class _RapportScreenState extends ConsumerState<RapportScreen> {
  int _moisSelectionne = DateTime.now().month;
  int _anneeSelectionnee = DateTime.now().year;

  static const _moisLabels = [
    'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
    'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre',
  ];

  @override
  Widget build(BuildContext context) {
    final txAsync = ref.watch(transactionsProvider);
    final creditsAsync = ref.watch(creditsProvider);
    final clientsAsync = ref.watch(clientsProvider);
    final isWide = MediaQuery.of(context).size.width >= 700;

    return Scaffold(
      appBar: const AppAppBar(title: 'Rapport d\'activité'),
      body: Column(
        children: [
          // Sélecteur mois/année
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                const Icon(Icons.calendar_month_outlined,
                    color: AppTheme.primary, size: 20),
                const SizedBox(width: 8),
                DropdownButton<int>(
                  value: _moisSelectionne,
                  underline: const SizedBox(),
                  items: List.generate(
                      12,
                      (i) => DropdownMenuItem(
                            value: i + 1,
                            child: Text(_moisLabels[i],
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                          )),
                  onChanged: (v) =>
                      setState(() => _moisSelectionne = v!),
                ),
                const SizedBox(width: 16),
                DropdownButton<int>(
                  value: _anneeSelectionnee,
                  underline: const SizedBox(),
                  items: List.generate(
                      5,
                      (i) => DropdownMenuItem(
                            value: DateTime.now().year - i,
                            child: Text(
                                '${DateTime.now().year - i}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                          )),
                  onChanged: (v) =>
                      setState(() => _anneeSelectionnee = v!),
                ),
                const Spacer(),
                Text(
                  _moisLabels[_moisSelectionne - 1],
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: txAsync.when(
              loading: () => const LoadingOverlay(),
              error: (e, _) =>
                  ErrorView(message: e.toString()),
              data: (allTx) {
                // Filtrer par mois/année sélectionnés
                final txMois = allTx.where((tx) {
                  return tx.dateTransaction.month == _moisSelectionne &&
                      tx.dateTransaction.year == _anneeSelectionnee;
                }).toList();

                final totalDepots = txMois
                    .where((t) => t.typeTransaction == 'DEPOT')
                    .fold(0.0, (s, t) => s + t.montant);
                final totalRetraits = txMois
                    .where((t) => t.typeTransaction == 'RETRAIT')
                    .fold(0.0, (s, t) => s + t.montant);
                final totalTransferts = txMois
                    .where((t) => t.typeTransaction == 'TRANSFERT')
                    .fold(0.0, (s, t) => s + t.montant);
                final totalRemboursements = txMois
                    .where(
                        (t) => t.typeTransaction == 'REMBOURSEMENT')
                    .fold(0.0, (s, t) => s + t.montant);

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Titre période
                    Row(
                      children: [
                        Text(
                          '${_moisLabels[_moisSelectionne - 1]} $_anneeSelectionnee',
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryLight,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${txMois.length} opérations',
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Grille transactions
                    GridView.count(
                      crossAxisCount: isWide ? 4 : 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: isWide ? 2.0 : 1.6,
                      children: [
                        _RapportCard(
                          label: 'Dépôts',
                          value: Formatters.currency(totalDepots),
                          count: txMois
                              .where((t) =>
                                  t.typeTransaction == 'DEPOT')
                              .length,
                          icon: Icons.arrow_downward,
                          color: AppTheme.success,
                        ),
                        _RapportCard(
                          label: 'Retraits',
                          value: Formatters.currency(totalRetraits),
                          count: txMois
                              .where((t) =>
                                  t.typeTransaction == 'RETRAIT')
                              .length,
                          icon: Icons.arrow_upward,
                          color: AppTheme.error,
                        ),
                        _RapportCard(
                          label: 'Transferts',
                          value:
                              Formatters.currency(totalTransferts),
                          count: txMois
                              .where((t) =>
                                  t.typeTransaction == 'TRANSFERT')
                              .length,
                          icon: Icons.swap_horiz,
                          color: AppTheme.primary,
                        ),
                        _RapportCard(
                          label: 'Remboursements',
                          value: Formatters.currency(
                              totalRemboursements),
                          count: txMois
                              .where((t) =>
                                  t.typeTransaction == 'REMBOURSEMENT')
                              .length,
                          icon: Icons.replay_outlined,
                          color: const Color(0xFF8B5CF6),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Solde net du mois
                    Card(
                      color: AppTheme.primary,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const Icon(Icons.account_balance,
                                color: Colors.white, size: 28),
                            const SizedBox(width: 14),
                            Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Flux net du mois',
                                  style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12),
                                ),
                                Text(
                                  Formatters.currency(
                                      totalDepots - totalRetraits),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Section crédits du mois
                    creditsAsync.when(
                      loading: () => const SizedBox(),
                      error: (_, _) => const SizedBox(),
                      data: (credits) {
                        final creditsMois = credits.where((c) {
                          if (c.dateDemande == null) return false;
                          return c.dateDemande!.month ==
                                  _moisSelectionne &&
                              c.dateDemande!.year ==
                                  _anneeSelectionnee;
                        }).toList();

                        if (creditsMois.isEmpty) {
                          return const SizedBox();
                        }

                        final totalDemandes = creditsMois.fold(
                            0.0, (s, c) => s + c.montantPret);
                        final totalAccordes = creditsMois
                            .where((c) => c.montantAccorde != null)
                            .fold(0.0,
                                (s, c) => s + (c.montantAccorde ?? 0));

                        return Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Crédits du mois',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 10),
                            GridView.count(
                              crossAxisCount: isWide ? 3 : 2,
                              shrinkWrap: true,
                              physics:
                                  const NeverScrollableScrollPhysics(),
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: isWide ? 2.2 : 1.7,
                              children: [
                                _RapportCard(
                                  label: 'Demandes',
                                  value: '${creditsMois.length}',
                                  count: creditsMois.length,
                                  icon: Icons.credit_score,
                                  color: AppTheme.primary,
                                  isAmount: false,
                                ),
                                _RapportCard(
                                  label: 'Montant prêté',
                                  value: Formatters.currency(
                                      totalDemandes),
                                  count: creditsMois
                                      .where((c) =>
                                          c.statut == 'EN_ATTENTE')
                                      .length,
                                  countLabel: 'en attente',
                                  icon: Icons.pending_actions,
                                  color: AppTheme.warning,
                                ),
                                _RapportCard(
                                  label: 'Montant débloqué',
                                  value: Formatters.currency(
                                      totalAccordes),
                                  count: creditsMois
                                      .where((c) =>
                                          c.statut == 'EN_COURS' ||
                                          c.statut == 'VALIDE')
                                      .length,
                                  countLabel: 'actifs',
                                  icon: Icons.check_circle_outline,
                                  color: AppTheme.success,
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),

                    // Nouveaux clients du mois
                    const SizedBox(height: 20),
                    clientsAsync.when(
                      loading: () => const SizedBox(),
                      error: (_, _) => const SizedBox(),
                      data: (clients) {
                        final nouveaux = clients.where((c) {
                          if (c.createdAt == null) return false;
                          return c.createdAt!.month ==
                                  _moisSelectionne &&
                              c.createdAt!.year == _anneeSelectionnee;
                        }).toList();

                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryLight,
                                    borderRadius:
                                        BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                      Icons.person_add_outlined,
                                      color: AppTheme.primary),
                                ),
                                const SizedBox(width: 14),
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${nouveaux.length} nouveau(x) client(s)',
                                      style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700),
                                    ),
                                    Text(
                                      'enregistré(s) en ${_moisLabels[_moisSelectionne - 1]}',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color:
                                              AppTheme.textSecondary),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 40),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RapportCard extends StatelessWidget {
  final String label, value;
  final int count;
  final String countLabel;
  final IconData icon;
  final Color color;
  final bool isAmount;

  const _RapportCard({
    required this.label,
    required this.value,
    required this.count,
    required this.icon,
    required this.color,
    this.countLabel = 'opération(s)',
    this.isAmount = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 16),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count $countLabel',
                    style: TextStyle(
                        fontSize: 9,
                        color: color,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w800),
              overflow: TextOverflow.ellipsis,
            ),
            Text(label,
                style: const TextStyle(
                    fontSize: 11, color: AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }
}
