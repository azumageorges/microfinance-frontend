import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import 'app_database.dart';
import 'sync_status.dart';

class SyncQueueItem {
  final int id;
  final SyncEntityType entityType;
  final String entityId;
  final SyncOperation operation;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final int retryCount;

  const SyncQueueItem({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.operation,
    required this.payload,
    required this.createdAt,
    required this.retryCount,
  });

  factory SyncQueueItem.fromRow(Map<String, dynamic> row) => SyncQueueItem(
        id: row['id'] as int,
        entityType: SyncEntityType.values.firstWhere(
          (t) => t.value == row['entity_type'],
        ),
        entityId: row['entity_id'] as String,
        operation: SyncOperation.fromString(row['operation'] as String),
        payload: jsonDecode(row['payload_json'] as String) as Map<String, dynamic>,
        createdAt: DateTime.parse(row['created_at'] as String),
        retryCount: row['retry_count'] as int? ?? 0,
      );
}

class SyncQueueStore {
  final AppDatabase _database;

  SyncQueueStore(this._database);

  Future<int> insert({
    required SyncEntityType entityType,
    required String entityId,
    required SyncOperation operation,
    required Map<String, dynamic> payload,
  }) async {
    return _database.db.insert('sync_queue', {
      'entity_type': entityType.value,
      'entity_id': entityId,
      'operation': operation.value,
      'payload_json': jsonEncode(payload),
      'created_at': DateTime.now().toIso8601String(),
      'retry_count': 0,
    });
  }

  Future<List<SyncQueueItem>> getAll() async {
    final rows = await _database.db.query(
      'sync_queue',
      orderBy: 'created_at ASC, id ASC',
    );
    return rows.map(SyncQueueItem.fromRow).toList();
  }

  Future<void> remove(int id) async {
    await _database.db.delete('sync_queue', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> removeByEntity(SyncEntityType entityType, String entityId) async {
    await _database.db.delete(
      'sync_queue',
      where: 'entity_type = ? AND entity_id = ?',
      whereArgs: [entityType.value, entityId],
    );
  }

  Future<void> incrementRetry(int id) async {
    await _database.db.rawUpdate(
      'UPDATE sync_queue SET retry_count = retry_count + 1 WHERE id = ?',
      [id],
    );
  }

  Future<int> count() async {
    final result = await _database.db.rawQuery(
      'SELECT COUNT(*) AS count FROM sync_queue',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
