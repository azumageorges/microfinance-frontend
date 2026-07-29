import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../models/compte_model.dart';

class CompteRepository {
  final ApiClient _apiClient;

  CompteRepository(this._apiClient);

  Future<List<CompteModel>> getComptes() async {
    try {
      final res = await _apiClient.dio.get('/api/comptes');
      return (res.data['data'] as List)
          .map((e) => CompteModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<CompteModel>> getComptesByClient(int clientId) async {
    try {
      final res =
          await _apiClient.dio.get('/api/comptes/client/$clientId');
      return (res.data['data'] as List)
          .map((e) => CompteModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<CompteModel> getCompteByNumero(String numero) async {
    try {
      final res = await _apiClient.dio.get('/api/comptes/$numero');
      return CompteModel.fromJson(res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<CompteModel> createCompte(Map<String, dynamic> data) async {
    try {
      final res = await _apiClient.dio.post('/api/comptes', data: data);
      return CompteModel.fromJson(res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<CompteModel> bloquerCompte(String numero) async {
    try {
      final res =
          await _apiClient.dio.patch('/api/comptes/$numero/bloquer');
      return CompteModel.fromJson(res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<CompteModel> debloquerCompte(String numero) async {
    try {
      final res =
          await _apiClient.dio.patch('/api/comptes/$numero/debloquer');
      return CompteModel.fromJson(res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<CompteModel> cloturerCompte(String numero) async {
    try {
      final res =
          await _apiClient.dio.patch('/api/comptes/$numero/cloturer');
      return CompteModel.fromJson(res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
