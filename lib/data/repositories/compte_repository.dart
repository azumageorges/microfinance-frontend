import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/connectivity_service.dart';
import '../local/compte_local_store.dart';
import '../models/compte_model.dart';
import 'compte_repository_interface.dart';

class CompteRepository implements ICompteRepository {
  final ApiClient _apiClient;
  final CompteLocalStore _localStore;
  final ConnectivityService _connectivity;

  CompteRepository(
    this._apiClient, {
    required this._localStore,
    required this._connectivity,
  });

  @override
  Future<List<CompteModel>> getComptes() async {
    final local = await _localStore.getAll();

    if (await _connectivity.isOnline()) {
      try {
        final res = await _apiClient.dio.get('/api/comptes');
        final remote = (res.data['data'] as List<dynamic>)
            .map((e) => CompteModel.fromJson(e as Map<String, dynamic>))
            .toList();
        await _localStore.upsertAll(remote);
        return remote;
      } on DioException {
        if (local.isNotEmpty) return local;
        rethrow;
      }
    }

    if (local.isNotEmpty) return local;
    return local;
  }

  @override
  Future<List<CompteModel>> getComptesByClient(int clientId) async {
    final local = await _localStore.getByClientId(clientId);

    if (await _connectivity.isOnline() && clientId > 0) {
      try {
        final res =
            await _apiClient.dio.get('/api/comptes/client/$clientId');
        final remote = (res.data['data'] as List<dynamic>)
            .map((e) => CompteModel.fromJson(e as Map<String, dynamic>))
            .toList();
        await _localStore.upsertAllForClient(clientId, remote);
        return remote;
      } on DioException {
        if (local.isNotEmpty) return local;
        rethrow;
      }
    }

    return local;
  }

  @override
  Future<CompteModel> getCompteByNumero(String numero) async {
    final local = await _localStore.getByNumero(numero);

    if (await _connectivity.isOnline()) {
      try {
        final res = await _apiClient.dio.get('/api/comptes/$numero');
        final remote = CompteModel.fromJson(res.data['data'] as Map<String, dynamic>);
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

  @override
  Future<CompteModel> createCompte(Map<String, dynamic> data) async {
    try {
      final res = await _apiClient.dio.post('/api/comptes', data: data);
      final compte = CompteModel.fromJson(res.data['data'] as Map<String, dynamic>);
      await _localStore.upsert(compte);
      return compte;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }


  @override
  Future<CompteModel> bloquerCompte(String numero) async {
    try {
      final res =
          await _apiClient.dio.patch('/api/comptes/$numero/bloquer');
      return CompteModel.fromJson(res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<CompteModel> debloquerCompte(String numero) async {
    try {
      final res =
          await _apiClient.dio.patch('/api/comptes/$numero/debloquer');
      return CompteModel.fromJson(res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<CompteModel> cloturerCompte(String numero) async {
    try {
      final res =
          await _apiClient.dio.patch('/api/comptes/$numero/cloturer');
      return CompteModel.fromJson(res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<CompteModel> modifierCompte(String numero, Map<String, dynamic> data) async {
    try {
      final res = await _apiClient.dio.patch('/api/comptes/$numero/modifier', data: data);
      return CompteModel.fromJson(res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<void> supprimerCompte(String numero) async {
    try {
      final response = await _apiClient.dio.delete('/api/comptes/$numero');
      if (response.statusCode == 200) {
        debugPrint('[DEBUG] Compte $numero supprimé avec succès');
      }
    } on DioException catch (e) {
      debugPrint('[ERROR] Erreur suppression compte $numero');
      debugPrint('[ERROR] Status: ${e.response?.statusCode}');
      debugPrint('[ERROR] Response: ${e.response?.data}');
      debugPrint('[ERROR] Message: ${e.message}');
      throw ApiException.fromDioError(e);
    }
  }
}
