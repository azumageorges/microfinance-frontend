import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/local/client_local_store.dart';
import '../../data/local/compte_local_store.dart';
import '../../data/local/credit_local_store.dart';
import '../../data/local/sync_queue_store.dart';
import '../../data/local/sync_status.dart';
import '../../data/local/transaction_local_store.dart';
import '../../data/models/client_model.dart';
import '../../data/models/compte_model.dart';
import '../../data/models/credit_model.dart';
import '../../data/models/transaction_model.dart';
import '../network/api_client.dart';
import '../network/connectivity_service.dart';

typedef SyncCompletedCallback = void Function();

class SyncService {
  final ApiClient _apiClient;
  final ClientLocalStore _clientStore;
  final CompteLocalStore _compteStore;
  final TransactionLocalStore _transactionStore;
  final CreditLocalStore _creditStore;
  final SyncQueueStore _syncQueue;
  final ConnectivityService _connectivity;
  final SyncCompletedCallback? onSyncCompleted;

  bool _syncing = false;
  StreamSubscription<bool>? _subscription;

  SyncService({
    required ApiClient apiClient,
    required ClientLocalStore clientStore,
    required CompteLocalStore compteStore,
    required TransactionLocalStore transactionStore,
    required CreditLocalStore creditStore,
    required SyncQueueStore syncQueue,
    required ConnectivityService connectivity,
    this.onSyncCompleted,
  })  : _apiClient = apiClient,
        _clientStore = clientStore,
        _compteStore = compteStore,
        _transactionStore = transactionStore,
        _creditStore = creditStore,
        _syncQueue = syncQueue,
        _connectivity = connectivity;


  void startListening() {
    _subscription?.cancel();
    _subscription = _connectivity.onConnectivityChanged().listen((online) {
      if (online) {
        syncPendingChanges();
        pullAllData();
      }
    });
  }

  void dispose() {
    _subscription?.cancel();
  }

  Future<void> syncPendingChanges() async {
    if (_syncing) return;
    if (!await _connectivity.isOnline()) return;

    _syncing = true;
    try {
      final items = await _syncQueue.getAll();
      for (final item in items) {
        try {
          switch (item.entityType) {
            case SyncEntityType.client:
              if (item.operation == SyncOperation.create) {
                await _syncClientCreate(item);
              } else if (item.operation == SyncOperation.update) {
                await _syncClientUpdate(item);
              }
              break;

            case SyncEntityType.transaction:
              if (item.operation == SyncOperation.depot) {
                await _syncTransactionDepot(item);
              } else if (item.operation == SyncOperation.retrait) {
                await _syncTransactionRetrait(item);
              } else if (item.operation == SyncOperation.transfert) {
                await _syncTransactionTransfert(item);
              }
              break;

            case SyncEntityType.compte:
              if (item.operation == SyncOperation.create) {
                await _syncCompteCreate(item);
              }
              break;

            default:
              break;
          }
        } catch (e) {
          debugPrint('Sync failed for queue item ${item.id} (${item.entityType}): $e');
          await _syncQueue.incrementRetry(item.id);
        }
      }
      onSyncCompleted?.call();
    } finally {
      _syncing = false;
    }
  }

  Future<void> _syncClientCreate(SyncQueueItem item) async {
    final localId = int.parse(item.entityId);
    final data = Map<String, dynamic>.from(item.payload['data'] as Map);

    final res = await _apiClient.dio.post('/api/clients', data: data);
    final serverClient =
        ClientModel.fromJson(res.data['data'] as Map<String, dynamic>);

    await _clientStore.markSynced(localId, serverClient);
    await _syncQueue.remove(item.id);
  }

  Future<void> _syncClientUpdate(SyncQueueItem item) async {
    final clientId = int.parse(item.entityId);
    final data = Map<String, dynamic>.from(item.payload['data'] as Map);

    final res =
        await _apiClient.dio.patch('/api/clients/$clientId', data: data);
    final serverClient =
        ClientModel.fromJson(res.data['data'] as Map<String, dynamic>);

    await _clientStore.upsert(serverClient);
    await _syncQueue.remove(item.id);
  }

