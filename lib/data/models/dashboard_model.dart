import 'transaction_model.dart';

class DashboardModel {
  final int totalClients;
  final int clientsActifs;
  final int totalComptes;
  final double totalEpargne;
  final double totalDat;
  final double totalSoldes;
  final int creditsEnCours;
  final int creditsEnAttente;
  final double totalCreditsAccordes;
  final double totalEncours;
  final List<TransactionModel> transactionsRecentes;
  final double totalDepotsJour;
  final double totalRetraitsJour;
  final double totalTransferts30j;

  const DashboardModel({
    required this.totalClients,
    required this.clientsActifs,
    required this.totalComptes,
    required this.totalEpargne,
    required this.totalDat,
    required this.totalSoldes,
    required this.creditsEnCours,
    required this.creditsEnAttente,
    required this.totalCreditsAccordes,
    required this.totalEncours,
    required this.transactionsRecentes,
    required this.totalDepotsJour,
    required this.totalRetraitsJour,
    required this.totalTransferts30j,
  });

  factory DashboardModel.fromJson(Map<String, dynamic> json) => DashboardModel(
        totalClients: json['totalClients'] as int? ?? 0,
        clientsActifs: json['clientsActifs'] as int? ?? 0,
        totalComptes: json['totalComptes'] as int? ?? 0,
        totalEpargne: (json['totalEpargne'] as num? ?? 0).toDouble(),
        totalDat: (json['totalDat'] as num? ?? 0).toDouble(),
        totalSoldes: (json['totalSoldes'] as num? ?? 0).toDouble(),
        creditsEnCours: json['creditsEnCours'] as int? ?? 0,
        creditsEnAttente: json['creditsEnAttente'] as int? ?? 0,
        totalCreditsAccordes:
            (json['totalCreditsAccordes'] as num? ?? 0).toDouble(),
        totalEncours: (json['totalEncours'] as num? ?? 0).toDouble(),
        transactionsRecentes:
            (json['transactionsRecentes'] as List<dynamic>? ?? [])
                .map((e) =>
                    TransactionModel.fromJson(e as Map<String, dynamic>))
                .toList(),
        totalDepotsJour: (json['totalDepotsJour'] as num? ?? 0).toDouble(),
        totalRetraitsJour:
            (json['totalRetraitsJour'] as num? ?? 0).toDouble(),
        totalTransferts30j:
            (json['totalTransferts30j'] as num? ?? 0).toDouble(),
      );
}
