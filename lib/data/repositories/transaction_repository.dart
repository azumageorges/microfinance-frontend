import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../models/transaction_model.dart';

class TransactionRepository {
  final ApiClient _apiClient;

  TransactionRepository(this._apiClient);

  /// Toutes les transactions sans pagination — pour rapports et dashboard caissier
  Future<List<TransactionModel>> getAllTransactions() async {
    try {
      final res = await _apiClient.dio.get('/api/transactions/all');
      return (res.data['data'] as List)
          .map((e) => TransactionModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<TransactionModel>> getTransactions({
    int page = 0,
    int size = 20,
  }) async {
    try {
      final res = await _apiClient.dio.get(
        '/api/transactions',
        queryParameters: {'page': page, 'size': size},
      );
      final pageData = res.data['data'] as Map<String, dynamic>;
      return (pageData['content'] as List)
          .map((e) => TransactionModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<TransactionModel>> getTransactionsByCompte(
    String numeroCompte, {
    int page = 0,
    int size = 20,
  }) async {
    try {
      final res = await _apiClient.dio.get(
        '/api/transactions/compte/$numeroCompte',
        queryParameters: {'page': page, 'size': size},
      );
      final pageData = res.data['data'] as Map<String, dynamic>;
      return (pageData['content'] as List)
          .map((e) => TransactionModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<TransactionModel>> getTransactionsByClient(int clientId) async {
    try {
      final res =
          await _apiClient.dio.get('/api/transactions/client/$clientId');
      return (res.data['data'] as List)
          .map((e) => TransactionModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<TransactionModel> depot(Map<String, dynamic> data) async {
    try {
      final res =
          await _apiClient.dio.post('/api/transactions/depot', data: data);
      return TransactionModel.fromJson(
          res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<TransactionModel> retrait(Map<String, dynamic> data) async {
    try {
      final res =
          await _apiClient.dio.post('/api/transactions/retrait', data: data);
      return TransactionModel.fromJson(
          res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<TransactionModel> transfert(Map<String, dynamic> data) async {
    try {
      final res =
          await _apiClient.dio.post('/api/transactions/transfert', data: data);
      return TransactionModel.fromJson(
          res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<TransactionModel> validerOperation(
    int id, {
    required bool approuve,
    String? motifRejet,
  }) async {
    try {
      final res = await _apiClient.dio.patch(
        '/api/transactions/$id/valider',
        data: {
          'approuve': approuve,
          if (motifRejet != null && motifRejet.trim().isNotEmpty)
            'motifRejet': motifRejet.trim(),
        },
      );
      return TransactionModel.fromJson(
        res.data['data'] as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<TransactionModel> executerOperation(int id) async {
    try {
      final res = await _apiClient.dio.patch('/api/transactions/$id/executer');
      return TransactionModel.fromJson(
        res.data['data'] as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
