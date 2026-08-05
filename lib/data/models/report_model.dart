class ReportModel {
  final Map<String, dynamic> data;

  ReportModel({required this.data});

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(data: json);
  }
}
