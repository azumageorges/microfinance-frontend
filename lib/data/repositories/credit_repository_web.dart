import 'package:flutter/foundation.dart';

import '../../core/network/api_client.dart';
import '../models/credit_model.dart';
import 'credit_repository_interface.dart';

/// Repository pour le Web - utilise uniquement l'API Spring Boot
/// Pas de SQLite, pas de mode offline
class CreditRepositoryWeb implements ICreditRepository {
  final ApiClient _apiClient;

  CreditRepositoryWeb(this._apiClient);

  @override
  Future<List<CreditModel>> getCredits() async {
    final res = await _apiClient.dio.get('/api/credits');
    return (res.data['data'] as List)
        .map((e) => CreditModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<CreditModel> getCreditByReference(String reference) async {
    final res = await _apiClient.dio.get('/api/credits/reference/$reference');
    return CreditModel.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  @override
  Future<List<CreditModel>> getCreditsByClient(int clientId) async {
    final res = await _apiClient.dio.get('/api/credits/client/$clientId');
    return (res.data['data'] as List)
        .map((e) => CreditModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<CreditModel>> getCreditsByStatut(String statut) async {
    final res = await _apiClient.dio.get('/api/credits/statut/$statut');
    return (res.data['data'] as List)
        .map((e) => CreditModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<CreditModel> createCredit(Map<String, dynamic> data) async {
    final res = await _apiClient.dio.post('/api/credits', data: data);
    return CreditModel.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  @override
  Future<CreditModel> demandeCredit(Map<String, dynamic> data) async {
    debugPrint('[CREDIT] POST /api/credits/demande');
    debugPrint('[CREDIT] Request Body: $data');
    final res = await _apiClient.dio.post('/api/credits/demande', data: data);
    debugPrint('[CREDIT] Response Status: ${res.statusCode}');
    debugPrint('[CREDIT] Response Body: ${res.data}');
    return CreditModel.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  @override
  Future<CreditModel> validateCredit(String reference, Map<String, dynamic> data) async {
    final res = await _apiClient.dio.patch('/api/credits/$reference/validation', data: data);
    return CreditModel.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  @override
  Future<CreditModel> rejectCredit(String reference, String motif) async {
    final res = await _apiClient.dio.patch(
      '/api/credits/$reference/rejet',
      data: {'motif_rejet': motif},
    );
    return CreditModel.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  @override
  Future<CreditModel> validerCredit(int id, {required bool approuve, String? motifRejet}) async {
    final res = await _apiClient.dio.patch(
      '/api/credits/$id/valider',
      data: {
        'approuve': approuve,
        'motifRejet': motifRejet,
      },
    );
    return CreditModel.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  @override
  Future<CreditModel> debloquerCredit(int id) async {
    // Méthode dépréciée : utiliser demanderDeblocage() + validerDeblocage() + executerDeblocage()
    final res = await _apiClient.dio.patch('/api/credits/$id/debloquer');
    return CreditModel.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  @override
  Future<CreditModel> demanderDeblocage(int id) async {
    final res = await _apiClient.dio.patch('/api/credits/$id/debloquer');
    return CreditModel.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  @override
  Future<CreditModel> validerDeblocage(int id, {required bool approuve, String? motifRejet}) async {
    final res = await _apiClient.dio.patch(
      '/api/credits/$id/valider-deblocage',
      data: {
        'approuve': approuve,
        'motifRejet': motifRejet,
      },
    );
    return CreditModel.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  @override
  Future<CreditModel> executerDeblocage(int id) async {
    final res = await _apiClient.dio.patch('/api/credits/$id/executer-deblocage');
    return CreditModel.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  @override
  Future<CreditModel> rembourserEcheance(int echeanceId) async {
    final res = await _apiClient.dio.patch('/api/credits/echeances/$echeanceId/rembourser');
    return CreditModel.fromJson(res.data['data'] as Map<String, dynamic>);
  }
}
