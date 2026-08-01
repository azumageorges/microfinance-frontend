import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_request.dart';
import '../../core/constants/app_constants.dart';

class FichierRepository {
  final ApiClient _apiClient;

  FichierRepository(this._apiClient);

  /// Retourne l'URL complète d'un fichier pour affichage (Image.network)
  static String urlPhoto(String? chemin) {
    if (chemin == null || chemin.isEmpty) return '';
    final base = AppConstants.baseUrl;
    return '$base/api/fichiers?chemin=${Uri.encodeComponent(chemin)}';
  }

  /// Upload la photo d'un client
  Future<void> uploadPhotoClient(
          int clientId, Uint8List bytes, String filename) =>
      _upload('/api/clients/$clientId/photo', bytes, filename);

  /// Upload la pièce d'identité d'un client
  Future<void> uploadPieceIdentite(
          int clientId, Uint8List bytes, String filename) =>
      _upload('/api/clients/$clientId/piece-identite', bytes, filename);

  Future<void> _upload(String path, Uint8List bytes, String filename) {
    return guardApi(() => _apiClient.dio.patch(
          path,
          data: FormData.fromMap({
            'fichier': MultipartFile.fromBytes(
              bytes,
              filename: filename,
              contentType: DioMediaType('image', _ext(filename)),
            ),
          }),
        ));
  }

  String _ext(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.png')) return 'png';
    if (lower.endsWith('.webp')) return 'webp';
    return 'jpeg';
  }
}
