import '../models/credit_model.dart';

/// Interface abstraite pour CreditRepository
/// Permet d'avoir des implémentations Web (API uniquement) et Mobile (SQLite + sync)
abstract class ICreditRepository {
  Future<List<CreditModel>> getCredits();
  Future<CreditModel> getCreditByReference(String reference);
  Future<List<CreditModel>> getCreditsByClient(int clientId);
  Future<List<CreditModel>> getCreditsByStatut(String statut);
  Future<CreditModel> createCredit(Map<String, dynamic> data);
  Future<CreditModel> demandeCredit(Map<String, dynamic> data);
  Future<CreditModel> validateCredit(String reference, Map<String, dynamic> data);
  Future<CreditModel> rejectCredit(String reference, String motif);
  Future<CreditModel> validerCredit(int id, {required bool approuve, String? motifRejet});
  Future<CreditModel> debloquerCredit(int id);
  Future<CreditModel> demanderDeblocage(int id);
  Future<CreditModel> validerDeblocage(int id, {required bool approuve, String? motifRejet});
  Future<CreditModel> executerDeblocage(int id);
  Future<CreditModel> rembourserEcheance(int echeanceId);
  Future<CreditModel> payerFrais(int creditId);
}
