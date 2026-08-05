String _stringValue(dynamic value, [String fallback = '']) {
  if (value == null) return fallback;
  final text = value.toString().trim();
  return text.isEmpty ? fallback : text;
}

double _doubleValue(dynamic value, [double fallback = 0]) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? fallback;
}

int _intValue(dynamic value, [int fallback = 0]) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

bool _boolValue(dynamic value, [bool fallback = false]) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  final text = value?.toString().toLowerCase().trim();
  if (text == 'true' || text == '1') return true;
  if (text == 'false' || text == '0') return false;
  return fallback;
}

DateTime? _dateTimeValue(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}

class EcheanceModel {
  final int id;
  final int numeroEcheance;
  final DateTime datePrevue;
  final DateTime? datePaiement;
  final double montantDu;
  final double? montantPaye;
  final double? soldeRestant;
  final String statut;
  final bool paye;

  const EcheanceModel({
    required this.id,
    required this.numeroEcheance,
    required this.datePrevue,
    this.datePaiement,
    required this.montantDu,
    this.montantPaye,
    this.soldeRestant,
    required this.statut,
    required this.paye,
  });

  String get statutLabel {
    const labels = {
      'EN_ATTENTE': 'En attente',
      'PAYEE': 'Payée',
      'EN_RETARD': 'En retard',
    };
    return labels[statut] ?? statut;
  }

  factory EcheanceModel.fromJson(Map<String, dynamic> json) => EcheanceModel(
        id: _intValue(json['id']),
        numeroEcheance: _intValue(json['numeroEcheance']),
        datePrevue: _dateTimeValue(json['datePrevue']) ?? DateTime.now(),
        datePaiement: _dateTimeValue(json['datePaiement']),
        montantDu: _doubleValue(json['montantDu']),
        montantPaye: json['montantPaye'] != null
            ? _doubleValue(json['montantPaye'])
            : null,
        soldeRestant: json['soldeRestant'] != null
            ? _doubleValue(json['soldeRestant'])
            : null,
        statut: _stringValue(json['statut'], 'EN_ATTENTE'),
        paye: _boolValue(json['paye']),
      );
}

class CreditModel {
  final int id;
  final String referenceCredit;
  final double? montantAccorde;
  final String typeCredit;
  final double miseQuotidienne;
  final double fraisCredit;
  final int nombreEcheances;
  final double montantUneEcheance;   // montant de chaque échéance (= mise quotidienne)
  final double? totalARembourser;
  final double totalRembourse;
  final double? resteARembourser;
  // Frais — payés séparément AVANT les échéances de capital
  final bool fraisPaye;
  final DateTime? datePaiementFrais;
  final String statut;
  final String? statutLabelBackend;
  final String? motifDemande;
  final String? motifRejet;
  final String? motifRejetDeblocage;
  final DateTime? dateDemande;
  final DateTime? dateValidation;
  final DateTime? dateDemandeDeblocage;
  final DateTime? dateDeblocage;
  final DateTime? dateFin;
  final String numeroCompte;
  final String? nomClient;
  final String? debloquePar;
  final String? deblocageValidePar;
  final DateTime? createdAt;
  final List<EcheanceModel> echeances;

  const CreditModel({
    required this.id,
    required this.referenceCredit,
    this.montantAccorde,
    required this.typeCredit,
    required this.miseQuotidienne,
    required this.fraisCredit,
    required this.nombreEcheances,
    this.montantUneEcheance = 0,
    this.totalARembourser,
    required this.totalRembourse,
    this.resteARembourser,
    this.fraisPaye = false,
    this.datePaiementFrais,
    required this.statut,
    this.statutLabelBackend,
    this.motifDemande,
    this.motifRejet,
    this.motifRejetDeblocage,
    this.dateDemande,
    this.dateValidation,
    this.dateDemandeDeblocage,
    this.dateDeblocage,
    this.dateFin,
    required this.numeroCompte,
    this.nomClient,
    this.debloquePar,
    this.deblocageValidePar,
    this.createdAt,
    this.echeances = const [],
  });

