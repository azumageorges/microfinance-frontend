import '../../core/network/api_client.dart';
import '../../core/network/api_request.dart';
import '../models/beneficiaire_model.dart';

class BeneficiaireRepository {
  final ApiClient _apiClient;

  BeneficiaireRepository(this._apiClient);

  Future<List<BeneficiaireModel>> getByClient(int clientId) {
    return guardApi(() async => parseList(
          await _apiClient.dio.get('/api/beneficiaires/client/$clientId'),
          BeneficiaireModel.fromJson,
        ));
  }

  Future<BeneficiaireModel> create(Map<String, dynamic> data) {
    return guardApi(() async => parseItem(
          await _apiClient.dio.post('/api/beneficiaires', data: data),
          BeneficiaireModel.fromJson,
        ));
  }

  Future<void> delete(int id) {
    return guardApi(() => _apiClient.dio.delete('/api/beneficiaires/$id'));
  }
}
