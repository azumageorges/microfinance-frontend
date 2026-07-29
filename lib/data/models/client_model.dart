import 'beneficiaire_model.dart';

class ClientModel {
  final int id;
  final String numeroClient;
  final String nom;
  final String prenom;
  final DateTime? dateNaissance;
  final String? lieuNaissance;
  final String telephone;
  final String? email;
  final String? adresse;
  final String? profession;
  final String? typePieceIdentite;
  final String? numeroPieceIdentite;
  final DateTime? dateExpirationPiece;
  final String? cheminPhoto;
  final String? numeroMembre;
  final String statut;
  final DateTime? createdAt;
  final List<BeneficiaireModel> beneficiaires;
  final int nombreComptes;

  const ClientModel({
    required this.id,
    required this.numeroClient,
    required this.nom,
    required this.prenom,
    this.dateNaissance,
    this.lieuNaissance,
    required this.telephone,
    this.email,
    this.adresse,
    this.profession,
    this.typePieceIdentite,
    this.numeroPieceIdentite,
    this.dateExpirationPiece,
    this.cheminPhoto,
    this.numeroMembre,
    required this.statut,
    this.createdAt,
    this.beneficiaires = const [],
    this.nombreComptes = 0,
  });

  String get fullName => '$prenom $nom';

  factory ClientModel.fromJson(Map<String, dynamic> json) => ClientModel(
        id: json['id'] as int,
        numeroClient: json['numeroClient'] as String,
        nom: json['nom'] as String,
        prenom: json['prenom'] as String,
        dateNaissance: json['dateNaissance'] != null
            ? DateTime.tryParse(json['dateNaissance'].toString())
            : null,
        lieuNaissance: json['lieuNaissance'] as String?,
        telephone: json['telephone'] as String,
        email: json['email'] as String?,
        adresse: json['adresse'] as String?,
        profession: json['profession'] as String?,
        typePieceIdentite: json['typePieceIdentite'] as String?,
        numeroPieceIdentite: json['numeroPieceIdentite'] as String?,
        dateExpirationPiece: json['dateExpirationPiece'] != null
            ? DateTime.tryParse(json['dateExpirationPiece'].toString())
            : null,
        cheminPhoto: json['cheminPhoto'] as String?,
        numeroMembre: json['numeroMembre'] as String?,
        statut: json['statut'] as String,
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'].toString())
            : null,
        beneficiaires: (json['beneficiaires'] as List<dynamic>? ?? [])
            .map((e) => BeneficiaireModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        nombreComptes: json['nombreComptes'] as int? ?? 0,
      );
}
