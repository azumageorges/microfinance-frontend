import 'dart:convert';

import '../models/beneficiaire_model.dart';
import '../models/client_model.dart';
import '../models/compte_model.dart';
import '../models/credit_model.dart';
import '../models/transaction_model.dart';
import 'sync_status.dart';

class LocalMappers {
  static ClientModel clientFromRow(Map<String, dynamic> row) {
    final beneficiairesJson = row['beneficiaires_json'] as String?;
    final beneficiaires = beneficiairesJson != null && beneficiairesJson.isNotEmpty
        ? (jsonDecode(beneficiairesJson) as List)
            .map((e) => BeneficiaireModel.fromJson(e as Map<String, dynamic>))
            .toList()
        : <BeneficiaireModel>[];

    return ClientModel(
      id: row['id'] as int,
      numeroClient: row['numero_client'] as String,
      nom: row['nom'] as String,
      prenom: row['prenom'] as String,
      dateNaissance: _parseDate(row['date_naissance']),
      lieuNaissance: row['lieu_naissance'] as String?,
      telephone: row['telephone'] as String,
      email: row['email'] as String?,
      adresse: row['adresse'] as String?,
      profession: row['profession'] as String?,
      typePieceIdentite: row['type_piece_identite'] as String?,
      numeroPieceIdentite: row['numero_piece_identite'] as String?,
      dateExpirationPiece: _parseDate(row['date_expiration_piece']),
      cheminPhoto: row['chemin_photo'] as String?,
      numeroMembre: row['numero_membre'] as String?,
      statut: row['statut'] as String,
      createdAt: _parseDate(row['created_at']),
      beneficiaires: beneficiaires,
      nombreComptes: row['nombre_comptes'] as int? ?? 0,
    );
  }

  static Map<String, dynamic> clientToRow(
    ClientModel client, {
    required SyncStatus syncStatus,
    String? localId,
  }) =>
      {
        'id': client.id,
        'local_id': localId,
        'numero_client': client.numeroClient,
        'nom': client.nom,
        'prenom': client.prenom,
        'date_naissance': client.dateNaissance?.toIso8601String(),
        'lieu_naissance': client.lieuNaissance,
        'telephone': client.telephone,
        'email': client.email,
        'adresse': client.adresse,
        'profession': client.profession,
        'type_piece_identite': client.typePieceIdentite,
        'numero_piece_identite': client.numeroPieceIdentite,
        'date_expiration_piece': client.dateExpirationPiece?.toIso8601String(),
        'chemin_photo': client.cheminPhoto,
        'numero_membre': client.numeroMembre,
        'statut': client.statut,
        'created_at': client.createdAt?.toIso8601String(),
        'beneficiaires_json': client.beneficiaires.isEmpty
            ? null
            : jsonEncode(
                client.beneficiaires
                    .map((b) => {
                          'id': b.id,
                          'nom': b.nom,
                          'prenom': b.prenom,
                          'telephone': b.telephone,
                          'adresse': b.adresse,
                          'lienAvecClient': b.lienAvecClient,
                        })
                    .toList(),
              ),
        'nombre_comptes': client.nombreComptes,
        'sync_status': syncStatus.value,
      };

  static CompteModel compteFromRow(Map<String, dynamic> row) => CompteModel(
        id: row['id'] as int,
        numeroCompte: row['numero_compte'] as String,
        typeCompte: row['type_compte'] as String,
        statut: row['statut'] as String,
        solde: (row['solde'] as num).toDouble(),
        soldeMinimum: row['solde_minimum'] != null
            ? (row['solde_minimum'] as num).toDouble()
            : null,
        tauxInteret: row['taux_interet'] != null
            ? (row['taux_interet'] as num).toDouble()
            : null,
        dureeEnMois: row['duree_en_mois'] as int?,
        dateOuverture: _parseDate(row['date_ouverture']),
        dateEcheance: _parseDate(row['date_echeance']),
        montantCible: row['montant_cible'] != null
            ? (row['montant_cible'] as num).toDouble()
            : null,
        representantLegal: row['representant_legal'] as String?,
        clientId: row['client_id'] as int,
        nomClient: row['nom_client'] as String,
        prenomClient: row['prenom_client'] as String,
        createdAt: _parseDate(row['created_at']),
      );

