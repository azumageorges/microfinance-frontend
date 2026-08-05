import '../models/transaction_model.dart';

/// Interface abstraite pour TransactionRepository
/// Permet d'avoir des implémentations Web (API uniquement) et Mobile (SQLite + sync)
abstract class ITransactionRepository {
  Future<List<TransactionModel>> getAllTransactions();
  Future<List<TransactionModel>> getTransactionsByCompte(String numeroCompte);
  Future<List<TransactionModel>> getTransactionsByClient(int clientId);
  Future<TransactionModel> createTransaction(Map<String, dynamic> data);
  Future<TransactionModel> getTransactionById(int id);
  Future<TransactionModel> depot(Map<String, dynamic> data);
  Future<TransactionModel> retrait(Map<String, dynamic> data);
  Future<TransactionModel> transfert(Map<String, dynamic> data);
  Future<TransactionModel> validerOperation(int id, {required bool approuve, String? motifRejet});
  Future<TransactionModel> executerOperation(int id);
}
