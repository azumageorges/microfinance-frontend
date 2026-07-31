import 'package:sqflite/sqflite.dart';
import '../models/compte_model.dart';
import 'app_database.dart';
import 'local_mappers.dart';

class CompteLocalStore {
  final AppDatabase _database;

  CompteLocalStore(this._database);

  Future<List<CompteModel>> getAll() async {
    final rows = await _database.db.query(
      'comptes',
      orderBy: 'created_at DESC, id DESC',
    );
    return rows.map(LocalMappers.compteFromRow).toList();
  }

  Future<CompteModel?> getByNumero(String numeroCompte) async {
    final rows = await _database.db.query(
      'comptes',
      where: 'numero_compte = ?',
      whereArgs: [numeroCompte],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return LocalMappers.compteFromRow(rows.first);
  }

  Future<List<CompteModel>> getByClientId(int clientId) async {
    final rows = await _database.db.query(
      'comptes',
      where: 'client_id = ?',
      whereArgs: [clientId],
      orderBy: 'created_at DESC, id DESC',
    );
    return rows.map(LocalMappers.compteFromRow).toList();
  }

  Future<void> upsert(CompteModel compte) async {
    await _database.db.insert(
      'comptes',
      LocalMappers.compteToRow(compte),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> upsertAll(List<CompteModel> comptes) async {
    final batch = _database.db.batch();
    for (final compte in comptes) {
      batch.insert(
        'comptes',
        LocalMappers.compteToRow(compte),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> upsertAllForClient(int clientId, List<CompteModel> comptes) async {
    final batch = _database.db.batch();
    batch.delete('comptes', where: 'client_id = ?', whereArgs: [clientId]);
    for (final compte in comptes) {
      batch.insert(
        'comptes',
        LocalMappers.compteToRow(compte),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> updateSolde(String numeroCompte, double deltaSolde) async {
    await _database.db.rawUpdate(
      'UPDATE comptes SET solde = solde + ? WHERE numero_compte = ?',
      [deltaSolde, numeroCompte],
    );
  }
}

