import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../models/beneficiaire_model.dart';

class BeneficiaireRepository {
  final ApiClient _apiClient;

  BeneficiaireRepository(this._apiClient);

  Future<List<BeneficiaireModel>> getByClient(int clientId) async {
    try {
      final res = await _apiClient.dio
          .get('/api/beneficiaires/client/$clientId');
      return (res.data['data'] as List<dynamic>)
          .map((e) => BeneficiaireModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<BeneficiaireModel> create(Map<String, dynamic> data) async {
    try {
      final res =
          await _apiClient.dio.post('/api/beneficiaires', data: data);
      return BeneficiaireModel.fromJson(
          res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> delete(int id) async {
    try {
      await _apiClient.dio.delete('/api/beneficiaires/$id');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
