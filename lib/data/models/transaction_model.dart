class TransactionModel {
  final int id;
  final String reference;
  final String typeTransaction;
  final String statut;
  final double montant;
  final double? soldeAvant;
  final double? soldeApres;
  final String? motif;
  final String? description;
  final String? motifRejet;
  final String numeroCompte;
  final String? numeroCompteDestination;
  final String? nomClient;
  final String? effectuePar;
  final String? initiePar;
  final String? validePar;
  final DateTime dateTransaction;
  final DateTime? dateValidation;
  final DateTime? dateExecution;

  const TransactionModel({
    required this.id,
    required this.reference,
    required this.typeTransaction,
    required this.statut,
    required this.montant,
    this.soldeAvant,
    this.soldeApres,
    this.motif,
    this.description,
    this.motifRejet,
    required this.numeroCompte,
    this.numeroCompteDestination,
    this.nomClient,
    this.effectuePar,
    this.initiePar,
    this.validePar,
    required this.dateTransaction,
    this.dateValidation,
    this.dateExecution,
  });

  String get typeLabel {
    const labels = {
      'DEPOT': 'Dépôt',
      'RETRAIT': 'Retrait',
      'TRANSFERT': 'Transfert',
      'PAIEMENT': 'Paiement',
      'REMBOURSEMENT': 'Remboursement',
      'PENALITE': 'Pénalité',
      'INTERET': 'Intérêt',
      'VERSEMENT_ACHAT': 'Versement achat',
    };
    return labels[typeTransaction] ?? typeTransaction;
  }

  String get statutLabel {
    const labels = {
      'EN_ATTENTE': 'En attente',
      'VALIDEE': 'Validée',
      'REJETEE': 'Rejetée',
      'EXECUTEE': 'Exécutée',
    };
    return labels[statut] ?? statut;
  }

  bool get isCredit => typeTransaction == 'DEPOT' || typeTransaction == 'INTERET';
  bool get isSensitive =>
      typeTransaction == 'RETRAIT' || typeTransaction == 'TRANSFERT';
  bool get isExecuted => statut == 'EXECUTEE';
  bool get isPendingValidation => statut == 'EN_ATTENTE';
  bool get isValidated => statut == 'VALIDEE';
  bool get isRejected => statut == 'REJETEE';

  factory TransactionModel.fromJson(Map<String, dynamic> json) =>
      TransactionModel(
        id: json['id'] as int,
        reference: json['reference'] as String,
        typeTransaction: json['typeTransaction'] as String,
        statut: (json['statut'] as String?) ?? 'EXECUTEE',
        montant: (json['montant'] as num).toDouble(),
        soldeAvant: json['soldeAvant'] != null
            ? (json['soldeAvant'] as num).toDouble()
            : null,
        soldeApres: json['soldeApres'] != null
            ? (json['soldeApres'] as num).toDouble()
            : null,
        motif: json['motif'] as String?,
        description: json['description'] as String?,
        motifRejet: json['motifRejet'] as String?,
        numeroCompte: json['numeroCompte'] as String,
        numeroCompteDestination: json['numeroCompteDestination'] as String?,
        nomClient: json['nomClient'] as String?,
        effectuePar: json['effectuePar'] as String?,
        initiePar: json['initiePar'] as String?,
        validePar: json['validePar'] as String?,
        dateTransaction: DateTime.parse(json['dateTransaction'] as String),
        dateValidation: json['dateValidation'] != null
            ? DateTime.tryParse(json['dateValidation'] as String)
            : null,
        dateExecution: json['dateExecution'] != null
            ? DateTime.tryParse(json['dateExecution'] as String)
            : null,
      );
}
