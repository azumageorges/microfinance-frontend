import 'package:sqflite/sqflite.dart';

import '../models/client_model.dart';
import 'app_database.dart';
import 'local_mappers.dart';
import 'sync_status.dart';

class ClientLocalStore {
  final AppDatabase _database;

  ClientLocalStore(this._database);

  Future<List<ClientModel>> getAll() async {
    final rows = await _database.db.query(
      'clients',
      orderBy: 'created_at DESC, id DESC',
    );
    return rows.map(LocalMappers.clientFromRow).toList();
  }

  Future<ClientModel?> getById(int id) async {
    final rows = await _database.db.query(
      'clients',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return LocalMappers.clientFromRow(rows.first);
  }

  Future<List<ClientModel>> search(String query) async {
    final q = '%${query.toLowerCase()}%';
    final rows = await _database.db.query(
      'clients',
      where: '''
        LOWER(nom) LIKE ? OR LOWER(prenom) LIKE ?
        OR LOWER(numero_client) LIKE ? OR telephone LIKE ?
      ''',
      whereArgs: [q, q, q, q],
      orderBy: 'nom ASC, prenom ASC',
    );
    return rows.map(LocalMappers.clientFromRow).toList();
  }

  Future<void> upsert(ClientModel client, {SyncStatus syncStatus = SyncStatus.synced}) async {
    await _database.db.insert(
      'clients',
      LocalMappers.clientToRow(client, syncStatus: syncStatus),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> upsertAll(List<ClientModel> clients) async {
    final batch = _database.db.batch();
    for (final client in clients) {
      batch.insert(
        'clients',
        LocalMappers.clientToRow(client, syncStatus: SyncStatus.synced),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> savePendingCreate({
    required ClientModel client,
    required String localId,
  }) async {
    await _database.db.insert(
      'clients',
      LocalMappers.clientToRow(
        client,
        syncStatus: SyncStatus.pendingCreate,
        localId: localId,
      ),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> savePendingUpdate(ClientModel client) async {
    await _database.db.update(
      'clients',
      LocalMappers.clientToRow(client, syncStatus: SyncStatus.pendingUpdate),
      where: 'id = ?',
      whereArgs: [client.id],
    );
  }

  Future<void> markSynced(int localId, ClientModel serverClient) async {
    await _database.db.delete('clients', where: 'id = ?', whereArgs: [localId]);
    await upsert(serverClient);
  }

  Future<int> countPending() async {
    final result = await _database.db.rawQuery('''
      SELECT COUNT(*) AS count FROM clients
      WHERE sync_status IN ('pending_create', 'pending_update')
    ''');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> delete(int id) async {
    await _database.db.delete('clients', where: 'id = ?', whereArgs: [id]);
  }
}
