import '../../core/network/api_client.dart';
import '../models/transaction_model.dart';
import 'transaction_repository_interface.dart';

/// Repository pour le Web - utilise uniquement l'API Spring Boot
/// Pas de SQLite, pas de mode offline
class TransactionRepositoryWeb implements ITransactionRepository {
  final ApiClient _apiClient;

  TransactionRepositoryWeb(this._apiClient);

  @override
  Future<List<TransactionModel>> getAllTransactions() async {
    final res = await _apiClient.dio.get('/api/transactions/all');
    return (res.data['data'] as List)
        .map((e) => TransactionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<TransactionModel>> getTransactionsByCompte(String numeroCompte) async {
    final res = await _apiClient.dio.get('/api/transactions/compte/$numeroCompte');
    final pageData = res.data['data'] as Map<String, dynamic>;
    final content = pageData['content'] as List;
    return content
        .map((e) => TransactionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<TransactionModel>> getTransactionsByClient(int clientId) async {
    final res = await _apiClient.dio.get('/api/transactions/client/$clientId');
    return (res.data['data'] as List)
        .map((e) => TransactionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<TransactionModel> createTransaction(Map<String, dynamic> data) async {
    final res = await _apiClient.dio.post('/api/transactions', data: data);
    return TransactionModel.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  @override
  Future<TransactionModel> getTransactionById(int id) async {
    final res = await _apiClient.dio.get('/api/transactions/$id');
    return TransactionModel.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  @override
  Future<TransactionModel> depot(Map<String, dynamic> data) async {
    final res = await _apiClient.dio.post('/api/transactions/depot', data: data);
    return TransactionModel.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  @override
  Future<TransactionModel> retrait(Map<String, dynamic> data) async {
    final res = await _apiClient.dio.post('/api/transactions/retrait', data: data);
    return TransactionModel.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  @override
  Future<TransactionModel> transfert(Map<String, dynamic> data) async {
    final res = await _apiClient.dio.post('/api/transactions/transfert', data: data);
    return TransactionModel.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  @override
  Future<TransactionModel> validerOperation(int id, {required bool approuve, String? motifRejet}) async {
    final res = await _apiClient.dio.patch(
      '/api/transactions/$id/valider',
      data: {
        'approuve': approuve,
        if (motifRejet != null && motifRejet.trim().isNotEmpty)
          'motifRejet': motifRejet.trim(),
      },
    );
    return TransactionModel.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  @override
  Future<TransactionModel> executerOperation(int id) async {
    final res = await _apiClient.dio.patch('/api/transactions/$id/executer');
    return TransactionModel.fromJson(res.data['data'] as Map<String, dynamic>);
  }
}
