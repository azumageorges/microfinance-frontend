import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/fichier_repository.dart';

/// Widget d'upload + preview d'une photo.
/// Fonctionne sur Web (file_selector) et Mobile (file_selector aussi).
///
/// Deux modes :
/// - [circle] = true  → avatar rond   (ex: profil)
/// - [circle] = false → rectangle portrait (ex: photo passeport)
class UploadPhotoWidget extends StatefulWidget {
  /// Chemin stocké en base — affiche la photo existante au chargement
  final String? cheminActuel;

  /// Appelé dès qu'un fichier est sélectionné.
  /// Peut être async (upload immédiat) ou synchrone (stockage local différé).
  final Future<void> Function(Uint8List bytes, String filename) onUpload;

  /// Label du bouton texte sous l'aperçu
  final String label;

  /// Taille de référence :
  ///   circle=true  → rayon = size/2  (diamètre = size)
  ///   circle=false → hauteur = size, largeur = size * 0.75 (ratio portrait)
  final double size;

  /// Forme : cercle ou rectangle portrait
  final bool circle;

  const UploadPhotoWidget({
    super.key,
    this.cheminActuel,
    required this.onUpload,
    this.label = 'Changer la photo',
    this.size = 90,
    this.circle = true,
  });

  @override
  State<UploadPhotoWidget> createState() => _UploadPhotoWidgetState();
}

class _UploadPhotoWidgetState extends State<UploadPhotoWidget> {
  bool _loading = false;
  Uint8List? _previewBytes;

  Future<void> _pick() async {
    const typeGroup = XTypeGroup(
      label: 'Images',
      extensions: ['jpg', 'jpeg', 'png', 'webp'],
      mimeTypes: ['image/jpeg', 'image/png', 'image/webp'],
    );

    final file = await openFile(acceptedTypeGroups: [typeGroup]);
    if (file == null) return;

    final bytes = await file.readAsBytes();

    // Affiche la preview immédiatement, avant l'upload
    setState(() => _previewBytes = bytes);

    // Si le callback est long (upload réseau), on affiche le spinner
    setState(() => _loading = true);
    try {
      await widget.onUpload(bytes, file.name);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : $e'),
            backgroundColor: AppTheme.error,
          ),
        );
        // Annule la preview si l'upload a échoué
        setState(() => _previewBytes = null);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto =
        _previewBytes != null || (widget.cheminActuel?.isNotEmpty == true);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: _loading ? null : _pick,
          child: widget.circle
              ? _CirclePreview(
                  size: widget.size,
                  previewBytes: _previewBytes,
                  cheminActuel: widget.cheminActuel,
                  hasPhoto: hasPhoto,
                  loading: _loading,
                )
              : _RectPreview(
                  size: widget.size,
                  previewBytes: _previewBytes,
                  cheminActuel: widget.cheminActuel,
                  hasPhoto: hasPhoto,
                  loading: _loading,
                ),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: _loading ? null : _pick,
          icon: const Icon(Icons.upload_outlined, size: 16),
          label: Text(widget.label, style: const TextStyle(fontSize: 12)),
        ),
      ],
    );
  }
}

// ─── Aperçu circulaire ────────────────────────────────────────────────────────

class _CirclePreview extends StatelessWidget {
  final double size;
  final Uint8List? previewBytes;
  final String? cheminActuel;
  final bool hasPhoto;
  final bool loading;

  const _CirclePreview({
    required this.size,
    required this.previewBytes,
    required this.cheminActuel,
    required this.hasPhoto,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    final photoUrl = (cheminActuel?.isNotEmpty == true)
        ? FichierRepository.urlPhoto(cheminActuel)
        : null;

    ImageProvider? imageProvider;
    if (previewBytes != null) {
      imageProvider = MemoryImage(previewBytes!);
    } else if (photoUrl != null && photoUrl.isNotEmpty) {
      imageProvider = NetworkImage(photoUrl);
    }

    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        CircleAvatar(
          radius: size / 2,
          backgroundColor: AppTheme.primaryLight,
          backgroundImage: imageProvider,
          child: !hasPhoto
              ? Icon(Icons.person, size: size * 0.5, color: AppTheme.primary)
              : null,
        ),
        _Badge(loading: loading),
      ],
    );
  }
}

// ─── Aperçu rectangle portrait ────────────────────────────────────────────────

class _RectPreview extends StatelessWidget {
  final double size;
  final Uint8List? previewBytes;
  final String? cheminActuel;
  final bool hasPhoto;
  final bool loading;

  const _RectPreview({
    required this.size,
    required this.previewBytes,
    required this.cheminActuel,
    required this.hasPhoto,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    // Ratio portrait standard (3:4)
    final w = size * 0.75;
    final h = size;

    final photoUrl = (cheminActuel?.isNotEmpty == true)
        ? FichierRepository.urlPhoto(cheminActuel)
        : null;

    return Stack(
      // Taille fixe pour que le badge ne déborde pas
      clipBehavior: Clip.none,
      children: [
        Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: AppTheme.primaryLight,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: hasPhoto
                  ? AppTheme.primary.withValues(alpha: 0.35)
                  : AppTheme.border,
              width: 1.5,
            ),
          ),
          // ClipRRect assure que l'image respecte le borderRadius
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6.5),
            child: _buildImageContent(w, h, photoUrl),
          ),
        ),
        // Badge caméra en bas à droite, légèrement en dehors du cadre
        Positioned(
          right: -6,
          bottom: -6,
          child: _Badge(loading: loading),
        ),
      ],
    );
  }

  Widget _buildImageContent(double w, double h, String? photoUrl) {
    // 1. Preview locale (bytes en mémoire)
    if (previewBytes != null) {
      return Image.memory(
        previewBytes!,
        width: w,
        height: h,
        fit: BoxFit.cover,
      );
    }

    // 2. Photo existante sur le serveur
    if (photoUrl != null && photoUrl.isNotEmpty) {
      return Image.network(
        photoUrl,
        width: w,
        height: h,
        fit: BoxFit.cover,
        loadingBuilder: (_, child, progress) => progress == null
            ? child
            : Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  value: progress.expectedTotalBytes != null
                      ? progress.cumulativeBytesLoaded /
                          progress.expectedTotalBytes!
                      : null,
                  color: AppTheme.primary,
                ),
              ),
        errorBuilder: (context, error, stackTrace) => _Placeholder(w: w, h: h),
      );
    }

    // 3. Aucune photo
    return _Placeholder(w: w, h: h);
  }
}

// ─── Placeholder quand aucune photo ──────────────────────────────────────────

class _Placeholder extends StatelessWidget {
  final double w, h;
  const _Placeholder({required this.w, required this.h});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: w,
      height: h,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_outline, size: h * 0.35, color: AppTheme.primary),
          const SizedBox(height: 4),
          Text(
            'Ajouter\nune photo',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: h * 0.085,
              color: AppTheme.textSecondary,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Badge caméra ─────────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  final bool loading;
  const _Badge({required this.loading});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: AppTheme.primary,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: loading
          ? const Padding(
              padding: EdgeInsets.all(5),
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.camera_alt, color: Colors.white, size: 14),
    );
  }
}
