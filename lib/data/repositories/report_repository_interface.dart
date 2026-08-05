import '../models/report_model.dart';

abstract class IReportRepository {
  Future<ReportModel> getRapportGlobal();
  Future<ReportModel> getRapportComptes();
  Future<ReportModel> getRapportTransactions(DateTime debut, DateTime fin);
  Future<ReportModel> getRapportCredits();
}
