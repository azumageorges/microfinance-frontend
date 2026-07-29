class UtilisateurModel {
  final int id;
  final String nom;
  final String prenom;
  final String email;
  final String? telephone;
  final String role;
  final bool actif;
  final DateTime? createdAt;
  final DateTime? lastLogin;

  const UtilisateurModel({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.email,
    this.telephone,
    required this.role,
    required this.actif,
    this.createdAt,
    this.lastLogin,
  });

  String get fullName => '$prenom $nom';

  String get roleLabel {
    const labels = {
      'ADMIN': 'Administrateur',
      'AGENT_TERRAIN': 'Agent terrain',
      'GESTIONNAIRE_COMPTE': 'Gestionnaire de compte',
      'CAISSIER': 'Caissier',
    };
    return labels[role] ?? role;
  }

  factory UtilisateurModel.fromJson(Map<String, dynamic> json) =>
      UtilisateurModel(
        id: json['id'] as int,
        nom: json['nom'] as String,
        prenom: json['prenom'] as String,
        email: json['email'] as String,
        telephone: json['telephone'] as String?,
        role: json['role'] as String,
        actif: json['actif'] as bool? ?? true,
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'].toString())
            : null,
        lastLogin: json['lastLogin'] != null
            ? DateTime.tryParse(json['lastLogin'].toString())
            : null,
      );
}
