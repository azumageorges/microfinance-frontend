import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/providers.dart';
import '../../widgets/app_app_bar.dart';

class OperationScreen extends ConsumerStatefulWidget {
  final String type; // 'depot' | 'retrait' | 'transfert'

  const OperationScreen({super.key, required this.type});

  @override
  ConsumerState<OperationScreen> createState() => _OperationScreenState();
}

class _OperationScreenState extends ConsumerState<OperationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _compteCtrl = TextEditingController();
  final _compteDestCtrl = TextEditingController();
  final _montantCtrl = TextEditingController();
  final _motifCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _compteCtrl.dispose();
    _compteDestCtrl.dispose();
    _montantCtrl.dispose();
    _motifCtrl.dispose();
    super.dispose();
  }

  String get _title {
    switch (widget.type) {
      case 'depot':
        return 'Dépôt';
      case 'retrait':
        return 'Retrait';
      case 'transfert':
        return 'Transfert';
      default:
        return 'Opération';
    }
  }

  Color get _color {
    switch (widget.type) {
      case 'depot':
        return AppTheme.success;
      case 'retrait':
        return AppTheme.error;
      default:
        return AppTheme.primary;
    }
  }

  IconData get _icon {
    switch (widget.type) {
      case 'depot':
        return Icons.add_circle;
      case 'retrait':
        return Icons.remove_circle;
      default:
        return Icons.swap_horiz;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });

    final data = {
      'numeroCompte': _compteCtrl.text.trim(),
      'montant': double.parse(_montantCtrl.text.trim()),
      if (_motifCtrl.text.isNotEmpty) 'motif': _motifCtrl.text.trim(),
      if (widget.type == 'transfert' &&
          _compteDestCtrl.text.isNotEmpty)
        'numeroCompteDestination': _compteDestCtrl.text.trim(),
    };

    try {
      final repo = ref.read(transactionRepositoryProvider);
      if (widget.type == 'depot') {
        await repo.depot(data);
      } else if (widget.type == 'retrait') {
        await repo.retrait(data);
      } else {
        await repo.transfert(data);
      }

      ref.invalidate(transactionsProvider);
      ref.invalidate(comptesProvider);

      if (mounted) {
        final successMessage = switch (widget.type) {
          'depot' => 'Dépôt effectué avec succès',
          'retrait' => 'Demande de retrait envoyée au gestionnaire',
          'transfert' => 'Demande de transfert envoyée au gestionnaire',
          _ => 'Opération enregistrée',
        };
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage),
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
      appBar: AppAppBar(title: _title),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              children: [
                // Icône
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: _color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(_icon, color: _color, size: 32),
                ),
                const SizedBox(height: 20),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Compte source
                          const Text('Numéro de compte',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500)),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _compteCtrl,
                            textCapitalization:
                                TextCapitalization.characters,
                            decoration: const InputDecoration(
                              hintText: 'Ex: CPT-00001',
                              prefixIcon: Icon(
                                  Icons.account_balance_wallet_outlined),
                            ),
                            validator: (v) => v?.trim().isEmpty == true
                                ? 'Requis'
                                : null,
                          ),

                          // Compte destination (transfert uniquement)
                          if (widget.type == 'transfert') ...[
                            const SizedBox(height: 14),
                            const Text('Compte destinataire',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500)),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _compteDestCtrl,
                              textCapitalization:
                                  TextCapitalization.characters,
                              decoration: const InputDecoration(
                                hintText: 'Ex: CPT-00002',
                                prefixIcon:
                                    Icon(Icons.send_outlined),
                              ),
                              validator: (v) =>
                                  v?.trim().isEmpty == true
                                      ? 'Requis'
                                      : null,
                            ),
                          ],

                          const SizedBox(height: 14),
                          const Text('Montant (FCFA)',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500)),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _montantCtrl,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            decoration: InputDecoration(
                              hintText: '0',
                              prefixIcon: const Icon(Icons.payments_outlined),
                              suffixText: 'FCFA',
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide:
                                    BorderSide(color: _color, width: 2),
                              ),
                            ),
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w600),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Requis';
                              final amount = double.tryParse(v);
                              if (amount == null || amount <= 0) {
                                return 'Montant invalide';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 14),
                          const Text('Motif (optionnel)',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500)),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _motifCtrl,
                            maxLines: 2,
                            decoration: const InputDecoration(
                              hintText: 'Raison de l\'opération...',
                            ),
                          ),

                          if (_error != null) ...[
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.error
                                    .withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: AppTheme.error
                                        .withValues(alpha: 0.3)),
                              ),
                              child: Text(_error!,
                                  style: const TextStyle(
                                      color: AppTheme.error)),
                            ),
                          ],

                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _loading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _color,
                            ),
                            child: _loading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white),
                                  )
                                : Text(widget.type == 'depot'
                                    ? 'Exécuter le $_title'
                                    : 'Envoyer la demande'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
