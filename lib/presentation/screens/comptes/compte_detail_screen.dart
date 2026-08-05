import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';

import '../../../core/utils/formatters.dart';

import '../../../providers/providers.dart';

import '../../widgets/loading_overlay.dart';

import '../../widgets/status_badge.dart';

import '../../widgets/app_app_bar.dart';



class CompteDetailScreen extends ConsumerWidget {

  final String numeroCompte;



  const CompteDetailScreen({super.key, required this.numeroCompte});



  @override

  Widget build(BuildContext context, WidgetRef ref) {

    final compteAsync = ref.watch(_compteByNumeroProvider(numeroCompte));

    final txAsync = ref.watch(_txByCompteProvider(numeroCompte));

    final auth = ref.watch(authProvider);

    final canManage = auth?.isAdmin == true || auth?.isGestionnaire == true;



    return compteAsync.when(

      loading: () => const Scaffold(body: LoadingOverlay()),

      error: (err, _) => Scaffold(body: ErrorView(message: err.toString())),

      data: (compte) {

        return Scaffold(

          appBar: AppAppBar(

            title: compte.typeLabel,

            actions: [

              if (canManage)

                PopupMenuButton<String>(

                  onSelected: (action) =>

                      _handleAction(context, ref, action, compte.statut),

                  itemBuilder: (_) => [

                    if (compte.statut == 'ACTIF')

                      const PopupMenuItem(

                        value: 'bloquer',

                        child: Row(children: [

                          Icon(Icons.lock_outline, size: 18),

                          SizedBox(width: 8),

                          Text('Bloquer'),

                        ]),

                      ),

                    if (compte.statut == 'BLOQUE')

                      const PopupMenuItem(

                        value: 'debloquer',

                        child: Row(children: [

                          Icon(Icons.lock_open_outlined, size: 18),

                          SizedBox(width: 8),

                          Text('Débloquer'),

                        ]),

                      ),

                    if (compte.statut != 'CLOTURE')

                      const PopupMenuItem(

                        value: 'cloturer',

                        child: Row(children: [

                          Icon(Icons.close, size: 18,

                              color: AppTheme.error),

                          SizedBox(width: 8),

                          Text('Clôturer',

                              style: TextStyle(color: AppTheme.error)),

                        ]),

                      ),

                  ],

                ),

            ],

          ),

          body: ListView(

            padding: const EdgeInsets.all(16),

            children: [

              // Solde

              Card(

                color: AppTheme.primary,

                child: Padding(

                  padding: const EdgeInsets.all(24),

                  child: Column(

                    children: [

                      const Text(

                        'Solde disponible',

                        style: TextStyle(

                            color: Colors.white70, fontSize: 13),

                      ),

                      const SizedBox(height: 8),

                      Text(

                        Formatters.currency(compte.solde),

                        style: const TextStyle(

                          color: Colors.white,

                          fontSize: 28,

                          fontWeight: FontWeight.w800,

                        ),

                      ),

                      const SizedBox(height: 12),

                      StatusBadge(status: compte.statut),

                    ],

                  ),

                ),

              ),

              const SizedBox(height: 12),



              // Infos

              Card(

                child: Padding(

                  padding: const EdgeInsets.all(16),

                  child: Column(

                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [

                      const Text('Informations',

                          style: TextStyle(

                              fontSize: 15, fontWeight: FontWeight.w700)),

                      const SizedBox(height: 12),

                      _InfoRow(label: 'Numéro', value: compte.numeroCompte),

                      _InfoRow(label: 'Type', value: compte.typeLabel),

                      _InfoRow(

                          label: 'Client',

                          value: compte.clientFullName),

                      if (compte.dateOuverture != null)

                        _InfoRow(

                            label: 'Ouvert le',

                            value: Formatters.date(compte.dateOuverture)),

                      if (compte.dateEcheance != null)

                        _InfoRow(

                            label: 'Échéance',

                            value: Formatters.date(compte.dateEcheance)),

                      if (compte.tauxInteret != null)

                        _InfoRow(

                            label: 'Taux d\'intérêt',

                            value: '${compte.tauxInteret}%'),

                      if (compte.dureeEnMois != null)

                        _InfoRow(

                            label: 'Durée',

                            value: '${compte.dureeEnMois} mois'),

                      if (compte.montantCible != null)

                        _InfoRow(

                            label: 'Montant cible',

                            value: Formatters.currency(compte.montantCible)),

                    ],

                  ),

                ),

              ),

              const SizedBox(height: 12),



              // Actions rapides caissier

              if (auth?.isCaissier == true || auth?.isAdmin == true) ...[

                Row(

                  children: [

                    Expanded(

                      child: OutlinedButton.icon(

                        onPressed: () => context.push('/transactions/depot'),

                        icon: const Icon(Icons.add),

                        label: const Text('Dépôt'),

                      ),

                    ),

                    const SizedBox(width: 8),

                    Expanded(

                      child: OutlinedButton.icon(

                        onPressed: () =>

                            context.push('/transactions/retrait'),

                        icon: const Icon(Icons.remove),

                        label: const Text('Retrait'),

                      ),

                    ),

                  ],

                ),

                const SizedBox(height: 12),

              ],



              // Transactions

              Card(

                child: Column(

                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [

                    const Padding(

                      padding: EdgeInsets.fromLTRB(16, 16, 16, 8),

                      child: Text('Historique des transactions',

                          style: TextStyle(

                              fontSize: 15, fontWeight: FontWeight.w700)),

                    ),

                    const Divider(height: 1),

                    txAsync.when(

                      loading: () => const Padding(

                        padding: EdgeInsets.all(16),

                        child: LinearProgressIndicator(),

                      ),

                      error: (e, _) => Padding(

                        padding: const EdgeInsets.all(16),

                        child: Text('Erreur: $e',

                            style: const TextStyle(color: AppTheme.error)),

                      ),

                      data: (txs) {

                        if (txs.isEmpty) {

                          return const Padding(

                            padding: EdgeInsets.all(16),

                            child: Text('Aucune transaction',

                                style: TextStyle(

                                    color: AppTheme.textSecondary)),

                          );

                        }

                        return Column(

                          children: txs

                              .take(20)

                              .map((tx) => ListTile(

                                    dense: true,

                                    leading: Container(

                                      width: 32,

                                      height: 32,

                                      decoration: BoxDecoration(

                                        color: (tx.isCredit

                                                ? AppTheme.success

                                                : AppTheme.error)

                                            .withValues(alpha: 0.12),

                                        borderRadius:

                                            BorderRadius.circular(8),

                                      ),

                                      child: Icon(

                                        tx.isCredit

                                            ? Icons.arrow_downward

                                            : Icons.arrow_upward,

                                        size: 16,

                                        color: tx.isCredit

                                            ? AppTheme.success

                                            : AppTheme.error,

                                      ),

                                    ),

                                    title: Text(

                                      tx.typeLabel,

                                      style: const TextStyle(fontSize: 13),

                                    ),

                                    subtitle: Text(

                                      Formatters.date(tx.dateTransaction),

                                      style: const TextStyle(fontSize: 11),

                                    ),

                                    trailing: Text(

                                      Formatters.currency(tx.montant),

                                      style: TextStyle(

                                        fontWeight: FontWeight.w600,

                                        color: tx.isCredit

                                            ? AppTheme.success

                                            : AppTheme.error,

                                      ),

                                    ),

                                  ))

                              .toList(),

                        );

                      },

                    ),

                  ],

                ),

              ),

              const SizedBox(height: 80),

            ],

          ),

        );

      },

    );

  }



