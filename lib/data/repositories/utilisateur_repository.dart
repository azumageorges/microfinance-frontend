import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../models/utilisateur_model.dart';

class UtilisateurRepository {
  final ApiClient _apiClient;

  UtilisateurRepository(this._apiClient);

  Future<List<UtilisateurModel>> getUtilisateurs() async {
    try {
      final res = await _apiClient.dio.get('/api/utilisateurs');
      return (res.data['data'] as List)
          .map((e) => UtilisateurModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<UtilisateurModel> createUtilisateur(
      Map<String, dynamic> data) async {
    try {
      final res =
          await _apiClient.dio.post('/api/utilisateurs', data: data);
      return UtilisateurModel.fromJson(
          res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<UtilisateurModel> toggleActif(int id) async {
    try {
      final res =
          await _apiClient.dio.patch('/api/utilisateurs/$id/toggle-actif');
      return UtilisateurModel.fromJson(
          res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<UtilisateurModel> updateUtilisateur(
    int id,
    Map<String, dynamic> data,
  ) async {
    try {
      final res = await _apiClient.dio.patch(
        '/api/utilisateurs/$id',
        data: data,
      );
      return UtilisateurModel.fromJson(
          res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> changerMotDePasse(
    int id, {
    required String ancien,
    required String nouveau,
  }) async {
    try {
      await _apiClient.dio.patch(
        '/api/utilisateurs/$id/changer-mot-de-passe',
        data: {'ancienMotDePasse': ancien, 'nouveauMotDePasse': nouveau},
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
