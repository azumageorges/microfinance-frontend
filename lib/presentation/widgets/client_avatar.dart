import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/fichier_repository.dart';

/// Avatar circulaire d'un client.
///
/// Affiche la photo passeport si [cheminPhoto] est renseigné,
/// avec fallback sur l'initiale du [fullName] en cas d'absence ou d'erreur.
class ClientAvatar extends StatelessWidget {
  final String fullName;
  final String? cheminPhoto;
  final double radius;

  const ClientAvatar({
    super.key,
    required this.fullName,
    required this.cheminPhoto,
    this.radius = 22,
  });

  @override
  Widget build(BuildContext context) {
    final photoUrl = (cheminPhoto != null && cheminPhoto!.isNotEmpty)
        ? FichierRepository.urlPhoto(cheminPhoto)
        : null;

    final initial = fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';
    final fontSize = radius * 0.78;

    final fallback = CircleAvatar(
      radius: radius,
      backgroundColor: AppTheme.primaryLight,
      child: Text(
        initial,
        style: TextStyle(
          color: AppTheme.primary,
          fontWeight: FontWeight.w700,
          fontSize: fontSize,
        ),
      ),
    );

    if (photoUrl == null) return fallback;

    return _NetworkAvatar(
      photoUrl: photoUrl,
      radius: radius,
      fallback: fallback,
    );
  }
}

class _NetworkAvatar extends StatefulWidget {
  final String photoUrl;
  final double radius;
  final Widget fallback;

  const _NetworkAvatar({
    required this.photoUrl,
    required this.radius,
    required this.fallback,
  });

  @override
  State<_NetworkAvatar> createState() => _NetworkAvatarState();
}

class _NetworkAvatarState extends State<_NetworkAvatar> {
  late ImageProvider _provider;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(_NetworkAvatar old) {
    super.didUpdateWidget(old);
    if (old.photoUrl != widget.photoUrl) {
      setState(() => _hasError = false);
      _loadImage();
    }
  }

  void _loadImage() {
    _provider = NetworkImage(widget.photoUrl);
    final stream = _provider.resolve(ImageConfiguration.empty);
    stream.addListener(
      ImageStreamListener(
        (ImageInfo info, bool sync) {},
        onError: (Object e, StackTrace? s) {
          if (mounted) setState(() => _hasError = true);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) return widget.fallback;

    return CircleAvatar(
      radius: widget.radius,
      backgroundColor: AppTheme.primaryLight,
      backgroundImage: _provider,
    );
  }
}
