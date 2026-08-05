import 'package:flutter/material.dart';

import 'package:flutter/services.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';

import '../../../providers/providers.dart';



/// Provider paramétré pour les bénéficiaires d'un client

final beneficiairesProvider =

    FutureProvider.family<dynamic, int>((ref, clientId) {

  return ref

      .watch(beneficiaireRepositoryProvider)

      .getByClient(clientId);

});



/// Écran / Widget de gestion des bénéficiaires d'un client

class BeneficiairesSheet extends ConsumerStatefulWidget {

  final int clientId;

  final String clientName;



  const BeneficiairesSheet({

    super.key,

    required this.clientId,

    required this.clientName,

  });



  @override

  ConsumerState<BeneficiairesSheet> createState() =>

      _BeneficiairesSheetState();

}



class _BeneficiairesSheetState

    extends ConsumerState<BeneficiairesSheet> {

  bool _showForm = false;



  @override

  Widget build(BuildContext context) {

    final listAsync = ref.watch(beneficiairesProvider(widget.clientId));



    return Column(

      mainAxisSize: MainAxisSize.min,

      children: [

        // Header

        Padding(

          padding: const EdgeInsets.fromLTRB(20, 20, 12, 0),

          child: Row(

            children: [

              const Icon(Icons.people_outline,

                  color: AppTheme.primary, size: 22),

              const SizedBox(width: 10),

              Expanded(

                child: Column(

                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [

                    const Text('Bénéficiaires',

                        style: TextStyle(

                            fontSize: 17, fontWeight: FontWeight.w700)),

                    Text(

                      widget.clientName,

                      style: const TextStyle(

                          fontSize: 12, color: AppTheme.textSecondary),

                    ),

                  ],

                ),

              ),

              IconButton(

                icon: Icon(

                  _showForm ? Icons.close : Icons.add,

                  color: AppTheme.primary,

                ),

                tooltip: _showForm ? 'Annuler' : 'Ajouter',

                onPressed: () =>

                    setState(() => _showForm = !_showForm),

              ),

            ],

          ),

        ),

        const Divider(height: 16),



        // Formulaire d'ajout

        if (_showForm)

          _AddBeneficiaireForm(

            clientId: widget.clientId,

            onAdded: () {

              setState(() => _showForm = false);

              ref.invalidate(beneficiairesProvider(widget.clientId));

            },

          ),



        // Liste

        listAsync.when(

          loading: () => const Padding(

            padding: EdgeInsets.all(20),

            child: Center(child: CircularProgressIndicator()),

          ),

          error: (e, _) => Padding(

            padding: const EdgeInsets.all(16),

            child: Text('Erreur : $e',

                style: const TextStyle(color: AppTheme.error)),

          ),

          data: (beneficiaires) {

            if (beneficiaires.isEmpty) {

              return const Padding(

                padding: EdgeInsets.all(24),

                child: Center(

                  child: Text(

                    'Aucun bénéficiaire enregistré',

                    style: TextStyle(color: AppTheme.textSecondary),

                  ),

                ),

              );

            }

            return Column(

              children: beneficiaires

                  .map<Widget>((b) => _BeneficiaireTile(

                        beneficiaire: b,

                        onDelete: () async {

                          final confirm = await showDialog<bool>(

                            context: context,

                            builder: (ctx) => AlertDialog(

                              title: const Text('Supprimer'),

                              content: Text(

                                  'Supprimer ${b.fullName} ?'),

                              actions: [

                                TextButton(

                                  onPressed: () =>

                                      Navigator.pop(ctx, false),

                                  child: const Text('Annuler'),

                                ),

                                ElevatedButton(

                                  onPressed: () =>

                                      Navigator.pop(ctx, true),

                                  style: ElevatedButton.styleFrom(

                                      backgroundColor: AppTheme.error),

                                  child: const Text('Supprimer'),

                                ),

                              ],

                            ),

                          );

                          if (confirm == true && context.mounted) {

                            try {

                              await ref

                                  .read(beneficiaireRepositoryProvider)

                                  .delete(b.id);

                              ref.invalidate(beneficiairesProvider(

                                  widget.clientId));

                            } catch (e) {

                              if (context.mounted) {

                                ScaffoldMessenger.of(context)

                                    .showSnackBar(SnackBar(

                                  content: Text(e.toString()),

                                  backgroundColor: AppTheme.error,

                                ));

                              }

                            }

                          }

                        },

                      ))

                  .toList(),

            );

          },

        ),

        const SizedBox(height: 16),

      ],

    );

  }

}



// ─── Tile bénéficiaire ────────────────────────────────────────────────────────



class _BeneficiaireTile extends StatelessWidget {

  final dynamic beneficiaire;

  final VoidCallback onDelete;



  const _BeneficiaireTile(

      {required this.beneficiaire, required this.onDelete});



  @override