  String get statutLabel {
    const labels = {
      'EN_ATTENTE': 'En attente',
      'VALIDE': 'Validé',
      'DEBLOCAGE_EN_ATTENTE': 'Déblocage en attente',
      'REJETE': 'Rejeté',
      'EN_COURS': 'En cours',
      'REMBOURSE': 'Remboursé',
      'EN_RETARD': 'En retard',
      'CONTENTIEUX': 'Contentieux',
    };
    return statutLabelBackend ?? labels[statut] ?? statut;
  }

  String get typeCreditLabel {
    const labels = {
      'QUINZAINE': 'Quinzaine',
      'MENSUEL': 'Mensuel',
    };
    return labels[typeCredit] ?? typeCredit;
  }

  int get nombreJoursRemboursement =>
      typeCredit == 'QUINZAINE' ? 15 : 30;

  int get nombreEcheancesPayees =>
      echeances.where((e) => e.paye).length;

  double get montantPret => montantAccorde ?? 0;

  double get progressionRemboursement {
    if (totalARembourser == null || totalARembourser == 0) return 0;
    return totalRembourse / totalARembourser!;
  }

  factory CreditModel.fromJson(Map<String, dynamic> json) => CreditModel(
        id: _intValue(json['id']),
        referenceCredit: _stringValue(
          json['referenceCredit'],
          'CRD-LEGACY-${_intValue(json['id'])}',
        ),
        montantAccorde: json['montantAccorde'] != null
            ? _doubleValue(json['montantAccorde'])
            : null,
        typeCredit: _stringValue(
          json['typeCredit'],
          (_intValue(json['nombreEcheances']) == 31) ? 'MENSUEL' : 'QUINZAINE',
        ),
        miseQuotidienne: _doubleValue(json['miseQuotidienne']),
        fraisCredit: _doubleValue(json['fraisCredit']),
        nombreEcheances: json['nombreEcheances'] != null
            ? _intValue(json['nombreEcheances'])
            :
            ((json['echeances'] as List<dynamic>? ?? []).length),
        montantUneEcheance: json['montantUneEcheance'] != null
            ? _doubleValue(json['montantUneEcheance'])
            : _doubleValue(json['miseQuotidienne']), // fallback = mise quotidienne
        totalARembourser: json['totalARembourser'] != null
            ? _doubleValue(json['totalARembourser'])
            : null,
        totalRembourse: _doubleValue(json['totalRembourse']),
        resteARembourser: json['resteARembourser'] != null
            ? _doubleValue(json['resteARembourser'])
            : null,
        fraisPaye: _boolValue(json['fraisPaye']),
        datePaiementFrais: _dateTimeValue(json['datePaiementFrais']),
        statut: _stringValue(json['statut'], 'EN_ATTENTE'),
        statutLabelBackend: json['statutLabel'] != null
            ? _stringValue(json['statutLabel'])
            : null,
        motifDemande: json['motifDemande'] != null
            ? _stringValue(json['motifDemande'])
            : null,
        motifRejet: json['motifRejet'] != null
            ? _stringValue(json['motifRejet'])
            : null,
        motifRejetDeblocage: json['motifRejetDeblocage'] != null
            ? _stringValue(json['motifRejetDeblocage'])
            : null,
        dateDemande: _dateTimeValue(json['dateDemande']),
        dateValidation: _dateTimeValue(json['dateValidation']),
        dateDemandeDeblocage: _dateTimeValue(json['dateDemandeDeblocage']),
        dateDeblocage: _dateTimeValue(json['dateDeblocage']),
        dateFin: _dateTimeValue(json['dateFin']),
        numeroCompte: _stringValue(json['numeroCompte'], 'N/A'),
        nomClient: json['nomClient'] != null
            ? _stringValue(json['nomClient'])
            : null,
        debloquePar: json['debloquePar'] != null
            ? _stringValue(json['debloquePar'])
            : null,
        deblocageValidePar: json['deblocageValidePar'] != null
            ? _stringValue(json['deblocageValidePar'])
            : null,
        createdAt: _dateTimeValue(json['createdAt']),
        echeances: (json['echeances'] as List<dynamic>? ?? [])
            .map((e) => e is Map<String, dynamic>
                ? EcheanceModel.fromJson(e)
                : EcheanceModel.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
}
