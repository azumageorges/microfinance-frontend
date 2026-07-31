import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  static const _dbName = 'microfinance_offline.db';
  static const _dbVersion = 2;

  final Database _db;

  AppDatabase._(this._db);

  Database get db => _db;

  static Future<AppDatabase> open() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    final database = await openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, version) async {
        await _createTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createTransactionsTable(db);
          await _createCreditsTable(db);
        }
      },
    );

    return AppDatabase._(database);
  }

  static Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE clients (
        id INTEGER PRIMARY KEY,
        local_id TEXT,
        numero_client TEXT NOT NULL,
        nom TEXT NOT NULL,
        prenom TEXT NOT NULL,
        date_naissance TEXT,
        lieu_naissance TEXT,
        telephone TEXT NOT NULL,
        email TEXT,
        adresse TEXT,
        profession TEXT,
        type_piece_identite TEXT,
        numero_piece_identite TEXT,
        date_expiration_piece TEXT,
        chemin_photo TEXT,
        numero_membre TEXT,
        statut TEXT NOT NULL,
        created_at TEXT,
        beneficiaires_json TEXT,
        nombre_comptes INTEGER NOT NULL DEFAULT 0,
        sync_status TEXT NOT NULL DEFAULT 'synced'
      )
    ''');

    await db.execute('''
      CREATE TABLE comptes (
        id INTEGER PRIMARY KEY,
        numero_compte TEXT NOT NULL,
        type_compte TEXT NOT NULL,
        statut TEXT NOT NULL,
        solde REAL NOT NULL,
        solde_minimum REAL,
        taux_interet REAL,
        duree_en_mois INTEGER,
        date_ouverture TEXT,
        date_echeance TEXT,
        montant_cible REAL,
        representant_legal TEXT,
        client_id INTEGER NOT NULL,
        nom_client TEXT NOT NULL,
        prenom_client TEXT NOT NULL,
        created_at TEXT,
        sync_status TEXT NOT NULL DEFAULT 'synced'
      )
    ''');

    await _createTransactionsTable(db);
    await _createCreditsTable(db);

    await db.execute('''
      CREATE TABLE sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        entity_type TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        operation TEXT NOT NULL,
        payload_json TEXT NOT NULL,
        created_at TEXT NOT NULL,
        retry_count INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_comptes_client_id ON comptes(client_id)',
    );
    await db.execute(
      'CREATE INDEX idx_clients_sync_status ON clients(sync_status)',
    );
  }

  static Future<void> _createTransactionsTable(Database db) async {
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY,
        local_id TEXT,
        numero_transaction TEXT NOT NULL,
        type TEXT NOT NULL,
        montant REAL NOT NULL,
        date TEXT NOT NULL,
        solde_apres REAL,
        description TEXT,
        reference_externe TEXT,
        client_id INTEGER,
        numero_compte TEXT NOT NULL,
        type_compte TEXT,
        sync_status TEXT NOT NULL DEFAULT 'synced',
        created_at TEXT
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_transactions_numero_compte ON transactions(numero_compte)',
    );
    await db.execute(
      'CREATE INDEX idx_transactions_client_id ON transactions(client_id)',
    );
  }

  static Future<void> _createCreditsTable(Database db) async {
    await db.execute('''
      CREATE TABLE credits (
        id INTEGER PRIMARY KEY,
        numero_credit TEXT NOT NULL,
        montant_demande REAL NOT NULL,
        montant_accorde REAL,
        statut TEXT NOT NULL,
        taux_interet REAL NOT NULL,
        duree_en_mois INTEGER NOT NULL,
        client_id INTEGER NOT NULL,
        nom_client TEXT,
        prenom_client TEXT,
        date_demande TEXT,
        created_at TEXT,
        sync_status TEXT NOT NULL DEFAULT 'synced'
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_credits_client_id ON credits(client_id)',
    );
  }

  Future<void> close() => _db.close();
}

