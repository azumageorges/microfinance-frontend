import 'package:dio/dio.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/connectivity_service.dart';
import '../../core/sync/sync_service.dart';
import '../local/client_local_store.dart';
import '../local/sync_queue_store.dart';
import '../local/sync_status.dart';
import '../models/client_model.dart';


class ClientRepository {
  final ApiClient _apiClient;
  final ClientLocalStore _localStore;
  final SyncQueueStore _syncQueue;
  final ConnectivityService _connectivity;
  final SyncService? _syncService;

  ClientRepository(
    this._apiClient, {
    required ClientLocalStore localStore,
    required SyncQueueStore syncQueue,
    required ConnectivityService connectivity,
    SyncService? syncService,
  })  : _localStore = localStore,
        _syncQueue = syncQueue,
        _connectivity = connectivity,
        _syncService = syncService;

  Future<List<ClientModel>> getClients() async {
    final local = await _localStore.getAll();

    if (await _connectivity.isOnline()) {
      try {
        final res = await _apiClient.dio.get('/api/clients');
        final remote = (res.data['data'] as List)
            .map((e) => ClientModel.fromJson(e as Map<String, dynamic>))
            .toList();
        await _localStore.upsertAll(remote);
        await _syncService?.syncPendingChanges();
        return _mergeWithPending(await _localStore.getAll(), remote);
      } on DioException catch (e) {
        if (local.isNotEmpty) return local;
        throw ApiException.fromDioError(e);
      } catch (e, stackTrace) {
        throw ApiException.from(e, stackTrace);
      }
    }

    if (local.isNotEmpty) return local;
    throw ApiException(
      'Aucune donnée locale disponible. Connectez-vous à internet.',
    );
  }

  Future<ClientModel> getClientById(int id) async {
    final local = await _localStore.getById(id);

    if (await _connectivity.isOnline()) {
      try {
        final res = await _apiClient.dio.get('/api/clients/$id');
        final remote =
            ClientModel.fromJson(res.data['data'] as Map<String, dynamic>);
        await _localStore.upsert(remote);
        return remote;
      } on DioException catch (e) {
        if (local != null) return local;
        throw ApiException.fromDioError(e);
      } catch (e, stackTrace) {
        throw ApiException.from(e, stackTrace);
      }
    }

    if (local != null) return local;
    throw ApiException('Client introuvable en mode hors ligne.');
  }

  Future<List<ClientModel>> searchClients(String query) async {
    if (query.trim().isEmpty) return getClients();

    if (await _connectivity.isOnline()) {
      try {
        final res = await _apiClient.dio
            .get('/api/clients/recherche', queryParameters: {'q': query});
        final remote = (res.data['data'] as List)
            .map((e) => ClientModel.fromJson(e as Map<String, dynamic>))
            .toList();
        await _localStore.upsertAll(remote);
        return remote;
      } on DioException catch (e) {
        final localResults = await _localStore.search(query);
        if (localResults.isNotEmpty) return localResults;
        throw ApiException.fromDioError(e);
      } catch (e, stackTrace) {
        throw ApiException.from(e, stackTrace);
      }
    }

    return _localStore.search(query);
  }

  Future<ClientModel> createClient(Map<String, dynamic> data) async {
    if (await _connectivity.isOnline()) {
      try {
        final res = await _apiClient.dio.post('/api/clients', data: data);
        final client =
            ClientModel.fromJson(res.data['data'] as Map<String, dynamic>);
        await _localStore.upsert(client);
        return client;
      } on DioException catch (e) {
        throw ApiException.fromDioError(e);
      } catch (e, stackTrace) {
        throw ApiException.from(e, stackTrace);
      }
    }

    return _createClientOffline(data);
  }

  Future<ClientModel> _createClientOffline(Map<String, dynamic> data) async {
    final localId = -DateTime.now().millisecondsSinceEpoch;
    final localUuid = 'local_$localId';
    final now = DateTime.now();

    final client = ClientModel(
      id: localId,
      numeroClient: 'LOCAL-${now.millisecondsSinceEpoch}',
      nom: data['nom'] as String,
      prenom: data['prenom'] as String,
      dateNaissance: data['dateNaissance'] != null
          ? DateTime.tryParse(data['dateNaissance'].toString())
          : null,
      lieuNaissance: data['lieuNaissance'] as String?,
      telephone: data['telephone'] as String,
      email: data['email'] as String?,
      adresse: data['adresse'] as String?,
      profession: data['profession'] as String?,
      typePieceIdentite: data['typePieceIdentite'] as String?,
      numeroPieceIdentite: data['numeroPieceIdentite'] as String?,
      statut: 'ACTIF',
      createdAt: now,
    );

    await _localStore.savePendingCreate(client: client, localId: localUuid);
    await _syncQueue.insert(
      entityType: SyncEntityType.client,
      entityId: localId.toString(),
      operation: SyncOperation.create,
      payload: {'data': data, 'localId': localUuid},
    );

    return client;
  }