  static Map<String, dynamic> compteToRow(CompteModel compte) => {
        'id': compte.id,
        'numero_compte': compte.numeroCompte,
        'type_compte': compte.typeCompte,
        'statut': compte.statut,
        'solde': compte.solde,
        'solde_minimum': compte.soldeMinimum,
        'taux_interet': compte.tauxInteret,
        'duree_en_mois': compte.dureeEnMois,
        'date_ouverture': compte.dateOuverture?.toIso8601String(),
        'date_echeance': compte.dateEcheance?.toIso8601String(),
        'montant_cible': compte.montantCible,
        'representant_legal': compte.representantLegal,
        'client_id': compte.clientId,
        'nom_client': compte.nomClient,
        'prenom_client': compte.prenomClient,
        'created_at': compte.createdAt?.toIso8601String(),
        'sync_status': SyncStatus.synced.value,
      };

  static TransactionModel transactionFromRow(Map<String, dynamic> row) =>
      TransactionModel(
        id: row['id'] as int,
        reference: row['numero_transaction'] as String? ?? 'LOCAL-${row['id']}',
        typeTransaction: row['type'] as String,
        statut: row['statut'] as String? ?? 'EXECUTEE',
        montant: (row['montant'] as num).toDouble(),
        soldeAvant: row['solde_avant'] != null
            ? (row['solde_avant'] as num).toDouble()
            : null,
        soldeApres: row['solde_apres'] != null
            ? (row['solde_apres'] as num).toDouble()
            : null,
        motif: row['motif'] as String?,
        description: row['description'] as String?,
        motifRejet: row['motif_rejet'] as String?,
        numeroCompte: row['numero_compte'] as String,
        numeroCompteDestination: row['numero_compte_destination'] as String?,
        nomClient: row['nom_client'] as String?,
        effectuePar: row['effectue_par'] as String?,
        initiePar: row['initie_par'] as String?,
        validePar: row['valide_par'] as String?,
        dateTransaction: _parseDate(row['date']) ?? DateTime.now(),
        dateValidation: _parseDate(row['date_validation']),
        dateExecution: _parseDate(row['date_execution']),
      );

  static Map<String, dynamic> transactionToRow(
    TransactionModel transaction, {
    SyncStatus syncStatus = SyncStatus.synced,
    String? localId,
  }) =>
      {
        'id': transaction.id,
        'local_id': localId,
        'numero_transaction': transaction.reference,
        'type': transaction.typeTransaction,
        'statut': transaction.statut,
        'montant': transaction.montant,
        'date': transaction.dateTransaction.toIso8601String(),
        'solde_avant': transaction.soldeAvant,
        'solde_apres': transaction.soldeApres,
        'motif': transaction.motif,
        'description': transaction.description,
        'motif_rejet': transaction.motifRejet,
        'numero_compte': transaction.numeroCompte,
        'numero_compte_destination': transaction.numeroCompteDestination,
        'nom_client': transaction.nomClient,
        'effectue_par': transaction.effectuePar,
        'initie_par': transaction.initiePar,
        'valide_par': transaction.validePar,
        'date_validation': transaction.dateValidation?.toIso8601String(),
        'date_execution': transaction.dateExecution?.toIso8601String(),
        'sync_status': syncStatus.value,
        'created_at': transaction.dateTransaction.toIso8601String(),
      };

