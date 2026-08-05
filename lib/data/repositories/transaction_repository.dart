import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/connectivity_service.dart';
import '../local/compte_local_store.dart';
import '../local/sync_queue_store.dart';
import '../local/sync_status.dart';
import '../local/transaction_local_store.dart';
import '../models/transaction_model.dart';
import 'transaction_repository_interface.dart';

class TransactionRepository implements ITransactionRepository {
  final ApiClient _apiClient;
  final TransactionLocalStore? _localStore;
  final CompteLocalStore? _compteStore;
  final SyncQueueStore? _syncQueue;
  final ConnectivityService? _connectivity;

  TransactionRepository(
    this._apiClient, {
    this._localStore,
    this._compteStore,
    this._syncQueue,
    this._connectivity,
  });

  @override
  Future<List<TransactionModel>> getAllTransactions() async {
    final local = await _localStore?.getAll() ?? [];

    if (_connectivity != null && await _connectivity.isOnline()) {
      try {
        final res = await _apiClient.dio.get('/api/transactions/all');
        final remote = (res.data['data'] as List<dynamic>)
            .map((e) => TransactionModel.fromJson(e as Map<String, dynamic>))
            .toList();
        await _localStore?.upsertAll(remote);
        return remote;
      } on DioException {
        if (local.isNotEmpty) return local;
        rethrow;
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
        final remote = (pageData['content'] as List<dynamic>)
            .map((e) => TransactionModel.fromJson(e as Map<String, dynamic>))
            .toList();
        await _localStore?.upsertAll(remote);
        return remote;
      } on DioException {
        if (local.isNotEmpty) return local;
        rethrow;
      }
    }

    return local;
  }

  @override
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
        final remote = (pageData['content'] as List<dynamic>)
            .map((e) => TransactionModel.fromJson(e as Map<String, dynamic>))
            .toList();
        await _localStore?.upsertAll(remote);
        return remote;
      } on DioException {
        if (local.isNotEmpty) return local;
        rethrow;
      }
    }

    return local;
  }

  @override
  Future<List<TransactionModel>> getTransactionsByClient(int clientId) async {
    final local = await _localStore?.getByClient(clientId) ?? [];

    if (_connectivity != null && await _connectivity.isOnline()) {
      try {
        final res =
            await _apiClient.dio.get('/api/transactions/client/$clientId');
        final remote = (res.data['data'] as List<dynamic>)
            .map((e) => TransactionModel.fromJson(e as Map<String, dynamic>))
            .toList();
        await _localStore?.upsertAll(remote);
        return remote;
      } on DioException {
        if (local.isNotEmpty) return local;
        rethrow;
      }
    }

    return local;
  }

  @override
  Future<TransactionModel> createTransaction(Map<String, dynamic> data) async {
    if (_connectivity != null && await _connectivity.isOnline()) {
      try {
        final res = await _apiClient.dio.post('/api/transactions', data: data);
        final tx = TransactionModel.fromJson(res.data['data'] as Map<String, dynamic>);
        await _localStore?.upsert(tx);
        return tx;
      } on DioException catch (e) {
        throw ApiException.fromDioError(e);
      }
    }
    throw ApiException('Création de transaction impossible hors ligne');
  }

  @override
  Future<TransactionModel> getTransactionById(int id) async {
    final local = await _localStore?.getById(id);
    
    if (_connectivity != null && await _connectivity.isOnline()) {
      try {
        final res = await _apiClient.dio.get('/api/transactions/$id');
        final tx = TransactionModel.fromJson(res.data['data'] as Map<String, dynamic>);
        await _localStore?.upsert(tx);
        return tx;
      } on DioException catch (e) {
        if (local != null) return local;
        throw ApiException.fromDioError(e);
      }
    }
    
    if (local != null) return local;
    throw ApiException('Transaction introuvable en mode hors ligne.');
  }

  @override
  Future<TransactionModel> depot(Map<String, dynamic> data) async {
    if (_connectivity != null && await _connectivity.isOnline()) {
      try {
        debugPrint('[DEPOT] POST /api/transactions/depot');
        debugPrint('[DEPOT] Request Body: $data');
        final res =
            await _apiClient.dio.post('/api/transactions/depot', data: data);
        debugPrint('[DEPOT] Response Status: ${res.statusCode}');
        debugPrint('[DEPOT] Response Body: ${res.data}');
        final tx = TransactionModel.fromJson(
            res.data['data'] as Map<String, dynamic>);
        await _localStore?.upsert(tx);
        if (data['numeroCompte'] != null && data['montant'] != null) {
          final montant = (data['montant'] as num).toDouble();
          await _compteStore?.updateSolde(data['numeroCompte'].toString(), montant);
        }
        return tx;
      } on DioException catch (e) {
        debugPrint('[DEPOT] ERROR: ${e.message}');
        debugPrint('[DEPOT] Status: ${e.response?.statusCode}');
        debugPrint('[DEPOT] Response: ${e.response?.data}');
        throw ApiException.fromDioError(e);
      }
    }

    return _createTransactionOffline(
      type: 'DEPOT',
      operation: SyncOperation.depot,
      data: data,
    );
  }

  @override
  Future<TransactionModel> retrait(Map<String, dynamic> data) async {
    if (_connectivity != null && await _connectivity.isOnline()) {
      try {
        final res =
            await _apiClient.dio.post('/api/transactions/retrait', data: data);
        final tx = TransactionModel.fromJson(
            res.data['data'] as Map<String, dynamic>);
        await _localStore?.upsert(tx);
        return tx;
      } on DioException catch (e) {
        throw ApiException.fromDioError(e);
      }
    }

    return _createTransactionOffline(
      type: 'RETRAIT',
      operation: SyncOperation.retrait,
      data: data,
    );
  }

  @override
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
      final delta = type == 'DEPOT' ? montant : 0.0;
      soldeApres = compte.solde + delta;
      if (delta != 0) {
        await _compteStore?.updateSolde(numeroCompte, delta);
      }
    }

    final statut = type == 'DEPOT' ? 'EXECUTEE' : 'EN_ATTENTE';

    final tx = TransactionModel(
      id: localId,
      reference: 'TX-OFFLINE-${now.millisecondsSinceEpoch}',
      typeTransaction: type,
      statut: statut,
      montant: montant,
      motif: data['motif'] as String?,
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

  @override
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
    }
  }

  @override
  Future<TransactionModel> executerOperation(int id) async {
    try {
      final res = await _apiClient.dio.patch('/api/transactions/$id/executer');
      return TransactionModel.fromJson(
        res.data['data'] as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
