import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../models/client_model.dart';

class ClientRepository {
  final ApiClient _apiClient;

  ClientRepository(this._apiClient);

  Future<List<ClientModel>> getClients() async {
    try {
      final res = await _apiClient.dio.get('/api/clients');
      return (res.data['data'] as List)
          .map((e) => ClientModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<ClientModel> getClientById(int id) async {
    try {
      final res = await _apiClient.dio.get('/api/clients/$id');
      return ClientModel.fromJson(res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<ClientModel>> searchClients(String query) async {
    try {
      final res = await _apiClient.dio
          .get('/api/clients/recherche', queryParameters: {'q': query});
      return (res.data['data'] as List)
          .map((e) => ClientModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<ClientModel> createClient(Map<String, dynamic> data) async {
    try {
      final res = await _apiClient.dio.post('/api/clients', data: data);
      return ClientModel.fromJson(res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<ClientModel> updateClient(int id, Map<String, dynamic> data) async {
    try {
      // PATCH côté backend pour éviter d'écraser les champs non envoyés (null)
      // quand on corrige seulement 1 ou 2 informations depuis le bureau.
      final res = await _apiClient.dio.patch('/api/clients/$id', data: data);
      return ClientModel.fromJson(res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<ClientModel> updateStatut(int id, String statut) async {
    try {
      final res = await _apiClient.dio.patch(
        '/api/clients/$id/statut',
        queryParameters: {'statut': statut},
      );
      return ClientModel.fromJson(res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