  static CreditModel creditFromRow(Map<String, dynamic> row) {
    // Désérialisation des échéances stockées en JSON
    final echeancesJson = row['echeances_json'] as String?;
    final echeances = (echeancesJson != null && echeancesJson.isNotEmpty)
        ? (jsonDecode(echeancesJson) as List)
            .map((e) => EcheanceModel.fromJson(e as Map<String, dynamic>))
            .toList()
        : <EcheanceModel>[];

    return CreditModel(
      id:                     row['id'] as int,
      referenceCredit:        row['reference_credit'] as String? ?? '',
      montantAccorde:         _toDoubleOrNull(row['montant_accorde']),
      typeCredit:             row['type_credit'] as String? ?? 'MENSUEL',
      miseQuotidienne:        _toDouble(row['mise_quotidienne']),
      fraisCredit:            _toDouble(row['frais_credit']),
      nombreEcheances:        row['nombre_echeances'] as int? ?? 0,
      totalARembourser:       _toDoubleOrNull(row['total_a_rembourser']),
      totalRembourse:         _toDouble(row['total_rembourse']),
      resteARembourser:       _toDoubleOrNull(row['reste_a_rembourser']),
      statut:                 row['statut'] as String? ?? 'EN_ATTENTE',
      motifDemande:           row['motif_demande'] as String?,
      motifRejet:             row['motif_rejet'] as String?,
      dateDemande:            _parseDate(row['date_demande']),
      dateValidation:         _parseDate(row['date_validation']),
      dateDeblocage:          _parseDate(row['date_deblocage']),
      dateFin:                _parseDate(row['date_fin']),
      numeroCompte:           row['numero_compte'] as String? ?? '',
      nomClient:              row['nom_client'] as String?,
      createdAt:              _parseDate(row['created_at']),
      echeances:              echeances,
    );
  }

  static Map<String, dynamic> creditToRow(CreditModel credit) => {
        'id':                     credit.id,
        'reference_credit':       credit.referenceCredit,
        'montant_demande':        credit.montantPret,
        'montant_accorde':        credit.montantAccorde,
        'statut':                 credit.statut,
        'statut_label':           credit.statutLabel,
        'type_credit':            credit.typeCredit,
        'mise_quotidienne':       credit.miseQuotidienne,
        'frais_credit':           credit.fraisCredit,
        'nombre_echeances':       credit.nombreEcheances,
        'taux_interet':           0,
        'duree_en_mois':          credit.nombreEcheances,
        'total_a_rembourser':     credit.totalARembourser,
        'total_rembourse':        credit.totalRembourse,
        'reste_a_rembourser':     credit.resteARembourser,
        'progression':            credit.progressionRemboursement,
        'nombre_echeances_payees': credit.nombreEcheancesPayees,
        // client_id = 0 si inconnu localement (sera corrigé après sync)
        'client_id':              0,
        'nom_client':             credit.nomClient,
        'numero_compte':          credit.numeroCompte,
        'motif_demande':          credit.motifDemande,
        'motif_rejet':            credit.motifRejet,
        'date_demande':           credit.dateDemande?.toIso8601String(),
        'date_validation':        credit.dateValidation?.toIso8601String(),
        'date_deblocage':         credit.dateDeblocage?.toIso8601String(),
        'date_fin':               credit.dateFin?.toIso8601String(),
        'echeances_json':         credit.echeances.isEmpty
            ? null
            : jsonEncode(credit.echeances
                .map((e) => {
                      'id':             e.id,
                      'numeroEcheance': e.numeroEcheance,
                      'datePrevue':     e.datePrevue.toIso8601String(),
                      'datePaiement':   e.datePaiement?.toIso8601String(),
                      'montantDu':      e.montantDu,
                      'montantPaye':    e.montantPaye,
                      'soldeRestant':   e.soldeRestant,
                      'statut':         e.statut,
                      'paye':           e.paye,
                    })
                .toList()),
        'created_at':             credit.createdAt?.toIso8601String(),
        'sync_status':            SyncStatus.synced.value,
      };

  static double _toDouble(dynamic v) =>
      v == null ? 0.0 : (v as num).toDouble();

  static double? _toDoubleOrNull(dynamic v) =>
      v == null ? null : (v as num).toDouble();

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}
