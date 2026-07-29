import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../models/credit_model.dart';

class CreditRepository {
  final ApiClient _apiClient;

  CreditRepository(this._apiClient);

  Future<CreditModel> getCreditByReference(String reference) async {
    try {
      final res = await _apiClient.dio.get('/api/credits/reference/$reference');
      return CreditModel.fromJson(res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<CreditModel>> getCredits() async {
    try {
      final res = await _apiClient.dio.get('/api/credits');
      return (res.data['data'] as List)
          .map((e) => CreditModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
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
    try {
      final res = await _apiClient.dio.get('/api/credits/client/$clientId');
      return (res.data['data'] as List)
          .map((e) => CreditModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<CreditModel> demandeCredit(Map<String, dynamic> data) async {
    try {
      final res =
          await _apiClient.dio.post('/api/credits/demande', data: data);
      return CreditModel.fromJson(res.data['data'] as Map<String, dynamic>);
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
