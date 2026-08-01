import '../../core/network/api_client.dart';
import '../../core/network/api_request.dart';
import '../models/dashboard_model.dart';

class DashboardRepository {
  final ApiClient _apiClient;

  DashboardRepository(this._apiClient);

  Future<DashboardModel> getDashboard() {
    return guardApi(() async => parseItem(
          await _apiClient.dio.get('/api/dashboard'),
          DashboardModel.fromJson,
        ));
  }
}
