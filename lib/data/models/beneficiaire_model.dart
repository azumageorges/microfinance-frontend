class BeneficiaireModel {
  final int id;
  final String nom;
  final String prenom;
  final String telephone;
  final String? adresse;
  final String lienAvecClient;

  const BeneficiaireModel({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.telephone,
    this.adresse,
    required this.lienAvecClient,
  });

  String get fullName => '$prenom $nom';

  factory BeneficiaireModel.fromJson(Map<String, dynamic> json) =>
      BeneficiaireModel(
        id: json['id'] as int,
        nom: json['nom'] as String,
        prenom: json['prenom'] as String,
        telephone: json['telephone'] as String,
        adresse: json['adresse'] as String?,
        lienAvecClient: json['lienAvecClient'] as String,
      );
}