  Widget build(BuildContext context) {

    return ListTile(

      leading: CircleAvatar(

        radius: 18,

        backgroundColor: AppTheme.primaryLight,

        child: Text(

          beneficiaire.fullName.isNotEmpty

              ? beneficiaire.fullName[0].toUpperCase()

              : '?',

          style: const TextStyle(

              color: AppTheme.primary,

              fontWeight: FontWeight.w700,

              fontSize: 13),

        ),

      ),

      title: Text(beneficiaire.fullName,

          style: const TextStyle(

              fontWeight: FontWeight.w600, fontSize: 14)),

      subtitle: Column(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          Text(beneficiaire.lienAvecClient,

              style: const TextStyle(

                  fontSize: 11,

                  color: AppTheme.primary,

                  fontWeight: FontWeight.w500)),

          Text(beneficiaire.telephone,

              style: const TextStyle(

                  fontSize: 12, color: AppTheme.textSecondary)),

        ],

      ),

      trailing: IconButton(

        icon: const Icon(Icons.delete_outline,

            color: AppTheme.error, size: 20),

        onPressed: onDelete,

        tooltip: 'Supprimer',

      ),

    );

  }

}



// ─── Formulaire d'ajout ───────────────────────────────────────────────────────



class _AddBeneficiaireForm extends ConsumerStatefulWidget {

  final int clientId;

  final VoidCallback onAdded;



  const _AddBeneficiaireForm(

      {required this.clientId, required this.onAdded});



  @override

  ConsumerState<_AddBeneficiaireForm> createState() =>

      _AddBeneficiaireFormState();

}



class _AddBeneficiaireFormState

    extends ConsumerState<_AddBeneficiaireForm> {

  final _formKey = GlobalKey<FormState>();

  final _nomCtrl = TextEditingController();

  final _prenomCtrl = TextEditingController();

  final _telCtrl = TextEditingController();

  final _adresseCtrl = TextEditingController();

  String _lien = 'Conjoint(e)';

  bool _loading = false;

  String? _error;



  static const _liens = [

    'Conjoint(e)',

    'Enfant',

    'Parent',

    'Frère/Sœur',

    'Autre',

  ];



  @override

  void dispose() {

    _nomCtrl.dispose();

    _prenomCtrl.dispose();

    _telCtrl.dispose();

    _adresseCtrl.dispose();

    super.dispose();

  }



  Future<void> _submit() async {

    if (!_formKey.currentState!.validate()) return;

    setState(() { _loading = true; _error = null; });

    try {

      await ref.read(beneficiaireRepositoryProvider).create({

        'clientId': widget.clientId,

        'nom': _nomCtrl.text.trim(),

        'prenom': _prenomCtrl.text.trim(),

        'telephone': _telCtrl.text.trim(),

        'lienAvecClient': _lien,

        if (_adresseCtrl.text.isNotEmpty)

          'adresse': _adresseCtrl.text.trim(),

      });

      widget.onAdded();

    } catch (e) {

      setState(() => _error = e.toString());

    } finally {

      if (mounted) setState(() => _loading = false);

    }

  }



  @override

  Widget build(BuildContext context) {

    return Container(

      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),

      padding: const EdgeInsets.all(14),

      decoration: BoxDecoration(

        color: AppTheme.primaryLight,

        borderRadius: BorderRadius.circular(10),

        border: Border.all(

            color: AppTheme.primary.withValues(alpha: 0.2)),

      ),

      child: Form(

        key: _formKey,

        child: Column(

          crossAxisAlignment: CrossAxisAlignment.stretch,

          children: [

            const Text('Nouveau bénéficiaire',

                style: TextStyle(

                    fontSize: 13,

                    fontWeight: FontWeight.w700,

                    color: AppTheme.primary)),

            const SizedBox(height: 10),

            Row(

              children: [

                Expanded(

                  child: TextFormField(

                    controller: _prenomCtrl,

                    decoration:

                        const InputDecoration(labelText: 'Prénom *'),

                    validator: (v) =>

                        v?.trim().isEmpty == true ? 'Requis' : null,

                  ),

                ),

                const SizedBox(width: 10),

                Expanded(

                  child: TextFormField(

                    controller: _nomCtrl,

                    decoration:

                        const InputDecoration(labelText: 'Nom *'),

                    validator: (v) =>

                        v?.trim().isEmpty == true ? 'Requis' : null,

                  ),

                ),

              ],

            ),

            const SizedBox(height: 10),

            TextFormField(

              controller: _telCtrl,

              keyboardType: TextInputType.phone,

              inputFormatters: [

                FilteringTextInputFormatter.digitsOnly

              ],

              decoration:

                  const InputDecoration(labelText: 'Téléphone *'),

              validator: (v) =>

                  v?.trim().isEmpty == true ? 'Requis' : null,

            ),

            const SizedBox(height: 10),

            DropdownButtonFormField<String>(

              // ignore: deprecated_member_use

              value: _lien,

              decoration: const InputDecoration(labelText: 'Lien'),

              items: _liens

                  .map((l) =>

                      DropdownMenuItem(value: l, child: Text(l)))

                  .toList(),

              onChanged: (v) => setState(() => _lien = v!),

            ),

            const SizedBox(height: 10),

            TextFormField(

              controller: _adresseCtrl,

              decoration: const InputDecoration(labelText: 'Adresse'),

            ),

            if (_error != null) ...[

              const SizedBox(height: 8),

              Text(_error!,

                  style: const TextStyle(

                      color: AppTheme.error, fontSize: 12)),

            ],

            const SizedBox(height: 12),

            ElevatedButton(

              onPressed: _loading ? null : _submit,

              child: _loading

                  ? const SizedBox(

                      height: 18,

                      width: 18,

                      child: CircularProgressIndicator(

                          strokeWidth: 2, color: Colors.white))

                  : const Text('Enregistrer'),

            ),

          ],

        ),

      ),

    );

  }

}

