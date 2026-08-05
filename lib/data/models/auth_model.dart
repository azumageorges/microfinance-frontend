class AuthResponse {
  final String token;
  final String type;
  final int userId;
  final String nom;
  final String prenom;
  final String email;
  final String role;

  const AuthResponse({
    required this.token,
    required this.type,
    required this.userId,
    required this.nom,
    required this.prenom,
    required this.email,
    required this.role,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
        token: json['token'] as String,
        type: json['type'] as String? ?? 'Bearer',
        userId: (json['userId'] as num).toInt(),
        nom: json['nom'] as String,
        prenom: json['prenom'] as String,
        email: json['email'] as String,
        role: (json['role'] as String?) ?? '',
      );

  String get fullName => '$prenom $nom';

  bool get isAdmin => role == 'ADMIN';
  bool get isAgentTerrain => role == 'AGENT_TERRAIN';
  bool get isGestionnaire => role == 'GESTIONNAIRE_COMPTE';
  bool get isCaissier => role == 'CAISSIER';

  /// Détermine si l'utilisateur doit utiliser l'interface web (bureau)
  bool get isWebUser => isAdmin || isGestionnaire || isCaissier;

  /// Détermine si l'utilisateur doit utiliser l'interface mobile (terrain)
  bool get isMobileUser => isAgentTerrain;

  /// Page d'accueil selon le rôle après connexion.
  String get homeRoute {
    if (isAdmin || isGestionnaire) return '/dashboard';
    if (isCaissier) return '/caisse';
    // Agent terrain → interface mobile
    return '/terrain';
  }

  bool get canAccessDashboard => isAdmin || isGestionnaire;
  bool get canAccessUtilisateurs => isAdmin;
  bool get canManageComptes => isAdmin || isGestionnaire;
  bool get canAccessTransactions => isAdmin || isGestionnaire || isCaissier;
  bool get canDoTransactions => isAdmin || isGestionnaire || isCaissier;
  bool get canValidateSensitiveTransactions => isAdmin || isGestionnaire;
  bool get canExecuteSensitiveTransactions =>
      isAdmin || isGestionnaire || isCaissier;
  bool get canValidateCredits => isGestionnaire;
  bool get canDebloquerCredits => isCaissier;

  Map<String, dynamic> toJson() => {
        'token': token,
        'type': type,
        'userId': userId,
        'nom': nom,
        'prenom': prenom,
        'email': email,
        'role': role,
      };
}
