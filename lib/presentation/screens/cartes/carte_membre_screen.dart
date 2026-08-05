import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_selector/file_selector.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/carte_theme.dart';
import '../../../core/utils/carte_pdf_service.dart';
import '../../../data/models/carte_model.dart';
import '../../../data/models/client_model.dart';
import '../../../data/repositories/carte_repository.dart';
import '../../../data/repositories/fichier_repository.dart';
import '../../../providers/providers.dart';
import '../../widgets/loading_overlay.dart';

// ─── Provider ─────────────────────────────────────────────────────────────────

final _carteProvider = FutureProvider.family<CarteModel, int>(
  (ref, clientId) => ref.watch(carteRepositoryProvider).getCarte(clientId),
);

// ─── Écran principal ──────────────────────────────────────────────────────────

class CarteMembre extends ConsumerStatefulWidget {
  final int clientId;
  final ClientModel client;

  const CarteMembre({
    super.key,
    required this.clientId,
    required this.client,
  });

  @override
  ConsumerState<CarteMembre> createState() => _CarteMembreState();
}

class _CarteMembreState extends ConsumerState<CarteMembre> {
  Uint8List? _photoBytes;
  String?   _photoFileName;
  bool _uploadingPhoto  = false;
  bool _generatingCarte = false;
  bool _deletingCarte  = false;
  String? _cheminPhotoMisAJour;

  bool get _hasPhotoServeur =>
      _cheminPhotoMisAJour != null ||
      (widget.client.cheminPhoto?.isNotEmpty == true);

  String? get _photoUrl {
    final chemin = _cheminPhotoMisAJour ?? widget.client.cheminPhoto;
    if (chemin == null || chemin.isEmpty) return null;
    return FichierRepository.urlPhoto(chemin);
  }

  Future<void> _choisirPhoto() async {
    const typeGroup = XTypeGroup(
      label: 'Photo passeport',
      extensions: ['jpg', 'jpeg', 'png', 'webp'],
      mimeTypes: ['image/jpeg', 'image/png', 'image/webp'],
    );
    final file = await openFile(acceptedTypeGroups: [typeGroup]);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (bytes.length > 5 * 1024 * 1024) {
      if (mounted) _showError('Fichier trop volumineux (max 5 Mo)');
      return;
    }
    setState(() { _photoBytes = bytes; _photoFileName = file.name; });
  }

  Future<void> _emettreCarteAction() async {
    if (_photoBytes != null && _photoFileName != null) {
      setState(() => _uploadingPhoto = true);
      try {
        await ref.read(fichierRepositoryProvider)
            .uploadPhotoClient(widget.clientId, _photoBytes!, _photoFileName!);
        final updated = await ref.read(clientRepositoryProvider)
            .getClientById(widget.clientId);
        if (mounted) setState(() => _cheminPhotoMisAJour = updated.cheminPhoto);
        ref.invalidate(clientsProvider);
      } catch (e) {
        if (mounted) _showError('Erreur upload photo : $e');
        setState(() => _uploadingPhoto = false);
        return;
      }
      setState(() => _uploadingPhoto = false);
    }
    setState(() => _generatingCarte = true);
    try {
      await ref.read(carteRepositoryProvider).genererCarte(widget.clientId);
      ref.invalidate(_carteProvider(widget.clientId));
      ref.invalidate(clientsProvider); // ← rafraîchit le numeroMembre dans la liste
      if (mounted) _showSuccess('Carte émise avec succès ✓');
    } catch (e) {
      if (mounted) _showError(e.toString());
    } finally {
      if (mounted) setState(() => _generatingCarte = false);
    }
  }

