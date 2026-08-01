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

  ClientModel copyWith({
    String? nom,
    String? prenom,
    DateTime? dateNaissance,
    String? lieuNaissance,
    String? telephone,
    String? email,
    String? adresse,
    String? profession,
    String? typePieceIdentite,
    String? numeroPieceIdentite,
    DateTime? dateExpirationPiece,
    String? cheminPhoto,
    String? numeroMembre,
    String? statut,
  }) =>
      ClientModel(
        id: id,
        numeroClient: numeroClient,
        nom: nom ?? this.nom,
        prenom: prenom ?? this.prenom,
        dateNaissance: dateNaissance ?? this.dateNaissance,
        lieuNaissance: lieuNaissance ?? this.lieuNaissance,
        telephone: telephone ?? this.telephone,
        email: email ?? this.email,
        adresse: adresse ?? this.adresse,
        profession: profession ?? this.profession,
        typePieceIdentite: typePieceIdentite ?? this.typePieceIdentite,
        numeroPieceIdentite: numeroPieceIdentite ?? this.numeroPieceIdentite,
        dateExpirationPiece: dateExpirationPiece ?? this.dateExpirationPiece,
        cheminPhoto: cheminPhoto ?? this.cheminPhoto,
        numeroMembre: numeroMembre ?? this.numeroMembre,
        statut: statut ?? this.statut,
        createdAt: createdAt,
        beneficiaires: beneficiaires,
        nombreComptes: nombreComptes,
      );

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
