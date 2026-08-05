import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Base SQLite locale — version 3
///
/// Historique :
///   v1 — clients, comptes, sync_queue
///   v2 — transactions, credits (schema incomplet)
///   v3 — credits étendu (reference_credit, type_credit, mise_quotidienne,
///          frais_credit, nombre_echeances, total_a_rembourser, total_rembourse,
///          reste_a_rembourser, statut_label, progression, date_validation,
///          date_deblocage, date_fin, motif_demande, motif_rejet,
///          numero_compte, echeances_json)
class AppDatabase {
  static const _dbName    = 'microfinance_offline.db';
  static const _dbVersion = 3;

  final Database _db;
  AppDatabase._(this._db);

  Database get db => _db;

  // ─── Ouverture ────────────────────────────────────────────────────────────

  static Future<AppDatabase> open() async {
    final dbPath = await getDatabasesPath();
    final path   = join(dbPath, _dbName);

    final database = await openDatabase(
      path,
      version: _dbVersion,
      onCreate:  (db, _) => _createAll(db),
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createTransactionsTable(db);
          // Recréer credits avec le schéma complet
          await db.execute('DROP TABLE IF EXISTS credits');
          await _createCreditsTable(db);
        } else if (oldVersion < 3) {
          // Migrer credits v2 → v3 (ajout colonnes manquantes)
          await _migrateCreditsV3(db);
        }
      },
    );

    return AppDatabase._(database);
  }

  // ─── Création complète ────────────────────────────────────────────────────

  static Future<void> _createAll(Database db) async {
    await _createClientsTable(db);
    await _createComptesTable(db);
    await _createTransactionsTable(db);
    await _createCreditsTable(db);
    await _createSyncQueueTable(db);
    await _createIndexes(db);
  }

  // ─── Tables ───────────────────────────────────────────────────────────────

  static Future<void> _createClientsTable(Database db) async {
    await db.execute('''
      CREATE TABLE clients (
        id                    INTEGER PRIMARY KEY,
        local_id              TEXT,
        numero_client         TEXT NOT NULL,
        nom                   TEXT NOT NULL,
        prenom                TEXT NOT NULL,
        date_naissance        TEXT,
        lieu_naissance        TEXT,
        telephone             TEXT NOT NULL,
        email                 TEXT,
        adresse               TEXT,
        profession            TEXT,
        type_piece_identite   TEXT,
        numero_piece_identite TEXT,
        date_expiration_piece TEXT,
        chemin_photo          TEXT,
        numero_membre         TEXT,
        statut                TEXT NOT NULL,
        created_at            TEXT,
        beneficiaires_json    TEXT,
        nombre_comptes        INTEGER NOT NULL DEFAULT 0,
        sync_status           TEXT NOT NULL DEFAULT 'synced'
      )
    ''');
  }

  static Future<void> _createComptesTable(Database db) async {
    await db.execute('''
      CREATE TABLE comptes (
        id                 INTEGER PRIMARY KEY,
        numero_compte      TEXT NOT NULL UNIQUE,
        type_compte        TEXT NOT NULL,
        statut             TEXT NOT NULL,
        solde              REAL NOT NULL,
        solde_minimum      REAL,
        taux_interet       REAL,
        duree_en_mois      INTEGER,
        date_ouverture     TEXT,
        date_echeance      TEXT,
        montant_cible      REAL,
        representant_legal TEXT,
        client_id          INTEGER NOT NULL,
        nom_client         TEXT NOT NULL,
        prenom_client      TEXT NOT NULL,
        created_at         TEXT,
        sync_status        TEXT NOT NULL DEFAULT 'synced'
      )
    ''');
  }

  static Future<void> _createTransactionsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS transactions (
        id                  INTEGER PRIMARY KEY,
        local_id            TEXT,
        numero_transaction  TEXT NOT NULL UNIQUE,
        type                TEXT NOT NULL,
        montant             REAL NOT NULL,
        date                TEXT NOT NULL,
        solde_apres         REAL,
        description         TEXT,
        reference_externe   TEXT,
        client_id           INTEGER,
        numero_compte       TEXT NOT NULL,
        type_compte         TEXT,
        sync_status         TEXT NOT NULL DEFAULT 'synced',
        created_at          TEXT
      )
    ''');
  }

  static Future<void> _createCreditsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS credits (
        id                  INTEGER PRIMARY KEY,
        reference_credit    TEXT NOT NULL UNIQUE,
        montant_demande     REAL NOT NULL,
        montant_accorde     REAL,
        statut              TEXT NOT NULL,
        statut_label        TEXT,
        type_credit         TEXT NOT NULL DEFAULT 'MENSUEL',
        mise_quotidienne    REAL NOT NULL DEFAULT 0,
        frais_credit        REAL NOT NULL DEFAULT 0,
        nombre_echeances    INTEGER NOT NULL DEFAULT 0,
        taux_interet        REAL NOT NULL DEFAULT 0,
        duree_en_mois       INTEGER NOT NULL DEFAULT 0,
        total_a_rembourser  REAL,
        total_rembourse     REAL NOT NULL DEFAULT 0,
        reste_a_rembourser  REAL,
        progression         REAL NOT NULL DEFAULT 0,
        nombre_echeances_payees INTEGER NOT NULL DEFAULT 0,
        client_id           INTEGER NOT NULL,
        nom_client          TEXT,
        numero_compte       TEXT NOT NULL DEFAULT '',
        motif_demande       TEXT,
        motif_rejet         TEXT,
        date_demande        TEXT,
        date_validation     TEXT,
        date_deblocage      TEXT,
        date_fin            TEXT,
        echeances_json      TEXT,
        created_at          TEXT,
        sync_status         TEXT NOT NULL DEFAULT 'synced'
      )
    ''');
  }

  static Future<void> _createSyncQueueTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sync_queue (
        id            INTEGER PRIMARY KEY AUTOINCREMENT,
        entity_type   TEXT NOT NULL,
        entity_id     TEXT NOT NULL,
        operation     TEXT NOT NULL,
        payload_json  TEXT NOT NULL,
        created_at    TEXT NOT NULL,
        retry_count   INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  static Future<void> _createIndexes(Database db) async {
    await db.execute('CREATE INDEX IF NOT EXISTS idx_comptes_client_id        ON comptes(client_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_clients_sync_status      ON clients(sync_status)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_transactions_compte      ON transactions(numero_compte)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_transactions_client_id   ON transactions(client_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_credits_client_id        ON credits(client_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_credits_reference        ON credits(reference_credit)');
  }

  // ─── Migration v2 → v3 ────────────────────────────────────────────────────

  static Future<void> _migrateCreditsV3(Database db) async {
    // Ajout des colonnes manquantes sur la table credits existante
    // (ALTER TABLE ADD COLUMN est la migration la plus sûre — pas de DROP)
    final cols = await _existingColumns(db, 'credits');
    final toAdd = <String, String>{
      'reference_credit':        'TEXT NOT NULL DEFAULT ""',
      'statut_label':            'TEXT',
      'type_credit':             'TEXT NOT NULL DEFAULT "MENSUEL"',
      'mise_quotidienne':        'REAL NOT NULL DEFAULT 0',
      'frais_credit':            'REAL NOT NULL DEFAULT 0',
      'nombre_echeances':        'INTEGER NOT NULL DEFAULT 0',
      'total_a_rembourser':      'REAL',
      'total_rembourse':         'REAL NOT NULL DEFAULT 0',
      'reste_a_rembourser':      'REAL',
      'progression':             'REAL NOT NULL DEFAULT 0',
      'nombre_echeances_payees': 'INTEGER NOT NULL DEFAULT 0',
      'numero_compte':           'TEXT NOT NULL DEFAULT ""',
      'date_validation':         'TEXT',
      'date_deblocage':          'TEXT',
      'date_fin':                'TEXT',
      'echeances_json':          'TEXT',
    };

    for (final entry in toAdd.entries) {
      if (!cols.contains(entry.key)) {
        await db.execute(
          'ALTER TABLE credits ADD COLUMN ${entry.key} ${entry.value}',
        );
      }
    }

    // Créer les index manquants
    await db.execute('CREATE UNIQUE INDEX IF NOT EXISTS idx_credits_reference ON credits(reference_credit)');
    await db.execute('CREATE INDEX        IF NOT EXISTS idx_credits_client_id ON credits(client_id)');
  }

  static Future<Set<String>> _existingColumns(
      Database db, String table) async {
    final result = await db.rawQuery("PRAGMA table_info($table)");
    return result.map((r) => r['name'] as String).toSet();
  }

  Future<void> close() => _db.close();
}