  /// Demande confirmation avant de régénérer une carte déjà émise.
  Future<void> _confirmerEtRegenerer() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Régénérer la carte ?'),
        content: const Text(
          'Le QR code sera recréé. Le numéro de membre et '
          'les dates d\'expiration restent inchangés.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary),
            child: const Text('Régénérer'),
          ),
        ],
      ),
    );
    if (ok == true) _emettreCarteAction();
  }

  /// Supprime la carte membre du client.
  Future<void> _confirmerEtSupprimer() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer la carte ?'),
        content: const Text(
          'Cette action est irréversible. Le numéro de membre sera supprimé.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (ok == true) {
      setState(() => _deletingCarte = true);
      try {
        await ref.read(carteRepositoryProvider).supprimerCarte(widget.clientId);
        ref.invalidate(_carteProvider(widget.clientId));
        ref.invalidate(clientsProvider);
        if (mounted) _showSuccess('Carte supprimée ✓');
      } catch (e) {
        if (mounted) _showError(e.toString());
      } finally {
        if (mounted) setState(() => _deletingCarte = false);
      }
    }
  }

  Future<void> _changerPhoto() async {
    await _choisirPhoto();
    if (_photoBytes == null) return;
    setState(() => _uploadingPhoto = true);
    try {
      await ref.read(fichierRepositoryProvider)
          .uploadPhotoClient(widget.clientId, _photoBytes!, _photoFileName!);
      await ref.read(carteRepositoryProvider).genererCarte(widget.clientId);
      ref.invalidate(_carteProvider(widget.clientId));
      ref.invalidate(clientsProvider);
      if (mounted) _showSuccess('Photo mise à jour ✓');
    } catch (e) {
      if (mounted) _showError(e.toString());
    } finally {
      if (mounted) setState(() { _uploadingPhoto = false; _photoBytes = null; });
    }
  }

  void _showSuccess(String msg) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(msg)),
          ]),
          backgroundColor: AppTheme.success,
          duration: const Duration(seconds: 3),
        ),
      );

  void _showError(String msg) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(msg)),
          ]),
          backgroundColor: AppTheme.error,
          duration: const Duration(seconds: 4),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final carteAsync = ref.watch(_carteProvider(widget.clientId));
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('Carte membre',
            style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          carteAsync.maybeWhen(
            data: (_) => IconButton(
              icon: const Icon(Icons.delete_outline, color: AppTheme.error),
              tooltip: 'Supprimer la carte',
              onPressed: _deletingCarte ? null : _confirmerEtSupprimer,
            ),
            orElse: () => const SizedBox(),
          ),
          carteAsync.maybeWhen(
            data: (_) => IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Régénérer la carte',
              onPressed: _generatingCarte ? null : _confirmerEtRegenerer,
            ),
            orElse: () => const SizedBox(),
          ),
        ],
      ),
      body: carteAsync.when(
        loading: () => const LoadingOverlay(),
        error: (Object e, StackTrace s) => _EmissionView(
          client:           widget.client,
          photoBytes:       _photoBytes,
          photoUrl:         _photoUrl,
          hasPhotoServeur:  _hasPhotoServeur,
          uploadingPhoto:   _uploadingPhoto,
          generatingCarte:  _generatingCarte,
          onChoisirPhoto:   _choisirPhoto,
          onAnnulerPhoto:   () => setState(() { _photoBytes = null; _photoFileName = null; }),
          onEmettreCarte:   _emettreCarteAction,
        ),
        data: (carte) => _PreviewView(
          carte:          carte,
          uploadingPhoto: _uploadingPhoto,
          onChangerPhoto: _changerPhoto,
        ),
      ),
    );
  }
}

// ─── Vue émission (pas encore de carte) ──────────────────────────────────────

class _EmissionView extends StatelessWidget {
  final ClientModel client;
  final Uint8List?  photoBytes;
  final String?     photoUrl;
  final bool        hasPhotoServeur;
  final bool        uploadingPhoto;
  final bool        generatingCarte;
  final VoidCallback onChoisirPhoto;
  final VoidCallback onAnnulerPhoto;
  final VoidCallback onEmettreCarte;

  const _EmissionView({
    required this.client,
    required this.photoBytes,
    required this.photoUrl,
    required this.hasPhotoServeur,
    required this.uploadingPhoto,
    required this.generatingCarte,
    required this.onChoisirPhoto,
    required this.onAnnulerPhoto,
    required this.onEmettreCarte,
  });

  bool get _hasAnyPhoto => photoBytes != null || hasPhotoServeur;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Émettre une carte membre',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(client.fullName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 15, color: AppTheme.textSecondary)),
              const SizedBox(height: 28),

              // Étape 1 : photo
              _StepCard(
                step: '1', title: 'Photo du membre',
                subtitle: 'Format portrait recommandé',
                done: _hasAnyPhoto,
                child: _PhotoPickerZone(
                  photoBytes:     photoBytes,
                  photoUrl:       photoUrl,
                  hasPhotoServeur: hasPhotoServeur,
                  onChoisir:      onChoisirPhoto,
                  onAnnuler:      photoBytes != null ? onAnnulerPhoto : null,
                ),
              ),
              const SizedBox(height: 16),