  Future<ClientModel> updateClient(int id, Map<String, dynamic> data) async {
    if (await _connectivity.isOnline() && id > 0) {
      try {
        final res = await _apiClient.dio.patch('/api/clients/$id', data: data);
        final client =
            ClientModel.fromJson(res.data['data'] as Map<String, dynamic>);
        await _localStore.upsert(client);
        return client;
      } on DioException catch (e) {
        throw ApiException.fromDioError(e);
      } catch (e, stackTrace) {
        throw ApiException.from(e, stackTrace);
      }
    }

    return _updateClientOffline(id, data);
  }

  Future<ClientModel> _updateClientOffline(int id, Map<String, dynamic> data) async {
    final existing = await _localStore.getById(id);
    if (existing == null) {
      throw ApiException('Client introuvable en mode hors ligne.');
    }

    final updated = ClientModel(
      id: existing.id,
      numeroClient: existing.numeroClient,
      nom: data['nom'] as String? ?? existing.nom,
      prenom: data['prenom'] as String? ?? existing.prenom,
      dateNaissance: data['dateNaissance'] != null
          ? DateTime.tryParse(data['dateNaissance'].toString())
          : existing.dateNaissance,
      lieuNaissance: data['lieuNaissance'] as String? ?? existing.lieuNaissance,
      telephone: data['telephone'] as String? ?? existing.telephone,
      email: data['email'] as String? ?? existing.email,
      adresse: data['adresse'] as String? ?? existing.adresse,
      profession: data['profession'] as String? ?? existing.profession,
      typePieceIdentite:
          data['typePieceIdentite'] as String? ?? existing.typePieceIdentite,
      numeroPieceIdentite: data['numeroPieceIdentite'] as String? ??
          existing.numeroPieceIdentite,
      dateExpirationPiece: existing.dateExpirationPiece,
      cheminPhoto: existing.cheminPhoto,
      numeroMembre: existing.numeroMembre,
      statut: existing.statut,
      createdAt: existing.createdAt,
      beneficiaires: existing.beneficiaires,
      nombreComptes: existing.nombreComptes,
    );

    if (id < 0) {
      await _localStore.savePendingCreate(
        client: updated,
        localId: 'local_$id',
      );
      await _syncQueue.removeByEntity(SyncEntityType.client, id.toString());
      await _syncQueue.insert(
        entityType: SyncEntityType.client,
        entityId: id.toString(),
        operation: SyncOperation.create,
        payload: {'data': data, 'localId': 'local_$id'},
      );
    } else {
      await _localStore.savePendingUpdate(updated);
      await _syncQueue.insert(
        entityType: SyncEntityType.client,
        entityId: id.toString(),
        operation: SyncOperation.update,
        payload: {'data': data},
      );
    }

    return updated;
  }

  Future<ClientModel> updateStatut(int id, String statut) async {
    if (await _connectivity.isOnline() && id > 0) {
      try {
        final res = await _apiClient.dio.patch(
          '/api/clients/$id/statut',
          queryParameters: {'statut': statut},
        );
        final client =
            ClientModel.fromJson(res.data['data'] as Map<String, dynamic>);
        await _localStore.upsert(client);
        return client;
      } on DioException catch (e) {
        throw ApiException.fromDioError(e);
      } catch (e, stackTrace) {
        throw ApiException.from(e, stackTrace);
      }
    }

    final existing = await _localStore.getById(id);
    if (existing == null) {
      throw ApiException('Client introuvable en mode hors ligne.');
    }
    final updated = ClientModel(
      id: existing.id,
      numeroClient: existing.numeroClient,
      nom: existing.nom,
      prenom: existing.prenom,
      dateNaissance: existing.dateNaissance,
      lieuNaissance: existing.lieuNaissance,
      telephone: existing.telephone,
      email: existing.email,
      adresse: existing.adresse,
      profession: existing.profession,
      typePieceIdentite: existing.typePieceIdentite,
      numeroPieceIdentite: existing.numeroPieceIdentite,
      dateExpirationPiece: existing.dateExpirationPiece,
      cheminPhoto: existing.cheminPhoto,
      numeroMembre: existing.numeroMembre,
      statut: statut,
      createdAt: existing.createdAt,
      beneficiaires: existing.beneficiaires,
      nombreComptes: existing.nombreComptes,
    );
    await _localStore.savePendingUpdate(updated);
    return updated;
  }

  /// Fusionne les clients locaux en attente avec les données serveur.
  List<ClientModel> _mergeWithPending(
    List<ClientModel> allLocal,
    List<ClientModel> remote,
  ) {
    final remoteIds = remote.map((c) => c.id).toSet();
    final pending = allLocal.where((c) => !remoteIds.contains(c.id)).toList();
    return [...remote, ...pending];
  }
}
