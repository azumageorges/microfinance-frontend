import '../../core/network/api_client.dart';
import '../../core/network/api_request.dart';
import '../models/utilisateur_model.dart';

class UtilisateurRepository {
  final ApiClient _apiClient;

  UtilisateurRepository(this._apiClient);

  Future<List<UtilisateurModel>> getUtilisateurs() {
    return guardApi(() async => parseList(
          await _apiClient.dio.get('/api/utilisateurs'),
          UtilisateurModel.fromJson,
        ));
  }

  Future<UtilisateurModel> createUtilisateur(Map<String, dynamic> data) {
    return guardApi(() async => parseItem(
          await _apiClient.dio.post('/api/utilisateurs', data: data),
          UtilisateurModel.fromJson,
        ));
  }

  Future<UtilisateurModel> toggleActif(int id) {
    return guardApi(() async => parseItem(
          await _apiClient.dio.patch('/api/utilisateurs/$id/toggle-actif'),
          UtilisateurModel.fromJson,
        ));
  }

  Future<UtilisateurModel> updateUtilisateur(
    int id,
    Map<String, dynamic> data,
  ) {
    return guardApi(() async => parseItem(
          await _apiClient.dio.patch('/api/utilisateurs/$id', data: data),
          UtilisateurModel.fromJson,
        ));
  }

  Future<void> changerMotDePasse(
    int id, {
    required String ancien,
    required String nouveau,
  }) {
    return guardApi(() => _apiClient.dio.patch(
          '/api/utilisateurs/$id/changer-mot-de-passe',
          data: {'ancienMotDePasse': ancien, 'nouveauMotDePasse': nouveau},
        ));
  }
}