              // Étape 2 : émettre
              _StepCard(
                step: '2', title: 'Émettre la carte',
                subtitle: 'Génère le numéro membre et le QR code',
                done: false,
                child: _EmettreZone(
                  hasPhoto:       _hasAnyPhoto,
                  uploading:      uploadingPhoto,
                  generating:     generatingCarte,
                  onEmettre:      onEmettreCarte,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Zone sélection photo ─────────────────────────────────────────────────────

class _PhotoPickerZone extends StatelessWidget {
  final Uint8List?   photoBytes;
  final String?      photoUrl;
  final bool         hasPhotoServeur;
  final VoidCallback onChoisir;
  final VoidCallback? onAnnuler;

  const _PhotoPickerZone({
    required this.photoBytes,
    required this.photoUrl,
    required this.hasPhotoServeur,
    required this.onChoisir,
    required this.onAnnuler,
  });

  bool get _hasAny => photoBytes != null || hasPhotoServeur;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Cadre portrait 110×140
        Center(
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 110, height: 140,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _hasAny
                        ? AppTheme.primary.withValues(alpha: 0.4)
                        : AppTheme.border,
                    width: 2,
                  ),
                  color: AppTheme.surface,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: _buildPhoto(),
                ),
              ),
              if (_hasAny)
                Positioned(
                  right: -6, bottom: -6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                        color: AppTheme.success, shape: BoxShape.circle),
                    child: const Icon(Icons.check, color: Colors.white, size: 14),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        OutlinedButton.icon(
          onPressed: onChoisir,
          icon: const Icon(Icons.upload_file_outlined),
          label: Text(_hasAny ? 'Changer la photo' : 'Choisir une photo'),
        ),
        if (onAnnuler != null) ...[
          const SizedBox(height: 6),
          TextButton.icon(
            onPressed: onAnnuler,
            icon: const Icon(Icons.delete_outline, color: AppTheme.error, size: 16),
            label: const Text('Annuler la sélection',
                style: TextStyle(color: AppTheme.error, fontSize: 12)),
          ),
        ],
        const SizedBox(height: 6),
        const Text('JPEG, PNG, WEBP — max 5 Mo',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
      ],
    );
  }

  Widget _buildPhoto() {
    if (photoBytes != null) {
      return Image.memory(photoBytes!, width: 110, height: 140, fit: BoxFit.cover);
    }
    if (hasPhotoServeur && photoUrl != null) {
      return Image.network(
        photoUrl!, width: 110, height: 140, fit: BoxFit.cover,
        loadingBuilder: (_, child, progress) =>
            progress == null ? child : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        errorBuilder: (BuildContext ctx, Object e, StackTrace? s) =>
            const Center(child: Icon(Icons.broken_image, size: 40, color: AppTheme.textSecondary)),
      );
    }
    return const Center(child: Icon(Icons.person, size: 48, color: AppTheme.textSecondary));
  }
}

// ─── Zone émission ────────────────────────────────────────────────────────────

class _EmettreZone extends StatelessWidget {
  final bool hasPhoto, uploading, generating;
  final VoidCallback onEmettre;

  const _EmettreZone({
    required this.hasPhoto,
    required this.uploading,
    required this.generating,
    required this.onEmettre,
  });

  @override
  Widget build(BuildContext context) {
    final busy = uploading || generating;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!hasPhoto)
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.warning_amber_outlined, color: AppTheme.warning, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Vous pouvez émettre sans photo, mais la carte sera incomplète.',
                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: busy ? null : onEmettre,
          icon: busy
              ? const SizedBox(width: 18, height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.credit_card),
          label: Text(uploading ? 'Upload photo…'
              : generating    ? 'Génération…'
                              : 'Émettre la carte'),
        ),
      ],
    );
  }
}

// ─── Vue prévisualisation (carte émise) ──────────────────────────────────────

class _PreviewView extends StatelessWidget {
  final CarteModel   carte;
  final bool         uploadingPhoto;
  final VoidCallback onChangerPhoto;

  const _PreviewView({
    required this.carte,
    required this.uploadingPhoto,
    required this.onChangerPhoto,
  });

  @override
  Widget build(BuildContext context) {
    final isWide   = MediaQuery.of(context).size.width >= 700;
    final qrBytes  = _decodeBase64(carte.qrCodeBase64);
    final photoUrl = carte.cheminPhoto.isNotEmpty
        ? FichierRepository.urlPhoto(carte.cheminPhoto)
        : null;

    final carteWidget = _CarteVisuelle(
      carte: carte, qrBytes: qrBytes, photoUrl: photoUrl,
      uploadingPhoto: uploadingPhoto, onChangerPhoto: onChangerPhoto,
    );
    final infosWidget = _CarteInfos(carte: carte);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: isWide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: carteWidget),
                const SizedBox(width: 20),
                Expanded(flex: 2, child: infosWidget),
              ],
            )
          : Column(children: [carteWidget, const SizedBox(height: 20), infosWidget]),
    );
  }

  static Uint8List? _decodeBase64(String b64) {
    try { return base64Decode(b64); } catch (_) { return null; }
  }
}

