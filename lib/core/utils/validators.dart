import 'package:flutter/widgets.dart';

/// Validateurs réutilisables pour tous les formulaires de l'application.
///
/// Objectifs :
/// - même logique partout (Web + Mobile)
/// - mêmes messages d'erreur (cohérence UX)
/// - éviter les oublis (ex: champ `required: true` sans validator)
class Validators {
  const Validators._();

  static String? Function(String?) combine(
    List<String? Function(String?)?> validators,
  ) {
    return (value) {
      for (final v in validators) {
        if (v == null) continue;
        final res = v(value);
        if (res != null) return res;
      }
      return null;
    };
  }

  static String? Function(String?) required({String message = 'Champ requis'}) {
    return (v) {
      if (v == null) return message;
      if (v.trim().isEmpty) return message;
      return null;
    };
  }

  static String? Function(String?) minLength(
    int min, {
    String? message,
  }) {
    return (v) {
      if (v == null) return null;
      if (v.trim().isEmpty) return null;
      if (v.trim().length < min) {
        return message ?? 'Minimum $min caractères';
      }
      return null;
    };
  }

  static String? Function(String?) maxLength(
    int max, {
    String? message,
  }) {
    return (v) {
      if (v == null) return null;
      if (v.trim().isEmpty) return null;
      if (v.trim().length > max) {
        return message ?? 'Maximum $max caractères';
      }
      return null;
    };
  }

  static final RegExp _emailRegex =
      RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  static String? Function(String?) email({bool isRequired = false}) {
    return combine([
      if (isRequired) required(message: 'Email requis'),
      (v) {
        if (v == null) return null;
        final value = v.trim();
        if (value.isEmpty) return null;
        if (!_emailRegex.hasMatch(value)) return 'Email invalide';
        return null;
      },
      maxLength(120, message: 'Email trop long'),
    ]);
  }

  /// Téléphone : uniquement des chiffres (le "+" n'est pas accepté dans l'app).
  /// Fourchette large pour supporter 8 chiffres (TG) et numéros internationaux
  /// si besoin.
  static String? Function(String?) phone({
    bool isRequired = false,
    int minDigits = 8,
    int maxDigits = 15,
  }) {
    return combine([
      if (isRequired) required(message: 'Téléphone requis'),
      (v) {
        if (v == null) return null;
        final value = v.trim();
        if (value.isEmpty) return null;
        if (!RegExp(r'^\d+$').hasMatch(value)) {
          return 'Téléphone invalide (chiffres uniquement)';
        }
        if (value.length < minDigits || value.length > maxDigits) {
          return 'Téléphone invalide ($minDigits à $maxDigits chiffres)';
        }
        return null;
      },
    ]);
  }

  /// Noms/prénoms : accepte lettres, espaces, apostrophes et tirets.
  static String? Function(String?) personName({
    bool isRequired = false,
    int max = 80,
    String label = 'Nom',
  }) {
    final allowed = RegExp(r"^[A-Za-zÀ-ÖØ-öø-ÿ' -]+$");
    return combine([
      if (isRequired) required(message: '$label requis'),
      (v) {
        if (v == null) return null;
        final value = v.trim();
        if (value.isEmpty) return null;
        if (!allowed.hasMatch(value)) {
          return '$label invalide';
        }
        return null;
      },
      maxLength(max, message: '$label : max $max caractères'),
      minLength(2, message: '$label : minimum 2 caractères'),
    ]);
  }

  static String? Function(String?) positiveNumber({
    bool isRequired = false,
    String messageRequired = 'Champ requis',
    String messageInvalid = 'Valeur invalide',
    double min = 0,
    double? max,
  }) {
    return combine([
      if (isRequired) required(message: messageRequired),
      (v) {
        if (v == null) return null;
        final value = v.trim();
        if (value.isEmpty) return null;
        final n = double.tryParse(value);
        if (n == null) return messageInvalid;
        if (n <= min) return messageInvalid;
        if (max != null && n > max) return messageInvalid;
        return null;
      },
    ]);
  }

  static String? Function(String?) integer({
    bool isRequired = false,
    int? min,
    int? max,
    String messageRequired = 'Champ requis',
    String messageInvalid = 'Valeur invalide',
  }) {
    return combine([
      if (isRequired) required(message: messageRequired),
      (v) {
        if (v == null) return null;
        final value = v.trim();
        if (value.isEmpty) return null;
        final n = int.tryParse(value);
        if (n == null) return messageInvalid;
        if (min != null && n < min) return messageInvalid;
        if (max != null && n > max) return messageInvalid;
        return null;
      },
    ]);
  }

  /// Numéro de compte : d'après le backend, il est généré sous la forme :
  /// EPC#########, DAT#########, CRD#########, ENF######### (9 chiffres).
  static final RegExp _numeroCompteRegex =
      RegExp(r'^(EPC|DAT|CRD|ENF)\d{9}$');

  static String? Function(String?) numeroCompte({bool isRequired = true}) {
    return combine([
      if (isRequired) required(message: 'Numéro de compte requis'),
      (v) {
        if (v == null) return null;
        final value = v.trim().toUpperCase();
        if (value.isEmpty) return null;
        if (!_numeroCompteRegex.hasMatch(value)) {
          return 'Format attendu : EPC/DAT/CRD/ENF + 9 chiffres';
        }
        return null;
      },
    ]);
  }

  /// Mot de passe : contrainte client identique à celle déjà utilisée
  /// pour la création d'utilisateur (min 8 + majuscule + minuscule + chiffre).
  static String? Function(String?) strongPassword({bool isRequired = true}) {
    return combine([
      if (isRequired) required(message: 'Mot de passe requis'),
      (v) {
        if (v == null) return null;
        if (v.isEmpty) return null;
        if (v.length < 8) return 'Minimum 8 caractères';
        if (!v.contains(RegExp(r'[a-z]'))) {
          return 'Doit contenir au moins une minuscule';
        }
        if (!v.contains(RegExp(r'[A-Z]'))) {
          return 'Doit contenir au moins une majuscule';
        }
        if (!v.contains(RegExp(r'[0-9]'))) {
          return 'Doit contenir au moins un chiffre';
        }
        return null;
      },
    ]);
  }

  static String? Function(String?) sameAs(
    TextEditingController other, {
    String message = 'Les valeurs ne correspondent pas',
  }) {
    return (v) {
      if (v != other.text) return message;
      return null;
    };
  }
}

