import '../models/credit_model.dart';
import 'app_database.dart';
import 'local_mappers.dart';

class CreditLocalStore {
  final AppDatabase _database;

  CreditLocalStore(this._database);

  Future<List<CreditModel>> getAll() async {
    final rows = await _database.db.query(
      'credits',
      orderBy: 'created_at DESC, id DESC',
    );
    return rows.map(LocalMappers.creditFromRow).toList();
  }

  Future<List<CreditModel>> getByClient(int clientId) async {
    final rows = await _database.db.query(
      'credits',
      where: 'client_id = ?',
      whereArgs: [clientId],
      orderBy: 'created_at DESC, id DESC',
    );
    return rows.map(LocalMappers.creditFromRow).toList();
  }

  Future<void> upsert(CreditModel credit) async {
    await _database.db.insert(
      'credits',
      LocalMappers.creditToRow(credit),
    );
  }

  Future<void> upsertAll(List<CreditModel> credits) async {
    final batch = _database.db.batch();
    for (final credit in credits) {
      batch.insert(
        'credits',
        LocalMappers.creditToRow(credit),
      );
    }
    await batch.commit(noResult: true);
  }
}