  Future<void> _handleAction(

    BuildContext context,

    WidgetRef ref,

    String action,

    String currentStatut,

  ) async {

    final repo = ref.read(compteRepositoryProvider);

    try {

      if (action == 'bloquer') {

        await repo.bloquerCompte(numeroCompte);

      } else if (action == 'debloquer') {

        await repo.debloquerCompte(numeroCompte);

      } else if (action == 'cloturer') {

        await repo.cloturerCompte(numeroCompte);

      }

      ref.invalidate(comptesProvider);

      if (context.mounted) {

        ScaffoldMessenger.of(context).showSnackBar(

          const SnackBar(

            content: Text('Opération effectuée'),

            backgroundColor: AppTheme.success,

          ),

        );

      }

    } catch (e) {

      if (context.mounted) {

        ScaffoldMessenger.of(context).showSnackBar(

          SnackBar(

            content: Text(e.toString()),

            backgroundColor: AppTheme.error,

          ),

        );

      }

    }

  }

}



// Providers paramétrés

final _compteByNumeroProvider = FutureProvider.family<dynamic, String>(

  (ref, numero) =>

      ref.watch(compteRepositoryProvider).getCompteByNumero(numero),

);



final _txByCompteProvider = FutureProvider.family<dynamic, String>(

  (ref, numero) =>

      ref.watch(transactionRepositoryProvider).getTransactionsByCompte(numero),

);



class _InfoRow extends StatelessWidget {

  final String label;

  final String value;



  const _InfoRow({required this.label, required this.value});



  @override

  Widget build(BuildContext context) {

    return Padding(

      padding: const EdgeInsets.only(bottom: 8),

      child: Row(

        children: [

          SizedBox(

            width: 130,

            child: Text(label,

                style: const TextStyle(

                    fontSize: 13, color: AppTheme.textSecondary)),

          ),

          Expanded(

            child: Text(value,

                style: const TextStyle(

                    fontSize: 13, fontWeight: FontWeight.w500)),

          ),

        ],

      ),

    );

  }

}