// ─── Partie visuelle (carte + actions) ───────────────────────────────────────

class _CarteVisuelle extends StatefulWidget {
  final CarteModel   carte;
  final Uint8List?   qrBytes;
  final String?      photoUrl;
  final bool         uploadingPhoto;
  final VoidCallback onChangerPhoto;

  const _CarteVisuelle({
    required this.carte,
    required this.qrBytes,
    required this.photoUrl,
    required this.uploadingPhoto,
    required this.onChangerPhoto,
  });

  @override
  State<_CarteVisuelle> createState() => _CarteVisuelleState();
}

class _CarteVisuelleState extends State<_CarteVisuelle> {
  final _cardKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        LayoutBuilder(builder: (_, constraints) {
          final available = constraints.maxWidth;
          final w = available > CarteTheme.maxPreviewWidth
              ? CarteTheme.maxPreviewWidth
              : available;
          final h = w * CarteTheme.isoRatio;
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 20),
            decoration: BoxDecoration(
              color: const Color(0xFF111928).withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border),
            ),
            child: Center(
              child: RepaintBoundary(
                key: _cardKey,
                child: _CarteISO(
                  width: w,
                  height: h,
                  carte: widget.carte,
                  qrBytes: widget.qrBytes,
                  photoUrl: widget.photoUrl,
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 14),
        _PhotoStatusCard(
            photoUrl: widget.photoUrl,
            uploading: widget.uploadingPhoto,
            onChanger: widget.onChangerPhoto),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showQr(context),
                icon: const Icon(Icons.qr_code_2),
                label: const Text('QR code'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _imprimer(context),
                icon: const Icon(Icons.print),
                label: const Text('Imprimer'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showQr(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.carte.nomComplet,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              Text(widget.carte.numeroMembre,
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontFamily: 'monospace')),
              const SizedBox(height: 16),
              widget.qrBytes != null
                  ? SizedBox(width: 240, height: 240,
                      child: Image.memory(widget.qrBytes!, fit: BoxFit.contain))
                  : const Icon(Icons.qr_code_2, size: 80),
              const SizedBox(height: 12),
              const Text('Scannez pour vérifier l\'identité du membre',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              const SizedBox(height: 16),
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Fermer')),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _imprimer(BuildContext context) async {
    try {
      final pdf = await CartePdfService.genererPdf(
        widget.carte,
        cardKey: _cardKey,
      );
      await Printing.layoutPdf(
        onLayout: (_) async => pdf,
        name: 'carte-${widget.carte.numeroMembre}.pdf',
        format: PdfPageFormat(
          CarteTheme.pdfCardW,
          CarteTheme.pdfCardH,
          marginAll: 0,
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur impression : $e'),
              backgroundColor: AppTheme.error),
        );
      }
    }
  }
}

// ─── Card statut photo ────────────────────────────────────────────────────────

class _PhotoStatusCard extends StatelessWidget {
  final String?      photoUrl;
  final bool         uploading;
  final VoidCallback onChanger;

  const _PhotoStatusCard({
    required this.photoUrl,
    required this.uploading,
    required this.onChanger,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            photoUrl != null
                ? _MiniAvatar(photoUrl: photoUrl!)
                : Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.no_photography_outlined,
                        color: AppTheme.warning, size: 20),
                  ),
            const SizedBox(width: 12),
            Expanded(
              child: photoUrl != null
                  ? const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Photo du membre',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        Text('Photo enregistrée ✓',
                            style: TextStyle(fontSize: 11, color: AppTheme.success)),
                      ],
                    )
                  : const Text('Aucune photo — ajoutez-en une',
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            ),
            uploading
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : TextButton.icon(
                    onPressed: onChanger,
                    icon: const Icon(Icons.upload_outlined, size: 14),
                    label: Text(photoUrl != null ? 'Changer' : 'Ajouter',
                        style: const TextStyle(fontSize: 12)),
                  ),
          ],
        ),
      ),
    );
  }
}

// ─── Logo République Togolaise ────────────────────────────────────────────────

class _TogoLogoBadge extends StatelessWidget {
  final double height;

  const _TogoLogoBadge({required this.height});

