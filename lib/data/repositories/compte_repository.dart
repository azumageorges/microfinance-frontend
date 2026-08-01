import 'package:dio/dio.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/api_request.dart';
import '../../core/network/connectivity_service.dart';
import '../local/compte_local_store.dart';
import '../models/compte_model.dart';
import 'offline_first.dart';

class CompteRepository {
  final ApiClient _apiClient;
  final CompteLocalStore _localStore;
  final ConnectivityService _connectivity;

  CompteRepository(
    this._apiClient, {
    required CompteLocalStore localStore,
    required ConnectivityService connectivity,
  })  : _localStore = localStore,
        _connectivity = connectivity;

  Future<List<CompteModel>> getComptes() {
    return offlineFirstList<CompteModel>(
      connectivity: _connectivity,
      local: _localStore.getAll,
      remote: () async => parseList(
        await _apiClient.dio.get('/api/comptes'),
        CompteModel.fromJson,
      ),
      cache: _localStore.upsertAll,
    );
  }

  Future<List<CompteModel>> getComptesByClient(int clientId) {
    return offlineFirstList<CompteModel>(
      connectivity: clientId > 0 ? _connectivity : null,
      local: () => _localStore.getByClientId(clientId),
      remote: () async => parseList(
        await _apiClient.dio.get('/api/comptes/client/$clientId'),
        CompteModel.fromJson,
      ),
      cache: (comptes) => _localStore.upsertAllForClient(clientId, comptes),
    );
  }

  Future<CompteModel> getCompteByNumero(String numero) async {
    final local = await _localStore.getByNumero(numero);

    if (await _connectivity.isOnline()) {
      try {
        final remote = parseItem(
          await _apiClient.dio.get('/api/comptes/$numero'),
          CompteModel.fromJson,
        );
        await _localStore.upsert(remote);
        return remote;
      } on DioException catch (e) {
        if (local != null) return local;
        throw ApiException.fromDioError(e);
      }
    }

    if (local != null) return local;
    throw ApiException('Compte introuvable en mode hors ligne.');
  }

  Future<CompteModel> createCompte(Map<String, dynamic> data) {
    return guardApi(() async {
      final compte = parseItem(
        await _apiClient.dio.post('/api/comptes', data: data),
        CompteModel.fromJson,
      );
      await _localStore.upsert(compte);
      return compte;
    });
  }

  Future<CompteModel> bloquerCompte(String numero) =>
      _patchCompte('/api/comptes/$numero/bloquer');

  Future<CompteModel> debloquerCompte(String numero) =>
      _patchCompte('/api/comptes/$numero/debloquer');

  Future<CompteModel> cloturerCompte(String numero) =>
      _patchCompte('/api/comptes/$numero/cloturer');

  Future<CompteModel> _patchCompte(String path) {
    return guardApi(() async => parseItem(
          await _apiClient.dio.patch(path),
          CompteModel.fromJson,
        ));
  }
}
