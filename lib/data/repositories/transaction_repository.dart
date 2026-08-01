import '../../core/network/api_client.dart';
import '../../core/network/api_request.dart';
import '../../core/network/connectivity_service.dart';
import '../local/compte_local_store.dart';
import '../local/sync_queue_store.dart';
import '../local/sync_status.dart';
import '../local/transaction_local_store.dart';
import '../models/transaction_model.dart';
import 'offline_first.dart';

class TransactionRepository {
  final ApiClient _apiClient;
  final TransactionLocalStore? _localStore;
  final CompteLocalStore? _compteStore;
  final SyncQueueStore? _syncQueue;
  final ConnectivityService? _connectivity;

  TransactionRepository(
    this._apiClient, {
    TransactionLocalStore? localStore,
    CompteLocalStore? compteStore,
    SyncQueueStore? syncQueue,
    ConnectivityService? connectivity,
  })  : _localStore = localStore,
        _compteStore = compteStore,
        _syncQueue = syncQueue,
        _connectivity = connectivity;

  /// Toutes les transactions sans pagination — pour rapports et dashboard caissier/agent
  Future<List<TransactionModel>> getAllTransactions() {
    return _offlineFirst(
      local: () async => await _localStore?.getAll() ?? [],
      remote: () async => parseList(
        await _apiClient.dio.get('/api/transactions/all'),
        TransactionModel.fromJson,
      ),
    );
  }

  Future<List<TransactionModel>> getTransactions({
    int page = 0,
    int size = 20,
  }) {
    return _offlineFirst(
      local: () async => await _localStore?.getAll() ?? [],
      remote: () async => parsePage(
        await _apiClient.dio.get(
          '/api/transactions',
          queryParameters: {'page': page, 'size': size},
        ),
        TransactionModel.fromJson,
      ),
    );
  }

  Future<List<TransactionModel>> getTransactionsByCompte(
    String numeroCompte, {
    int page = 0,
    int size = 20,
  }) {
    return _offlineFirst(
      local: () async => await _localStore?.getByCompte(numeroCompte) ?? [],
      remote: () async => parsePage(
        await _apiClient.dio.get(
          '/api/transactions/compte/$numeroCompte',
          queryParameters: {'page': page, 'size': size},
        ),
        TransactionModel.fromJson,
      ),
    );
  }

  Future<List<TransactionModel>> getTransactionsByClient(int clientId) {
    return _offlineFirst(
      local: () async => await _localStore?.getByClient(clientId) ?? [],
      remote: () async => parseList(
        await _apiClient.dio.get('/api/transactions/client/$clientId'),
        TransactionModel.fromJson,
      ),
    );
  }

  Future<List<TransactionModel>> _offlineFirst({
    required Future<List<TransactionModel>> Function() local,
    required Future<List<TransactionModel>> Function() remote,
  }) {
    return offlineFirstList<TransactionModel>(
      connectivity: _connectivity,
      local: local,
      remote: remote,
      cache: (txs) async => _localStore?.upsertAll(txs),
    );
  }

  Future<TransactionModel> depot(Map<String, dynamic> data) => _operation(
        path: '/api/transactions/depot',
        type: 'DEPOT',
        operation: SyncOperation.depot,
        data: data,
        soldeSign: 1,
      );

  Future<TransactionModel> retrait(Map<String, dynamic> data) => _operation(
        path: '/api/transactions/retrait',
        type: 'RETRAIT',
        operation: SyncOperation.retrait,
        data: data,
        soldeSign: -1,
      );

  Future<TransactionModel> transfert(Map<String, dynamic> data) => _operation(
        path: '/api/transactions/transfert',
        type: 'TRANSFERT',
        operation: SyncOperation.transfert,
        data: data,
      );

  /// Exécute l'opération en ligne (avec mise à jour du solde local quand
  /// [soldeSign] est fourni) ou la met en file d'attente hors ligne.
  Future<TransactionModel> _operation({
    required String path,
    required String type,
    required SyncOperation operation,
    required Map<String, dynamic> data,
    int? soldeSign,
  }) async {
    if (_connectivity != null && await _connectivity.isOnline()) {
      return guardApi(() async {
        final tx = parseItem(
          await _apiClient.dio.post(path, data: data),
          TransactionModel.fromJson,
        );
        await _localStore?.upsert(tx);
        if (soldeSign != null &&
            data['numeroCompte'] != null &&
            data['montant'] != null) {
          final montant = (data['montant'] as num).toDouble();
          await _compteStore?.updateSolde(
            data['numeroCompte'].toString(),
            montant * soldeSign,
          );
        }
        return tx;
      });
    }

    return _createTransactionOffline(
      type: type,
      operation: operation,
      data: data,
    );
  }

  Future<TransactionModel> _createTransactionOffline({
    required String type,
    required SyncOperation operation,
    required Map<String, dynamic> data,
  }) async {
    final localId = -DateTime.now().millisecondsSinceEpoch;
    final now = DateTime.now();
    final montant = (data['montant'] as num).toDouble();
    final numeroCompte = data['numeroCompte'] as String;

    double? soldeApres;
    final compte = await _compteStore?.getByNumero(numeroCompte);
    if (compte != null) {
      final delta = type == 'DEPOT' ? montant : -montant;
      soldeApres = compte.solde + delta;
      await _compteStore?.updateSolde(numeroCompte, delta);
    }

    final tx = TransactionModel(
      id: localId,
      reference: 'TX-OFFLINE-${now.millisecondsSinceEpoch}',
      typeTransaction: type,
      statut: 'EXECUTEE',
      montant: montant,
      soldeApres: soldeApres,
      description: data['description'] as String?,
      numeroCompte: numeroCompte,
      numeroCompteDestination: data['numeroCompteDestination'] as String?,
      dateTransaction: now,
    );

    final localStore = _localStore;
    if (localStore != null) {
      await localStore.savePendingTransaction(
        transaction: tx,
        localId: localId.toString(),
      );
    }

    final syncQueue = _syncQueue;
    if (syncQueue != null) {
      await syncQueue.insert(
        entityType: SyncEntityType.transaction,
        entityId: localId.toString(),
        operation: operation,
        payload: {'data': data, 'localId': localId.toString()},
      );
    }


    return tx;
  }

  Future<TransactionModel> validerOperation(
    int id, {
    required bool approuve,
    String? motifRejet,
  }) {
    return guardApi(() async => parseItem(
          await _apiClient.dio.patch(
            '/api/transactions/$id/valider',
            data: {
              'approuve': approuve,
              if (motifRejet != null && motifRejet.trim().isNotEmpty)
                'motifRejet': motifRejet.trim(),
            },
          ),
          TransactionModel.fromJson,
        ));
  }

  Future<TransactionModel> executerOperation(int id) {
    return guardApi(() async => parseItem(
          await _apiClient.dio.patch('/api/transactions/$id/executer'),
          TransactionModel.fromJson,
        ));
  }
}
