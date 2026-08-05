import '../../core/network/api_client.dart';
import '../models/report_model.dart';
import 'report_repository_interface.dart';

class ReportRepositoryWeb implements IReportRepository {
  final ApiClient _apiClient;

  ReportRepositoryWeb(this._apiClient);

  @override
  Future<ReportModel> getRapportGlobal() async {
    final res = await _apiClient.dio.get('/api/rapports/global');
    return ReportModel.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  @override
  Future<ReportModel> getRapportComptes() async {
    final res = await _apiClient.dio.get('/api/rapports/comptes');
    return ReportModel.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  @override
  Future<ReportModel> getRapportTransactions(DateTime debut, DateTime fin) async {
    final res = await _apiClient.dio.get('/api/rapports/transactions', queryParameters: {
      'debut': debut.toIso8601String(),
      'fin': fin.toIso8601String(),
    });
    return ReportModel.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  @override
  Future<ReportModel> getRapportCredits() async {
    final res = await _apiClient.dio.get('/api/rapports/credits');
    return ReportModel.fromJson(res.data['data'] as Map<String, dynamic>);
  }
}
