import '../../core/network/api_client.dart';
import '../../core/network/api_request.dart';
import '../models/carte_model.dart';

export '../models/carte_model.dart';

class CarteRepository {
  final ApiClient _apiClient;

  CarteRepository(this._apiClient);

  /// Génère (ou régénère) la carte membre d'un client.
  /// Crée le numéro membre si inexistant côté backend.
  Future<CarteModel> genererCarte(int clientId) {
    return guardApi(() async => parseItem(
          await _apiClient.dio.post('/api/cartes/generer/$clientId'),
          CarteModel.fromJson,
        ));
  }

  /// Récupère la carte existante sans la régénérer.
  /// Lance une exception si le client n'a pas encore de carte.
  Future<CarteModel> getCarte(int clientId) {
    return guardApi(() async => parseItem(
          await _apiClient.dio.get('/api/cartes/$clientId'),
          CarteModel.fromJson,
        ));
  }
}
