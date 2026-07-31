import 'package:sqflite/sqflite.dart';

import '../models/transaction_model.dart';
import 'app_database.dart';
import 'local_mappers.dart';
import 'sync_status.dart';

class TransactionLocalStore {
  final AppDatabase _database;

  TransactionLocalStore(this._database);

  Future<List<TransactionModel>> getAll() async {
    final rows = await _database.db.query(
      'transactions',
      orderBy: 'date DESC, id DESC',
    );
    return rows.map(LocalMappers.transactionFromRow).toList();
  }

  Future<List<TransactionModel>> getByCompte(String numeroCompte) async {
    final rows = await _database.db.query(
      'transactions',
      where: 'numero_compte = ?',
      whereArgs: [numeroCompte],
      orderBy: 'date DESC, id DESC',
    );
    return rows.map(LocalMappers.transactionFromRow).toList();
  }

  Future<List<TransactionModel>> getByClient(int clientId) async {
    final rows = await _database.db.query(
      'transactions',
      where: 'client_id = ?',
      whereArgs: [clientId],
      orderBy: 'date DESC, id DESC',
    );
    return rows.map(LocalMappers.transactionFromRow).toList();
  }

  Future<void> upsert(
    TransactionModel transaction, {
    SyncStatus syncStatus = SyncStatus.synced,
    String? localId,
  }) async {
    await _database.db.insert(
      'transactions',
      LocalMappers.transactionToRow(
        transaction,
        syncStatus: syncStatus,
        localId: localId,
      ),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> upsertAll(List<TransactionModel> transactions) async {
    final batch = _database.db.batch();
    for (final tx in transactions) {
      batch.insert(
        'transactions',
        LocalMappers.transactionToRow(tx, syncStatus: SyncStatus.synced),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> savePendingTransaction({
    required TransactionModel transaction,
    required String localId,
  }) async {
    await upsert(
      transaction,
      syncStatus: SyncStatus.pendingCreate,
      localId: localId,
    );
  }

  Future<void> markSynced(int localId, TransactionModel serverTx) async {
    await _database.db.delete('transactions', where: 'id = ?', whereArgs: [localId]);
    await upsert(serverTx);
  }

  Future<int> countPending() async {
    final result = await _database.db.rawQuery('''
      SELECT COUNT(*) AS count FROM transactions
      WHERE sync_status IN ('pending_create', 'pending_update')
    ''');
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
