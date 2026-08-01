import '../../core/network/api_client.dart';
import '../../core/network/api_request.dart';
import '../../core/network/connectivity_service.dart';
import '../local/credit_local_store.dart';
import '../models/credit_model.dart';
import 'offline_first.dart';

class CreditRepository {
  final ApiClient _apiClient;
  final CreditLocalStore? _localStore;
  final ConnectivityService? _connectivity;

  CreditRepository(
    this._apiClient, {
    CreditLocalStore? localStore,
    ConnectivityService? connectivity,
  })  : _localStore = localStore,
        _connectivity = connectivity;

  Future<CreditModel> getCreditByReference(String reference) {
    return guardApi(() async {
      final credit = parseItem(
        await _apiClient.dio.get('/api/credits/reference/$reference'),
        CreditModel.fromJson,
      );
      await _localStore?.upsert(credit);
      return credit;
    });
  }

  Future<List<CreditModel>> getCredits() {
    return offlineFirstList<CreditModel>(
      connectivity: _connectivity,
      local: () async => await _localStore?.getAll() ?? [],
      remote: () async => parseList(
        await _apiClient.dio.get('/api/credits'),
        CreditModel.fromJson,
      ),
      cache: (credits) async => _localStore?.upsertAll(credits),
    );
  }

  Future<List<CreditModel>> getCreditsByStatut(String statut) {
    return guardApi(() async => parseList(
          await _apiClient.dio.get('/api/credits/statut/$statut'),
          CreditModel.fromJson,
        ));
  }

  Future<List<CreditModel>> getCreditsByClient(int clientId) {
    return offlineFirstList<CreditModel>(
      connectivity: _connectivity,
      local: () async => await _localStore?.getByClient(clientId) ?? [],
      remote: () async => parseList(
        await _apiClient.dio.get('/api/credits/client/$clientId'),
        CreditModel.fromJson,
      ),
      cache: (credits) async => _localStore?.upsertAll(credits),
    );
  }

  Future<CreditModel> demandeCredit(Map<String, dynamic> data) {
    return guardApi(() async {
      final credit = parseItem(
        await _apiClient.dio.post('/api/credits/demande', data: data),
        CreditModel.fromJson,
      );
      await _localStore?.upsert(credit);
      return credit;
    });
  }

  Future<CreditModel> validerCredit(
    int id, {
    required bool approuve,
    String? motifRejet,
  }) {
    return guardApi(() async => parseItem(
          await _apiClient.dio.patch(
            '/api/credits/$id/valider',
            data: {'approuve': approuve, 'motifRejet': motifRejet},
          ),
          CreditModel.fromJson,
        ));
  }

  Future<CreditModel> debloquerCredit(int id) {
    return guardApi(() async => parseItem(
          await _apiClient.dio.patch('/api/credits/$id/debloquer'),
          CreditModel.fromJson,
        ));
  }

  Future<CreditModel> rembourserEcheance(int echeanceId) {
    return guardApi(() async => parseItem(
          await _apiClient.dio
              .patch('/api/credits/echeances/$echeanceId/rembourser'),
          CreditModel.fromJson,
        ));
  }
}