  Future<void> _syncTransactionDepot(SyncQueueItem item) async {
    final localId = int.parse(item.entityId);
    final data = Map<String, dynamic>.from(item.payload['data'] as Map);

    final res = await _apiClient.dio.post('/api/transactions/depot', data: data);
    final serverTx = TransactionModel.fromJson(res.data['data'] as Map<String, dynamic>);

    await _transactionStore.markSynced(localId, serverTx);
    await _syncQueue.remove(item.id);
  }

  Future<void> _syncTransactionRetrait(SyncQueueItem item) async {
    final localId = int.parse(item.entityId);
    final data = Map<String, dynamic>.from(item.payload['data'] as Map);

    final res = await _apiClient.dio.post('/api/transactions/retrait', data: data);
    final serverTx = TransactionModel.fromJson(res.data['data'] as Map<String, dynamic>);

    await _transactionStore.markSynced(localId, serverTx);
    await _syncQueue.remove(item.id);
  }

  Future<void> _syncTransactionTransfert(SyncQueueItem item) async {
    final localId = int.parse(item.entityId);
    final data = Map<String, dynamic>.from(item.payload['data'] as Map);

    final res = await _apiClient.dio.post('/api/transactions/transfert', data: data);
    final serverTx = TransactionModel.fromJson(res.data['data'] as Map<String, dynamic>);

    await _transactionStore.markSynced(localId, serverTx);
    await _syncQueue.remove(item.id);
  }

  Future<void> _syncCompteCreate(SyncQueueItem item) async {
    final data = Map<String, dynamic>.from(item.payload['data'] as Map);

    final res = await _apiClient.dio.post('/api/comptes', data: data);
    final serverCompte = CompteModel.fromJson(res.data['data'] as Map<String, dynamic>);

    await _compteStore.upsert(serverCompte);
    await _syncQueue.remove(item.id);
  }

  Future<void> pullAllData() async {
    if (!await _connectivity.isOnline()) return;
    await pullClients();
    await pullComptes();
    await pullTransactions();
    await pullCredits();
  }

  Future<void> pullClients() async {
    if (!await _connectivity.isOnline()) return;

    try {
      final res = await _apiClient.dio.get('/api/clients');
      final clients = (res.data['data'] as List)
          .map((e) => ClientModel.fromJson(e as Map<String, dynamic>))
          .toList();
      await _clientStore.upsertAll(clients);
    } catch (e) {
      debugPrint('Pull clients failed: $e');
    }
  }

  Future<void> pullComptes() async {
    if (!await _connectivity.isOnline()) return;

    try {
      final res = await _apiClient.dio.get('/api/comptes');
      final comptes = (res.data['data'] as List)
          .map((e) => CompteModel.fromJson(e as Map<String, dynamic>))
          .toList();
      await _compteStore.upsertAll(comptes);
    } catch (e) {
      debugPrint('Pull comptes failed: $e');
    }
  }

  Future<void> pullTransactions() async {
    if (!await _connectivity.isOnline()) return;

    try {
      final res = await _apiClient.dio.get('/api/transactions/all');
      final txs = (res.data['data'] as List)
          .map((e) => TransactionModel.fromJson(e as Map<String, dynamic>))
          .toList();
      await _transactionStore.upsertAll(txs);
    } catch (e) {
      debugPrint('Pull transactions failed: $e');
    }
  }

  Future<void> pullCredits() async {
    if (!await _connectivity.isOnline()) return;

    try {
      final res = await _apiClient.dio.get('/api/credits');
      final credits = (res.data['data'] as List)
          .map((e) => CreditModel.fromJson(e as Map<String, dynamic>))
          .toList();
      await _creditStore.upsertAll(credits);
    } catch (e) {
      debugPrint('Pull credits failed: $e');
    }
  }
}

