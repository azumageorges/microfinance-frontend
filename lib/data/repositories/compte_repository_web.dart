import '../../core/network/api_client.dart';
import '../models/compte_model.dart';
import 'compte_repository_interface.dart';

/// Repository pour le Web - utilise uniquement l'API Spring Boot
/// Pas de SQLite, pas de mode offline
class CompteRepositoryWeb implements ICompteRepository {
  final ApiClient _apiClient;

  CompteRepositoryWeb(this._apiClient);

  @override
  Future<List<CompteModel>> getComptes() async {
    final res = await _apiClient.dio.get('/api/comptes');
    return (res.data['data'] as List)
        .map((e) => CompteModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<CompteModel>> getComptesByClient(int clientId) async {
    final res = await _apiClient.dio.get('/api/comptes/client/$clientId');
    return (res.data['data'] as List)
        .map((e) => CompteModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<CompteModel> getCompteByNumero(String numero) async {
    final res = await _apiClient.dio.get('/api/comptes/$numero');
    return CompteModel.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  @override
  Future<CompteModel> createCompte(Map<String, dynamic> data) async {
    final res = await _apiClient.dio.post('/api/comptes', data: data);
    return CompteModel.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  @override
  Future<CompteModel> bloquerCompte(String numero) async {
    final res = await _apiClient.dio.patch('/api/comptes/$numero/bloquer');
    return CompteModel.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  @override
  Future<CompteModel> debloquerCompte(String numero) async {
    final res = await _apiClient.dio.patch('/api/comptes/$numero/debloquer');
    return CompteModel.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  @override
  Future<CompteModel> cloturerCompte(String numero) async {
    final res = await _apiClient.dio.patch('/api/comptes/$numero/cloturer');
    return CompteModel.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  @override
  Future<CompteModel> modifierCompte(String numero, Map<String, dynamic> data) async {
    final res = await _apiClient.dio.patch('/api/comptes/$numero/modifier', data: data);
    return CompteModel.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  @override
  Future<void> supprimerCompte(String numero) async {
    await _apiClient.dio.delete('/api/comptes/$numero');
  }
}
