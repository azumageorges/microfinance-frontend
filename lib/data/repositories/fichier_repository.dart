import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
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
  Future<void> uploadPhotoClient(int clientId, Uint8List bytes,
      String filename) async {
    try {
      final formData = FormData.fromMap({
        'fichier': MultipartFile.fromBytes(
          bytes,
          filename: filename,
          contentType: DioMediaType('image', _ext(filename)),
        ),
      });
      await _apiClient.dio.patch(
        '/api/clients/$clientId/photo',
        data: formData,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Upload la pièce d'identité d'un client
  Future<void> uploadPieceIdentite(int clientId, Uint8List bytes,
      String filename) async {
    try {
      final formData = FormData.fromMap({
        'fichier': MultipartFile.fromBytes(
          bytes,
          filename: filename,
          contentType: DioMediaType('image', _ext(filename)),
        ),
      });
      await _apiClient.dio.patch(
        '/api/clients/$clientId/piece-identite',
        data: formData,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  String _ext(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.png')) return 'png';
    if (lower.endsWith('.webp')) return 'webp';
    return 'jpeg';
  }
}
