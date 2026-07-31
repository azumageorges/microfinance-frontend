import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/connectivity_service.dart';
import '../local/credit_local_store.dart';
import '../models/credit_model.dart';

class CreditRepository {
  final ApiClient _apiClient;
  final CreditLocalStore? _localStore;
  final ConnectivityService? _connectivity;

  CreditRepository(
    this._apiClient, {
    CreditLocalStore? localStore,
    ConnectivityService? connectivity,
  })  : _localStore = localStore,
        _connectivity = connectivity;

  Future<CreditModel> getCreditByReference(String reference) async {
    try {
      final res = await _apiClient.dio.get('/api/credits/reference/$reference');
      final credit = CreditModel.fromJson(res.data['data'] as Map<String, dynamic>);
      await _localStore?.upsert(credit);
      return credit;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<CreditModel>> getCredits() async {
    final local = await _localStore?.getAll() ?? [];

    if (_connectivity != null && await _connectivity.isOnline()) {
      try {
        final res = await _apiClient.dio.get('/api/credits');
        final remote = (res.data['data'] as List)
            .map((e) => CreditModel.fromJson(e as Map<String, dynamic>))
            .toList();
        await _localStore?.upsertAll(remote);
        return remote;
      } on DioException {
        if (local.isNotEmpty) return local;
        rethrow;
      }
    }

    return local;
  }

  Future<List<CreditModel>> getCreditsByStatut(String statut) async {
    try {
      final res = await _apiClient.dio.get('/api/credits/statut/$statut');
      return (res.data['data'] as List)
          .map((e) => CreditModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<CreditModel>> getCreditsByClient(int clientId) async {
    final local = await _localStore?.getByClient(clientId) ?? [];

    if (_connectivity != null && await _connectivity.isOnline()) {
      try {
        final res = await _apiClient.dio.get('/api/credits/client/$clientId');
        final remote = (res.data['data'] as List)
            .map((e) => CreditModel.fromJson(e as Map<String, dynamic>))
            .toList();
        await _localStore?.upsertAll(remote);
        return remote;
      } on DioException {
        if (local.isNotEmpty) return local;
        rethrow;
      }
    }

    return local;
  }

  Future<CreditModel> demandeCredit(Map<String, dynamic> data) async {
    try {
      final res =
          await _apiClient.dio.post('/api/credits/demande', data: data);
      final credit = CreditModel.fromJson(res.data['data'] as Map<String, dynamic>);
      await _localStore?.upsert(credit);
      return credit;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<CreditModel> validerCredit(
    int id, {
    required bool approuve,
    String? motifRejet,
  }) async {
    try {
      final res = await _apiClient.dio.patch(
        '/api/credits/$id/valider',
        data: {
          'approuve': approuve,
          'motifRejet': motifRejet,
        },
      );
      return CreditModel.fromJson(res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<CreditModel> debloquerCredit(int id) async {
    try {
      final res =
          await _apiClient.dio.patch('/api/credits/$id/debloquer');
      return CreditModel.fromJson(res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<CreditModel> rembourserEcheance(int echeanceId) async {
    try {
      final res = await _apiClient.dio
          .patch('/api/credits/echeances/$echeanceId/rembourser');
      return CreditModel.fromJson(res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}