  @override
  Widget build(BuildContext context) {
    final w = height * 0.75;
    final radius = height * 0.10;
    return Container(
      width: w,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: height * 0.12,
            spreadRadius: height * 0.01,
            offset: Offset(0, height * 0.04),
          ),
          BoxShadow(
            color: CarteTheme.goldAccent.withValues(alpha: 0.15),
            blurRadius: height * 0.06,
            offset: Offset(0, 0),
          ),
        ],
        border: Border.all(
          color: CarteTheme.goldAccent.withValues(alpha: 0.40),
          width: 1.0,
        ),
      ),
      padding: EdgeInsets.all(height * 0.05),
      child: Image.asset(
        CarteTheme.logoTogoAsset,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      ),
    );
  }
}

// ─── Badge institutionnel simplifié ───────────────────────────────────────────────

class _InstitutionLogoBadge extends StatelessWidget {
  final double size;

  const _InstitutionLogoBadge({required this.size});

  @override
  Widget build(BuildContext context) {
    final radius = size * 0.16;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        // Dégradé or/vert pour effet premium
        gradient: const LinearGradient(
          colors: [Color(0xFF1B7A4E), Color(0xFF009060), Color(0xFF00B070)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: CarteTheme.goldAccent.withValues(alpha: 0.35),
            blurRadius: size * 0.14,
            spreadRadius: size * 0.02,
            offset: Offset(0, size * 0.04),
          ),
          BoxShadow(
            color: CarteTheme.greenStart.withValues(alpha: 0.25),
            blurRadius: size * 0.10,
            offset: Offset(0, size * 0.02),
          ),
        ],
        border: Border.all(
          color: CarteTheme.goldAccent.withValues(alpha: 0.55),
          width: size * 0.035,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius * 0.85),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Reflet haut subtil
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: size * 0.40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.18),
                      Colors.white.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
            // Logo institutionnel centré
            Text(
              CarteTheme.institutionShort,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: CarteTheme.goldAccent,
                fontWeight: FontWeight.w900,
                fontSize: size * 0.42,
                letterSpacing: 3.0,
                height: 1.0,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    offset: Offset(0, size * 0.02),
                    blurRadius: size * 0.05,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Carte ISO 7810 ───────────────────────────────────────────────────────────
//
//  Layout interne :
//
//   ┌──────────────────────────────────────────────────────────────┐
//   │ [Logo RT] [ED]  ENTREPRENARIAT & DÉVELOPPEMENT    [QR code] │
//   │                 CARTE MEMBRE                                 │
//   │······························································│
//   │ [Photo]  NOM COMPLET                                         │
//   │          N° MEMBRE   N° CLIENT                               │
//   │          EXPIRE      TÉL.                                    │
//   └──────────────────────────────────────────────────────────────┘
//
//  Toutes les dimensions sont proportionnelles à `height` pour que la carte
//  soit rendue correctement quelle que soit la largeur d'écran.

class _CarteISO extends StatelessWidget {
  final double     width, height;
  final CarteModel carte;
  final Uint8List? qrBytes;
  final String?    photoUrl;

  // Constantes de proportions
  static const double _px        = 0.05;   // padding horizontal / width
  static const double _py        = 0.08;   // padding vertical   / height
  static const double _logoRatio = 0.22;   // badge ED           / height
  static const double _togoRatio = 0.26;   // logo RT            / height
  static const double _qrRatio   = 0.24;   // QR size            / height
  static const double _photoH    = 0.40;   // photo height       / height
  static const double _photoW    = 0.75;   // photo width        / photo height (portrait 3:4)

  const _CarteISO({
    required this.width,
    required this.height,
    required this.carte,
    required this.qrBytes,
    required this.photoUrl,
  });

  @override
  Widget build(BuildContext context) {
    final radius = CarteTheme.borderRadius(height);
    final innerRadius = CarteTheme.innerBorderRadius(height);

    return Container(
      width: width, height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: CarteTheme.cardGradient,
        boxShadow: [
          // Ombre profonde
          BoxShadow(
            color: CarteTheme.greenStart.withValues(alpha: 0.35),
            blurRadius: height * 0.20,
            spreadRadius: height * 0.02,
            offset: Offset(0, height * 0.08),
          ),
          // Ombre légère
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: height * 0.06,
            offset: Offset(0, height * 0.02),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Décoration : grand cercle haut-droite
          Positioned(
            right: -width * 0.12, top: -height * 0.40,
            child: _circle(height * 1.20, alpha: 0.07),
          ),
          // Décoration : cercle moyen haut-gauche
          Positioned(
            left: -width * 0.10, top: -height * 0.20,
            child: _circle(height * 0.60, alpha: 0.06),
          ),
          // Décoration : petit cercle bas-gauche
          Positioned(
            left: -width * 0.04, bottom: -height * 0.25,
            child: _circle(height * 0.80, alpha: 0.05),
          ),
          // Décoration : cercle bas-droit subtil
          Positioned(
            right: -width * 0.05, bottom: -height * 0.15,
            child: _circle(height * 0.50, alpha: 0.06),
          ),
          // Décoration : ligne diagonale subtile
          Positioned.fill(child: CustomPaint(painter: _DiagonalPainter())),
          // Bande or en bas (effet carte premium)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: height * 0.028,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    CarteTheme.goldAccent.withValues(alpha: 0.0),
                    CarteTheme.goldAccent.withValues(alpha: 0.35),
                    CarteTheme.goldAccent.withValues(alpha: 0.55),
                    CarteTheme.goldAccent.withValues(alpha: 0.35),
                    CarteTheme.goldAccent.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          // Bordure intérieure premium avec effet glossy
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(1.5),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(innerRadius),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.22),
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),
          // Effet de reflet haute lumière (haut-gauche → haut)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: height * 0.38,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(radius),
                  topRight: Radius.circular(radius),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.10),
                    Colors.white.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),

          // Contenu
          Padding(
            padding: EdgeInsets.symmetric(
                horizontal: width * _px, vertical: height * _py),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                SizedBox(height: height * 0.022),
                _buildSeparator(),
                const Spacer(),
                _buildFooter(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _circle(double size, {required double alpha}) => Container(
        width: size, height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: alpha),
        ),
      );

  Widget _buildSeparator() => SizedBox(
        height: 2,
        width: double.infinity,
        child: CustomPaint(painter: _GoldDashedLinePainter()),
      );

  // ── Header : logo + institution + QR ──────────────────────────────────────

  Widget _buildHeader() {
    final badgeSize = height * _logoRatio;
    final togoH     = height * _togoRatio;
    final qrSize    = height * _qrRatio;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Logo RT (République Togolaise)
        _TogoLogoBadge(height: togoH),
        SizedBox(width: width * 0.018),

        // Badge ED
        _InstitutionLogoBadge(size: badgeSize),
        SizedBox(width: width * 0.018),

        // Texte institution
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ENTREPRENARIAT &',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: height * 0.065,
                          letterSpacing: 0.5,
                          height: 1.08,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.20),
                              offset: Offset(0, 1),
                              blurRadius: 3,
                            ),
                          ],
                        )),
                    Text('DÉVELOPPEMENT',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: height * 0.065,
                          letterSpacing: 0.5,
                          height: 1.08,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.20),
                              offset: Offset(0, 1),
                              blurRadius: 3,
                            ),
                          ],
                        )),
                  ],
                ),
              ),
              SizedBox(height: height * 0.006),
              // Ligne or sous le nom
              Container(
                height: height * 0.018,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      CarteTheme.goldAccent.withValues(alpha: 0.85),
                      CarteTheme.goldAccent.withValues(alpha: 0.10),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: height * 0.005),
              Text(
                CarteTheme.cardSubtitle,
                style: TextStyle(
                  color: CarteTheme.goldAccent.withValues(alpha: 0.92),
                  fontSize: height * 0.050,
                  letterSpacing: 2.2,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),

        SizedBox(width: width * 0.012),
        _buildQrBox(qrSize),
      ],
    );
  }

  Widget _buildQrBox(double qrSize) {
    return Container(
      width: qrSize,
      height: qrSize,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(qrSize * 0.12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.20),
            blurRadius: qrSize * 0.10,
            spreadRadius: qrSize * 0.01,
            offset: Offset(0, qrSize * 0.04),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.25),
          width: 1.2,
        ),
      ),
      padding: EdgeInsets.all(qrSize * 0.08),
      child: qrBytes != null
          ? Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(qrSize * 0.06),
              ),
              child: Image.memory(qrBytes!, fit: BoxFit.contain),
            )
          : Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(qrSize * 0.06),
              ),
              child: Icon(Icons.qr_code_2, color: Colors.grey.shade400, size: qrSize * 0.68),
            ),
    );
  }

  // ── Footer : photo + identité ──────────────────────────────────────────────

  Widget _buildFooter() {
    final ph = height * _photoH;
    final pw = ph * _photoW;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Photo portrait
        _CartePhoto(photoUrl: photoUrl, w: pw, h: ph),
        SizedBox(width: width * 0.035),

        // Identité
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              LayoutBuilder(
                builder: (_, constraints) => FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: constraints.maxWidth),
                    child: Text(
                      carte.nomComplet.toUpperCase(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: height * 0.09,
                        height: 1.12,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: height * 0.018),
              Container(
                height: 1,
                color: Colors.white.withValues(alpha: 0.25),
                margin: EdgeInsets.only(bottom: height * 0.018),
              ),
              Row(
                children: [
                  Expanded(
                    child: _field('N° MEMBRE', carte.numeroMembre,
                        height * 0.060, monospace: true),
                  ),
                  SizedBox(width: width * 0.025),
                  Expanded(
                    child: _field('N° CLIENT', carte.numeroClient,
                        height * 0.060, monospace: true),
                  ),
                ],
              ),
              SizedBox(height: height * 0.012),
              Row(
                children: [
                  Expanded(
                    child: _field(
                      'EXPIRE',
                      _shortDate(carte.dateExpiration),
                      height * 0.055,
                    ),
                  ),
                  SizedBox(width: width * 0.025),
                  Expanded(
                    child: carte.telephone.isNotEmpty
                        ? FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: _field(
                              'TÉL.',
                              carte.telephone,
                              height * 0.055,
                              align: TextAlign.right,
                            ),
                          )
                        : _field('TÉL.', '—', height * 0.055,
                            align: TextAlign.right),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _field(String label, String value, double fs,
      {bool monospace = false, TextAlign align = TextAlign.left}) {
    return Column(
      crossAxisAlignment: align == TextAlign.right
          ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: fs * 0.72, letterSpacing: 1.0, fontWeight: FontWeight.w500,
            )),
        const SizedBox(height: 1),
        Text(value,
            textAlign: align,
            style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.w700,
              fontSize: monospace ? fs * 0.95 : fs,
              fontFamily: monospace ? 'monospace' : null,
              letterSpacing: monospace ? 0.8 : 0,
            )),
      ],
    );
  }

  String _shortDate(String iso) {
    try {
      final d = DateTime.parse(iso);
      return '${d.month.toString().padLeft(2, '0')}/${d.year}';
    } catch (_) { return iso; }
  }
}

