import '../models/compte_model.dart';

/// Interface abstraite pour CompteRepository
/// Permet d'avoir des implémentations Web (API uniquement) et Mobile (SQLite + sync)
abstract class ICompteRepository {
  Future<List<CompteModel>> getComptes();
  Future<List<CompteModel>> getComptesByClient(int clientId);
  Future<CompteModel> getCompteByNumero(String numero);
  Future<CompteModel> createCompte(Map<String, dynamic> data);
  Future<CompteModel> bloquerCompte(String numero);
  Future<CompteModel> debloquerCompte(String numero);
  Future<CompteModel> cloturerCompte(String numero);
  Future<CompteModel> modifierCompte(String numero, Map<String, dynamic> data);
  Future<void> supprimerCompte(String numero);
}
