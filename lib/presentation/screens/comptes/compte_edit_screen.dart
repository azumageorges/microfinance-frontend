import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../../../providers/providers.dart';
import '../../widgets/loading_overlay.dart';
import '../../widgets/app_app_bar.dart';

class CompteEditScreen extends ConsumerStatefulWidget {
  final String numeroCompte;

  const CompteEditScreen({super.key, required this.numeroCompte});

  @override
  ConsumerState<CompteEditScreen> createState() => _CompteEditScreenState();
}

class _CompteEditScreenState extends ConsumerState<CompteEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tauxInteretController = TextEditingController();
  final _dureeEnMoisController = TextEditingController();
  final _montantCibleController = TextEditingController();
  final _representantLegalController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _tauxInteretController.dispose();
    _dureeEnMoisController.dispose();
    _montantCibleController.dispose();
    _representantLegalController.dispose();
    super.dispose();
  }

  Future<void> _loadCompte() async {
    final compte = await ref.read(compteRepositoryProvider).getCompteByNumero(widget.numeroCompte);
    _tauxInteretController.text = compte.tauxInteret?.toString() ?? '';
    _dureeEnMoisController.text = compte.dureeEnMois?.toString() ?? '';
    _montantCibleController.text = compte.montantCible?.toString() ?? '';
    _representantLegalController.text = compte.representantLegal ?? '';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final data = <String, dynamic>{};
      if (_tauxInteretController.text.isNotEmpty) {
        data['tauxInteret'] = double.tryParse(_tauxInteretController.text);
      }
      if (_dureeEnMoisController.text.isNotEmpty) {
        data['dureeEnMois'] = int.tryParse(_dureeEnMoisController.text);
      }
      if (_montantCibleController.text.isNotEmpty) {
        data['montantCible'] = double.tryParse(_montantCibleController.text);
      }
      if (_representantLegalController.text.isNotEmpty) {
        data['representantLegal'] = _representantLegalController.text;
      }

      await ref.read(compteRepositoryProvider).modifierCompte(widget.numeroCompte, data);
      if (mounted) {
        ref.invalidate(comptesProvider);
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Compte modifié avec succès'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAppBar(
        title: 'Modifier le compte',
      ),
      body: FutureBuilder(
        future: _loadCompte(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingOverlay();
          }
          return Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSection('Paramètres du compte', [
                  _buildTextField(
                    _tauxInteretController,
                    'Taux d\'intérêt (%)',
                    keyboardType: TextInputType.number,
                    validator: Validators.positiveNumber(
                      isRequired: false,
                      min: 0,
                      max: 100,
                      messageInvalid: 'Taux entre 0 et 100',
                    ),
                  ),
                  _buildTextField(
                    _dureeEnMoisController,
                    'Durée (mois)',
                    keyboardType: TextInputType.number,
                    validator: Validators.integer(
                      isRequired: false,
                      min: 1,
                      max: 360,
                      messageInvalid: 'Durée entre 1 et 360 mois',
                    ),
                  ),
                  _buildTextField(
                    _montantCibleController,
                    'Montant cible',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
                    ],
                    validator: (v) {
                      if (v!.isEmpty) return null;
                      final value = double.tryParse(v.replaceAll(',', '.'));
                      if (value == null || value <= 0) {
                        return 'Montant positif requis';
                      }
                      return null;
                    },
                  ),
                  _buildTextField(
                    _representantLegalController,
                    'Représentant légal',
                    validator: Validators.maxLength(100,
                        message: 'Max 100 caractères'),
                  ),
                ]),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Enregistrer',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          )),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: Colors.grey[50],
        ),
      ),
    );
  }
}
