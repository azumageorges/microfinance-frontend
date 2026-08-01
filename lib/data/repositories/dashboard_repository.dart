import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../models/dashboard_model.dart';

class DashboardRepository {
  final ApiClient _apiClient;

  DashboardRepository(this._apiClient);

  Future<DashboardModel> getDashboard() async {
    try {
      final res = await _apiClient.dio.get('/api/dashboard');
      return DashboardModel.fromJson(
          res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    } catch (e, stackTrace) {
      throw ApiException.from(e, stackTrace);
    }
  }
}
