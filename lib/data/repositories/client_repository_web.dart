import '../../core/network/api_client.dart';
import '../models/client_model.dart';
import 'client_repository_interface.dart';

/// Repository pour le Web - utilise uniquement l'API Spring Boot
/// Pas de SQLite, pas de mode offline
class ClientRepositoryWeb implements IClientRepository {
  final ApiClient _apiClient;

  ClientRepositoryWeb(this._apiClient);

  @override
  Future<List<ClientModel>> getClients() async {
    final res = await _apiClient.dio.get('/api/clients');
    return (res.data['data'] as List)
        .map((e) => ClientModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<ClientModel> getClientById(int id) async {
    final res = await _apiClient.dio.get('/api/clients/$id');
    return ClientModel.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  @override
  Future<List<ClientModel>> searchClients(String query) async {
    if (query.trim().isEmpty) return getClients();

    final res = await _apiClient.dio
        .get('/api/clients/recherche', queryParameters: {'q': query});
    return (res.data['data'] as List)
        .map((e) => ClientModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<ClientModel> createClient(Map<String, dynamic> data) async {
    final res = await _apiClient.dio.post('/api/clients', data: data);
    return ClientModel.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  @override
  Future<ClientModel> updateClient(int id, Map<String, dynamic> data) async {
    final res = await _apiClient.dio.patch('/api/clients/$id', data: data);
    return ClientModel.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  @override
  Future<ClientModel> updateStatut(int id, String statut) async {
    final res = await _apiClient.dio.patch(
      '/api/clients/$id/statut',
      queryParameters: {'statut': statut},
    );
    return ClientModel.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  @override
  Future<void> deleteClient(int id) async {
    await _apiClient.dio.delete('/api/clients/$id');
  }
}