// ─── Photo sur la carte ───────────────────────────────────────────────────────
//
//  • `w` et `h` sont calculés par le parent — pas de recalcul ici
//  • L'erreur bascule sur l'icône directement dans errorBuilder (pas de setState
//    en dehors du build via addPostFrameCallback, ce qui était une pratique risquée)

class _CartePhoto extends StatelessWidget {
  final String? photoUrl;
  final double  w, h;

  const _CartePhoto({required this.photoUrl, required this.w, required this.h});

  @override
  Widget build(BuildContext context) {
    final borderRadius = h * 0.08;
    final borderDeco = BoxDecoration(
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: Colors.white.withValues(alpha: 0.70),
        width: 2.0,
      ),
      color: Colors.white.withValues(alpha: 0.10),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.25),
          blurRadius: h * 0.12,
          spreadRadius: h * 0.01,
          offset: Offset(0, h * 0.06),
        ),
      ],
    );

    Widget child;
    if (photoUrl != null) {
      child = Image.network(
        photoUrl!,
        width: w, height: h,
        fit: BoxFit.cover,
        loadingBuilder: (_, c, progress) =>
            progress == null ? c : _spinner(),
        // errorBuilder synchrone : pas de setState, renvoie directement le fallback
        errorBuilder: (BuildContext ctx, Object e, StackTrace? s) => _placeholder(),
      );
    } else {
      child = _placeholder();
    }

    return Container(
      width: w, height: h,
      decoration: borderDeco,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius - 2),
        child: child,
      ),
    );
  }

  Widget _placeholder() => Center(
        child: Icon(Icons.person_rounded, color: Colors.white54, size: h * 0.45),
      );

  Widget _spinner() => Center(
        child: SizedBox(
          width: h * 0.24, height: h * 0.24,
          child: const CircularProgressIndicator(
              strokeWidth: 2, color: Colors.white60),
        ),
      );
}

