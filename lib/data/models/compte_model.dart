class CompteModel {
  final int id;
  final String numeroCompte;
  final String typeCompte;
  final String statut;
  final double solde;
  final double? soldeMinimum;
  final double? tauxInteret;
  final int? dureeEnMois;
  final DateTime? dateOuverture;
  final DateTime? dateEcheance;
  final double? montantAvecInterets;
  final double? montantCible;
  final String? representantLegal;
  final int clientId;
  final String nomClient;
  final String prenomClient;
  final DateTime? createdAt;

  const CompteModel({
    required this.id,
    required this.numeroCompte,
    required this.typeCompte,
    required this.statut,
    required this.solde,
    this.soldeMinimum,
    this.tauxInteret,
    this.dureeEnMois,
    this.dateOuverture,
    this.dateEcheance,
    this.montantAvecInterets,
    this.montantCible,
    this.representantLegal,
    required this.clientId,
    required this.nomClient,
    required this.prenomClient,
    this.createdAt,
  });

  String get clientFullName => '$prenomClient $nomClient';

  String get typeLabel {
    const labels = {
      'EPARGNE': 'Épargne',
      'DAT': 'Dépôt à Terme',
      'CREDIT': 'Crédit',
      'ENFANT': 'Enfant',
    };
    return labels[typeCompte] ?? typeCompte;
  }

  bool get isActif => statut == 'ACTIF';

  factory CompteModel.fromJson(Map<String, dynamic> json) => CompteModel(
        id: json['id'] as int,
        numeroCompte: json['numeroCompte'] as String,
        typeCompte: json['typeCompte'] as String,
        statut: json['statut'] as String,
        solde: (json['solde'] as num).toDouble(),
        soldeMinimum: json['soldeMinimum'] != null
            ? (json['soldeMinimum'] as num).toDouble()
            : null,
        tauxInteret: json['tauxInteret'] != null
            ? (json['tauxInteret'] as num).toDouble()
            : null,
        dureeEnMois: json['dureeEnMois'] as int?,
        dateOuverture: json['dateOuverture'] != null
            ? DateTime.tryParse(json['dateOuverture'].toString())
            : null,
        dateEcheance: json['dateEcheance'] != null
            ? DateTime.tryParse(json['dateEcheance'].toString())
            : null,
        montantAvecInterets: json['montantAvecInterets'] != null
            ? (json['montantAvecInterets'] as num).toDouble()
            : null,
        montantCible: json['montantCible'] != null
            ? (json['montantCible'] as num).toDouble()
            : null,
        representantLegal: json['representantLegal'] as String?,
        clientId: json['clientId'] as int,
        nomClient: json['nomClient'] as String,
        prenomClient: json['prenomClient'] as String,
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'].toString())
            : null,
      );
}
