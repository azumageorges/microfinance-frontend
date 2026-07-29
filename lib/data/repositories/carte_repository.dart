import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../models/carte_model.dart';

export '../models/carte_model.dart';

class CarteRepository {
  final ApiClient _apiClient;

  CarteRepository(this._apiClient);

  /// Génère (ou régénère) la carte membre d'un client.
  /// Crée le numéro membre si inexistant côté backend.
  Future<CarteModel> genererCarte(int clientId) async {
    try {
      final res = await _apiClient.dio.post('/api/cartes/generer/$clientId');
      return CarteModel.fromJson(res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Récupère la carte existante sans la régénérer.
  /// Lance une exception si le client n'a pas encore de carte.
  Future<CarteModel> getCarte(int clientId) async {
    try {
      final res = await _apiClient.dio.get('/api/cartes/$clientId');
      return CarteModel.fromJson(res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
