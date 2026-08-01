import 'package:dio/dio.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/connectivity_service.dart';
import '../local/compte_local_store.dart';
import '../local/sync_queue_store.dart';
import '../local/sync_status.dart';
import '../local/transaction_local_store.dart';
import '../models/transaction_model.dart';

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
  Future<List<TransactionModel>> getAllTransactions() async {
    final local = await _localStore?.getAll() ?? [];

    if (_connectivity != null && await _connectivity.isOnline()) {
      try {
        final res = await _apiClient.dio.get('/api/transactions/all');
        final remote = (res.data['data'] as List)
            .map((e) => TransactionModel.fromJson(e as Map<String, dynamic>))
            .toList();
        await _localStore?.upsertAll(remote);
        return remote;
      } on DioException catch (e) {
        if (local.isNotEmpty) return local;
        throw ApiException.fromDioError(e);
      } catch (e, stackTrace) {
        throw ApiException.from(e, stackTrace);
      }
    }

    if (local.isNotEmpty) return local;
    return local;
  }

  Future<List<TransactionModel>> getTransactions({
    int page = 0,
    int size = 20,
  }) async {
    final local = await _localStore?.getAll() ?? [];

    if (_connectivity != null && await _connectivity.isOnline()) {
      try {
        final res = await _apiClient.dio.get(
          '/api/transactions',
          queryParameters: {'page': page, 'size': size},
        );
        final pageData = res.data['data'] as Map<String, dynamic>;
        final remote = (pageData['content'] as List)
            .map((e) => TransactionModel.fromJson(e as Map<String, dynamic>))
            .toList();
        await _localStore?.upsertAll(remote);
        return remote;
      } on DioException catch (e) {
        if (local.isNotEmpty) return local;
        throw ApiException.fromDioError(e);
      } catch (e, stackTrace) {
        throw ApiException.from(e, stackTrace);
      }
    }

    return local;
  }

  Future<List<TransactionModel>> getTransactionsByCompte(
    String numeroCompte, {
    int page = 0,
    int size = 20,
  }) async {
    final local = await _localStore?.getByCompte(numeroCompte) ?? [];

    if (_connectivity != null && await _connectivity.isOnline()) {
      try {
        final res = await _apiClient.dio.get(
          '/api/transactions/compte/$numeroCompte',
          queryParameters: {'page': page, 'size': size},
        );
        final pageData = res.data['data'] as Map<String, dynamic>;
        final remote = (pageData['content'] as List)
            .map((e) => TransactionModel.fromJson(e as Map<String, dynamic>))
            .toList();
        await _localStore?.upsertAll(remote);
        return remote;
      } on DioException catch (e) {
        if (local.isNotEmpty) return local;
        throw ApiException.fromDioError(e);
      } catch (e, stackTrace) {
        throw ApiException.from(e, stackTrace);
      }
    }

    return local;
  }

  Future<List<TransactionModel>> getTransactionsByClient(int clientId) async {
    final local = await _localStore?.getByClient(clientId) ?? [];

    if (_connectivity != null && await _connectivity.isOnline()) {
      try {
        final res =
            await _apiClient.dio.get('/api/transactions/client/$clientId');
        final remote = (res.data['data'] as List)
            .map((e) => TransactionModel.fromJson(e as Map<String, dynamic>))
            .toList();
        await _localStore?.upsertAll(remote);
        return remote;
      } on DioException catch (e) {
        if (local.isNotEmpty) return local;
        throw ApiException.fromDioError(e);
      } catch (e, stackTrace) {
        throw ApiException.from(e, stackTrace);
      }
    }

    return local;
  }

  Future<TransactionModel> depot(Map<String, dynamic> data) async {
    if (_connectivity != null && await _connectivity.isOnline()) {
      try {
        final res =
            await _apiClient.dio.post('/api/transactions/depot', data: data);
        final tx = TransactionModel.fromJson(
            res.data['data'] as Map<String, dynamic>);
        await _localStore?.upsert(tx);
        if (data['numeroCompte'] != null && data['montant'] != null) {
          final montant = (data['montant'] as num).toDouble();
          await _compteStore?.updateSolde(data['numeroCompte'].toString(), montant);
        }
        return tx;
      } on DioException catch (e) {
        throw ApiException.fromDioError(e);
      } catch (e, stackTrace) {
        throw ApiException.from(e, stackTrace);
      }
    }

    return _createTransactionOffline(
      type: 'DEPOT',
      operation: SyncOperation.depot,
      data: data,
    );
  }

  Future<TransactionModel> retrait(Map<String, dynamic> data) async {
    if (_connectivity != null && await _connectivity.isOnline()) {
      try {
        final res =
            await _apiClient.dio.post('/api/transactions/retrait', data: data);
        final tx = TransactionModel.fromJson(
            res.data['data'] as Map<String, dynamic>);
        await _localStore?.upsert(tx);
        if (data['numeroCompte'] != null && data['montant'] != null) {
          final montant = (data['montant'] as num).toDouble();
          await _compteStore?.updateSolde(data['numeroCompte'].toString(), -montant);
        }
        return tx;
      } on DioException catch (e) {
        throw ApiException.fromDioError(e);
      } catch (e, stackTrace) {
        throw ApiException.from(e, stackTrace);
      }
    }

    return _createTransactionOffline(
      type: 'RETRAIT',
      operation: SyncOperation.retrait,
      data: data,
    );
  }

  Future<TransactionModel> transfert(Map<String, dynamic> data) async {
    if (_connectivity != null && await _connectivity.isOnline()) {
      try {
        final res =
            await _apiClient.dio.post('/api/transactions/transfert', data: data);
        final tx = TransactionModel.fromJson(
            res.data['data'] as Map<String, dynamic>);
        await _localStore?.upsert(tx);
        return tx;
      } on DioException catch (e) {
        throw ApiException.fromDioError(e);
      } catch (e, stackTrace) {
        throw ApiException.from(e, stackTrace);
      }
    }

    return _createTransactionOffline(
      type: 'TRANSFERT',
      operation: SyncOperation.transfert,
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
  }) async {
    try {
      final res = await _apiClient.dio.patch(
        '/api/transactions/$id/valider',
        data: {
          'approuve': approuve,
          if (motifRejet != null && motifRejet.trim().isNotEmpty)
            'motifRejet': motifRejet.trim(),
        },
      );
      return TransactionModel.fromJson(
        res.data['data'] as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    } catch (e, stackTrace) {
      throw ApiException.from(e, stackTrace);
    }
  }

  Future<TransactionModel> executerOperation(int id) async {
    try {
      final res = await _apiClient.dio.patch('/api/transactions/$id/executer');
      return TransactionModel.fromJson(
        res.data['data'] as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    } catch (e, stackTrace) {
      throw ApiException.from(e, stackTrace);
    }
  }
}
