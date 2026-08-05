import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/connectivity_service.dart';
import '../local/credit_local_store.dart';
import '../models/credit_model.dart';
import 'credit_repository_interface.dart';

class CreditRepository implements ICreditRepository {
  final ApiClient _apiClient;
  final CreditLocalStore? _localStore;
  final ConnectivityService? _connectivity;

  CreditRepository(
    this._apiClient, {
    this._localStore,
    this._connectivity,
  });

  @override
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

  @override
  Future<List<CreditModel>> getCredits() async {
    final local = await _localStore?.getAll() ?? [];

    if (_connectivity != null && await _connectivity.isOnline()) {
      try {
        final res = await _apiClient.dio.get('/api/credits');
        final remote = (res.data['data'] as List<dynamic>)
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

  @override
  Future<List<CreditModel>> getCreditsByStatut(String statut) async {
    try {
      final res = await _apiClient.dio.get('/api/credits/statut/$statut');
      return (res.data['data'] as List<dynamic>)
          .map((e) => CreditModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<List<CreditModel>> getCreditsByClient(int clientId) async {
    final local = await _localStore?.getByClient(clientId) ?? [];

    if (_connectivity != null && await _connectivity.isOnline()) {
      try {
        final res = await _apiClient.dio.get('/api/credits/client/$clientId');
        final remote = (res.data['data'] as List<dynamic>)
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

  @override
  Future<CreditModel> createCredit(Map<String, dynamic> data) async {
    try {
      final res = await _apiClient.dio.post('/api/credits', data: data);
      final credit = CreditModel.fromJson(res.data['data'] as Map<String, dynamic>);
      await _localStore?.upsert(credit);
      return credit;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
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

  @override
  Future<CreditModel> validateCredit(String reference, Map<String, dynamic> data) async {
    try {
      final res = await _apiClient.dio.patch('/api/credits/$reference/validation', data: data);
      return CreditModel.fromJson(res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<CreditModel> rejectCredit(String reference, String motif) async {
    try {
      final res = await _apiClient.dio.patch(
        '/api/credits/$reference/rejet',
        data: {'motif_rejet': motif},
      );
      return CreditModel.fromJson(res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
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

  @override
  Future<CreditModel> debloquerCredit(int id) async {
    try {
      final res =
          await _apiClient.dio.patch('/api/credits/$id/debloquer');
      return CreditModel.fromJson(res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<CreditModel> rembourserEcheance(int echeanceId) async {
    try {
      final res = await _apiClient.dio
          .patch('/api/credits/echeances/$echeanceId/rembourser');
      return CreditModel.fromJson(res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<CreditModel> demanderDeblocage(int id) async {
    try {
      final res = await _apiClient.dio.patch('/api/credits/$id/demander-deblocage');
      return CreditModel.fromJson(res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<CreditModel> validerDeblocage(int id, {required bool approuve, String? motifRejet}) async {
    try {
      final res = await _apiClient.dio.patch(
        '/api/credits/$id/valider-deblocage',
        data: {
          'approuve': approuve,
          if (motifRejet != null && motifRejet.trim().isNotEmpty)
            'motifRejet': motifRejet.trim(),
        },
      );
      return CreditModel.fromJson(res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<CreditModel> executerDeblocage(int id) async {
    try {
      final res = await _apiClient.dio.patch('/api/credits/$id/executer-deblocage');
      return CreditModel.fromJson(res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}

