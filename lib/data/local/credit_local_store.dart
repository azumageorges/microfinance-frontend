import 'package:sqflite/sqflite.dart';

import '../models/credit_model.dart';
import 'app_database.dart';
import 'local_mappers.dart';

class CreditLocalStore {
  final AppDatabase _database;

  CreditLocalStore(this._database);

  // ─── Lectures ─────────────────────────────────────────────────────────────

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

  Future<CreditModel?> getByReference(String reference) async {
    final rows = await _database.db.query(
      'credits',
      where: 'reference_credit = ?',
      whereArgs: [reference],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return LocalMappers.creditFromRow(rows.first);
  }

  // ─── Écritures ────────────────────────────────────────────────────────────

  /// INSERT OR REPLACE — met à jour si la référence existe déjà.
  Future<void> upsert(CreditModel credit) async {
    await _database.db.insert(
      'credits',
      LocalMappers.creditToRow(credit),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Batch INSERT OR REPLACE pour une liste.
  Future<void> upsertAll(List<CreditModel> credits) async {
    if (credits.isEmpty) return;
    final batch = _database.db.batch();
    for (final credit in credits) {
      batch.insert(
        'credits',
        LocalMappers.creditToRow(credit),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  /// Supprime un crédit par référence (ex: après sync réussie d'un brouillon).
  Future<void> deleteByReference(String reference) async {
    await _database.db.delete(
      'credits',
      where: 'reference_credit = ?',
      whereArgs: [reference],
    );
  }

  /// Retourne les crédits en attente de synchronisation (mode offline).
  Future<List<CreditModel>> getPending() async {
    final rows = await _database.db.query(
      'credits',
      where: "sync_status = 'pending'",
      orderBy: 'created_at ASC',
    );
    return rows.map(LocalMappers.creditFromRow).toList();
  }

  Future<int> count() async {
    final result = await _database.db
        .rawQuery('SELECT COUNT(*) as c FROM credits');
    return (result.first['c'] as int?) ?? 0;
  }
}