// ─── Ligne pointillée dorée (séparateur premium) ──────────────────────────────

class _GoldDashedLinePainter extends CustomPainter {
  _GoldDashedLinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    const goldColor = CarteTheme.goldAccent;
    final paintGold = Paint()
      ..color = goldColor.withValues(alpha: 0.65)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    final paintFaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    const dash = 6.0;
    const gap = 4.0;
    var x = 0.0;
    var toggle = true;
    while (x < size.width) {
      final end = (x + dash).clamp(0.0, size.width);
      canvas.drawLine(
        Offset(x, size.height / 2),
        Offset(end, size.height / 2),
        toggle ? paintGold : paintFaint,
      );
      x += dash + gap;
      toggle = !toggle;
    }
  }

  @override
  bool shouldRepaint(covariant _GoldDashedLinePainter oldDelegate) => false;
}

// ─── Décoration diagonale ─────────────────────────────────────────────────────

class _DiagonalPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawLine(
      Offset(0, size.height * 0.9),
      Offset(size.width * 0.85, 0),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.04)
        ..strokeWidth = size.height * 0.18
        ..style = PaintingStyle.stroke,
    );
  }
  @override
  bool shouldRepaint(covariant _DiagonalPainter oldDelegate) => false;
}

// ─── Mini-avatar (card statut photo) ─────────────────────────────────────────

