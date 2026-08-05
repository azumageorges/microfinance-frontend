import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../../../providers/providers.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/loading_overlay.dart';
import '../../widgets/app_app_bar.dart';
import '../../widgets/upload_photo_widget.dart';

class ClientFormScreen extends ConsumerStatefulWidget {
  final int? clientId;

  const ClientFormScreen({super.key, this.clientId});

  @override
  ConsumerState<ClientFormScreen> createState() => _ClientFormScreenState();
}

class _ClientFormScreenState extends ConsumerState<ClientFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomCtrl = TextEditingController();
  final _prenomCtrl = TextEditingController();
  final _telCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _adresseCtrl = TextEditingController();
  final _professionCtrl = TextEditingController();
  final _lieuNaissCtrl = TextEditingController();
  final _typePieceCtrl = TextEditingController();
  final _numPieceCtrl = TextEditingController();

  bool _loading = false;
  bool _loadingData = false;
  String? _error;

  // Date de naissance
  DateTime? _dateNaissance;

  // Photo passeport
  String? _cheminPhotoActuel;
  Uint8List? _photoBytes;
  String? _photoFileName;

  bool get isEdit => widget.clientId != null;

  @override
  void initState() {
    super.initState();
    if (isEdit) _loadClient();
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    _prenomCtrl.dispose();
    _telCtrl.dispose();
    _emailCtrl.dispose();
    _adresseCtrl.dispose();
    _professionCtrl.dispose();
    _lieuNaissCtrl.dispose();
    _typePieceCtrl.dispose();
    _numPieceCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadClient() async {
    setState(() => _loadingData = true);
    try {
      final client = await ref
          .read(clientRepositoryProvider)
          .getClientById(widget.clientId!);
      _nomCtrl.text = client.nom;
      _prenomCtrl.text = client.prenom;
      _telCtrl.text = client.telephone;
      _emailCtrl.text = client.email ?? '';
      _adresseCtrl.text = client.adresse ?? '';
      _professionCtrl.text = client.profession ?? '';
      _lieuNaissCtrl.text = client.lieuNaissance ?? '';
      _typePieceCtrl.text = client.typePieceIdentite ?? '';
      _numPieceCtrl.text = client.numeroPieceIdentite ?? '';
      _cheminPhotoActuel = client.cheminPhoto;
      _dateNaissance = client.dateNaissance;
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loadingData = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });

    final data = <String, dynamic>{
      'nom': _nomCtrl.text.trim(),
      'prenom': _prenomCtrl.text.trim(),
      'telephone': _telCtrl.text.trim(),
    };

    // Ajouter uniquement les champs non vides
    if (_dateNaissance != null) {
      data['dateNaissance'] =
          '${_dateNaissance!.year.toString().padLeft(4, '0')}-'
          '${_dateNaissance!.month.toString().padLeft(2, '0')}-'
          '${_dateNaissance!.day.toString().padLeft(2, '0')}';
    }
    if (_emailCtrl.text.trim().isNotEmpty) {
      data['email'] = _emailCtrl.text.trim();
    }
    if (_adresseCtrl.text.trim().isNotEmpty) {
      data['adresse'] = _adresseCtrl.text.trim();
    }
    if (_professionCtrl.text.trim().isNotEmpty) {
      data['profession'] = _professionCtrl.text.trim();
    }
    if (_lieuNaissCtrl.text.trim().isNotEmpty) {
      data['lieuNaissance'] = _lieuNaissCtrl.text.trim();
    }
    if (_typePieceCtrl.text.trim().isNotEmpty) {
      data['typePieceIdentite'] = _typePieceCtrl.text.trim();
    }
    if (_numPieceCtrl.text.trim().isNotEmpty) {
      data['numeroPieceIdentite'] = _numPieceCtrl.text.trim();
    }

    try {
      if (isEdit) {
        await ref
            .read(clientRepositoryProvider)
            .updateClient(widget.clientId!, data);
        // Upload photo si sélectionnée
        if (_photoBytes != null && _photoFileName != null) {
          await ref.read(fichierRepositoryProvider).uploadPhotoClient(
              widget.clientId!, _photoBytes!, _photoFileName!);
        }
        ref.invalidate(clientsProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Client modifié avec succès'),
              backgroundColor: AppTheme.success,
            ),
          );
          context.pop();
        }
      } else {
        final client = await ref
            .read(clientRepositoryProvider)
            .createClient(data);
        // Upload photo si sélectionnée après création (seulement si online)
        if (_photoBytes != null && _photoFileName != null && client.id > 0) {
          await ref.read(fichierRepositoryProvider).uploadPhotoClient(
              client.id, _photoBytes!, _photoFileName!);
        }
        ref.invalidate(clientsProvider);
        if (mounted) {
          // Message différent selon mode online/offline
          final isOffline = client.id < 0; // ID négatif = créé localement
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(
                    isOffline ? Icons.cloud_off_rounded : Icons.check_circle_outline,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isOffline
                          ? 'Client sauvegardé localement — sera synchronisé dès le retour du réseau'
                          : 'Client créé avec succès',
                    ),
                  ),
                ],
              ),
              backgroundColor: isOffline ? AppTheme.warning : AppTheme.success,
              duration: Duration(seconds: isOffline ? 5 : 3),
            ),
          );
          if (kIsWeb) {
            context.go('/clients/${client.id}');
          } else {
            context.go('/terrain/clients/${client.id}');
          }
        }
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingData) return const Scaffold(body: LoadingOverlay());

    return Scaffold(
      appBar: AppAppBar(
        title: isEdit ? 'Modifier le client' : 'Nouveau client',
      ),
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Identité
            _FormSection(title: 'Identité', icon: Icons.person_outline, children: [
              AppTextField(
                label: 'Prénom',
                controller: _prenomCtrl,
                required: true,
                validator: Validators.personName(label: 'Prénom'),
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Nom',
                controller: _nomCtrl,
                required: true,
                validator: Validators.personName(label: 'Nom'),
              ),
              const SizedBox(height: 12),
              // Date de naissance — date picker natif
              _DateField(
                label: 'Date de naissance',
                value: _dateNaissance,
                onChanged: (date) => setState(() => _dateNaissance = date),
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Lieu de naissance',
                controller: _lieuNaissCtrl,
                validator: Validators.maxLength(80,
                    message: 'Lieu de naissance : max 80 caractères'),
              ),
            ]),
            const SizedBox(height: 16),

            // Photo passeport
            _FormSection(title: 'Photo passeport', icon: Icons.photo_camera_outlined, children: [
              Center(
                child: UploadPhotoWidget(
                  cheminActuel: _cheminPhotoActuel,
                  circle: false,
                  size: 110,
                  label: _cheminPhotoActuel != null || _photoBytes != null
                      ? 'Changer la photo'
                      : 'Ajouter une photo',
                  onUpload: (bytes, filename) async {
                    // Stockage local — l'upload réel se fait à la sauvegarde
                    setState(() {
                      _photoBytes = bytes;
                      _photoFileName = filename;
                    });
                  },
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'JPEG, PNG — max 5 Mo. Format portrait recommandé.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
              ),
            ]),
            const SizedBox(height: 16),

            // Contact
            _FormSection(title: 'Contact', icon: Icons.phone_outlined, children: [
              AppTextField(
                label: 'Téléphone',
                controller: _telCtrl,
                required: true,
                keyboardType: TextInputType.phone,
                prefixIcon: const Icon(Icons.phone_outlined),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: Validators.phone(isRequired: false),
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Email',
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: const Icon(Icons.email_outlined),
                validator: Validators.email(isRequired: false),
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Adresse',
                controller: _adresseCtrl,
                maxLines: 2,
                prefixIcon: const Icon(Icons.location_on_outlined),
                validator: Validators.maxLength(200,
                    message: 'Adresse : max 200 caractères'),
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Profession',
                controller: _professionCtrl,
                prefixIcon: const Icon(Icons.work_outline),
                validator: Validators.maxLength(80,
                    message: 'Profession : max 80 caractères'),
              ),
            ]),
            const SizedBox(height: 16),

            // Pièce d'identité
            _FormSection(title: "Pièce d'identité", icon: Icons.badge_outlined, children: [
              AppTextField(
                label: 'Type de pièce',
                controller: _typePieceCtrl,
                hint: 'CNI, Passeport, Permis...',
                prefixIcon: const Icon(Icons.badge_outlined),
                validator: Validators.combine([
                  Validators.maxLength(30,
                      message: 'Type de pièce : max 30 caractères'),
                  (v) {
                    final type = v?.trim() ?? '';
                    final num = _numPieceCtrl.text.trim();
                    if (type.isEmpty && num.isNotEmpty) {
                      return 'Type de pièce requis';
                    }
                    return null;
                  },
                ]),
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Numéro de pièce',
                controller: _numPieceCtrl,
                prefixIcon: const Icon(Icons.numbers),
                validator: Validators.combine([
                  Validators.maxLength(40,
                      message: 'Numéro de pièce : max 40 caractères'),
                  (v) {
                    final num = v?.trim() ?? '';
                    final type = _typePieceCtrl.text.trim();
                    if (num.isEmpty && type.isNotEmpty) {
                      return 'Numéro de pièce requis';
                    }
                    return null;
                  },
                ]),
              ),
            ]),

            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: AppTheme.error.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: AppTheme.error, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_error!,
                          style: const TextStyle(
                              color: AppTheme.error, fontSize: 13)),
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
                  : Text(isEdit
                      ? 'Enregistrer les modifications'
                      : 'Créer le client'),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;

  const _DateField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final formatted = value != null
        ? DateFormat('dd/MM/yyyy').format(value!)
        : null;

    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime(DateTime.now().year - 20),
          firstDate: DateTime(1920),
          lastDate: DateTime.now(),
          locale: const Locale('fr'),
          helpText: 'Date de naissance',
          cancelText: 'Annuler',
          confirmText: 'Confirmer',
          fieldLabelText: 'Date de naissance',
          fieldHintText: 'jj/mm/aaaa',
        );
        if (picked != null) onChanged(picked);
      },
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.cake_outlined),
          suffixIcon: value != null
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () => onChanged(null),
                  tooltip: 'Effacer',
                )
              : const Icon(Icons.calendar_today_outlined, size: 18),
        ),
        isEmpty: value == null,
        child: Text(
          formatted ?? '',
          style: TextStyle(
            fontSize: 14,
            color: value != null
                ? AppTheme.textPrimary
                : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _FormSection extends StatelessWidget {
  final String title;
  final IconData? icon;
  final List<Widget> children;

  const _FormSection({
    required this.title,
    required this.children,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 16, color: AppTheme.primary),
                  const SizedBox(width: 6),
                ],
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }
}
