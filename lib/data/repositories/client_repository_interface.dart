import '../models/client_model.dart';

/// Interface abstraite pour ClientRepository
/// Permet d'avoir des implémentations Web (API uniquement) et Mobile (SQLite + sync)
abstract class IClientRepository {
  Future<List<ClientModel>> getClients();
  Future<ClientModel> getClientById(int id);
  Future<List<ClientModel>> searchClients(String query);
  Future<ClientModel> createClient(Map<String, dynamic> data);
  Future<ClientModel> updateClient(int id, Map<String, dynamic> data);
  Future<ClientModel> updateStatut(int id, String statut);
  Future<void> deleteClient(int id);
}