class _MiniAvatar extends StatefulWidget {
  final String photoUrl;
  const _MiniAvatar({required this.photoUrl});
  @override
  State<_MiniAvatar> createState() => _MiniAvatarState();
}

class _MiniAvatarState extends State<_MiniAvatar> {
  bool _error = false;

  @override
  Widget build(BuildContext context) {
    if (_error) {
      return const CircleAvatar(
        radius: 20, backgroundColor: AppTheme.primaryLight,
        child: Icon(Icons.person, size: 20, color: AppTheme.primary),
      );
    }
    return CircleAvatar(
      radius: 20, backgroundColor: AppTheme.primaryLight,
      backgroundImage: NetworkImage(widget.photoUrl),
      onBackgroundImageError: (Object e, StackTrace? s) {
        if (mounted) setState(() => _error = true);
      },
    );
  }
}

// ─── Informations détaillées ──────────────────────────────────────────────────

class _CarteInfos extends StatelessWidget {
  final CarteModel carte;
  const _CarteInfos({required this.carte});

  @override
  Widget build(BuildContext context) {
    final expired      = _isExpired(carte.dateExpiration);
    final expiringSoon = !expired && _expiringSoon(carte.dateExpiration);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Informations de la carte',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 14),
            _InfoRow(Icons.badge_outlined,            'N° membre',   carte.numeroMembre, mono: true),
            _InfoRow(Icons.person_outline,            'Titulaire',   carte.nomComplet),
            _InfoRow(Icons.account_balance_outlined,  'N° client',   carte.numeroClient, mono: true),
            if (carte.telephone.isNotEmpty)
              _InfoRow(Icons.phone_outlined,          'Téléphone',   carte.telephone),
            _InfoRow(Icons.event_outlined,            'Expiration',
                _fmt(carte.dateExpiration),
                color: expired ? AppTheme.error : expiringSoon ? AppTheme.warning : null),
            _InfoRow(Icons.history_outlined,          'Émise le',    _fmt(carte.dateGeneration)),
            const Divider(height: 20),
            Row(children: [
              Icon(
                expired      ? Icons.cancel_outlined
                : expiringSoon ? Icons.warning_amber_outlined
                               : Icons.verified_outlined,
                size: 16,
                color: expired ? AppTheme.error : expiringSoon ? AppTheme.warning : AppTheme.success,
              ),
              const SizedBox(width: 8),
              Text(
                expired      ? 'Carte expirée'
                : expiringSoon ? 'Expire dans moins de 90 jours'
                               : 'Carte valide',
                style: TextStyle(
                  color: expired ? AppTheme.error : expiringSoon ? AppTheme.warning : AppTheme.success,
                  fontWeight: FontWeight.w600, fontSize: 13,
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  String _fmt(String iso) {
    try {
      final d = DateTime.parse(iso);
      return '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}';
    } catch (_) { return iso; }
  }

  bool _isExpired(String iso) {
    try { return DateTime.parse(iso).isBefore(DateTime.now()); } catch (_) { return false; }
  }

  bool _expiringSoon(String iso) {
    try {
      final diff = DateTime.parse(iso).difference(DateTime.now()).inDays;
      return diff >= 0 && diff < 90;
    } catch (_) { return false; }
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String   label, value;
  final bool     mono;
  final Color?   color;

  const _InfoRow(this.icon, this.label, this.value,
      {this.mono = false, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 15, color: AppTheme.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
                Text(value,
                    style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600,
                      fontFamily: mono ? 'monospace' : null,
                      color: color ?? AppTheme.textPrimary,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Step card ────────────────────────────────────────────────────────────────

class _StepCard extends StatelessWidget {
  final String step, title, subtitle;
  final bool   done;
  final Widget child;

  const _StepCard({
    required this.step, required this.title, required this.subtitle,
    required this.done,  required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 30, height: 30,
                  decoration: BoxDecoration(
                    color: done ? AppTheme.success : AppTheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: done
                        ? const Icon(Icons.check, color: Colors.white, size: 16)
                        : Text(step, style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                    Text(subtitle, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                  ],
                )),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}
