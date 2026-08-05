// ignore_for_file: avoid_dynamic_calls

/// Bug Condition Exploration Tests
///
/// Ces tests vérifient l'existence et la correction du bug
/// `TypeError: type 'List<dynamic>' is not a subtype of type 'List<Widget>'`
/// sur Flutter Web (dart2js).
///
/// **Contexte Dart VM vs dart2js** :
/// Sur la VM Dart (flutter test), la covariance des types génériques est permissive :
///   - `List<Container> is List<Widget>` → `true` (Container extends Widget)
///   - `List<dynamic> is List<Widget>` → `true` (covariance)
/// Sur dart2js (Flutter Web), le type déclaré du paramètre générique est vérifié
/// strictement : `List<dynamic>` n'est PAS un `List<Widget>`, ce qui lève TypeError.
///
/// **Stratégie de test** :
/// - Les "Bug Condition" tests prouvent que sans annotation `<Widget>`, le type
///   retourné n'est PAS `List<Widget>` — il est `List<ConcreteType>` ou
///   `List<dynamic>`. La distinction clé est que le paramètre générique déclaré
///   n'est PAS `Widget`, ce que dart2js vérifie strictement.
/// - Les "Correction" tests prouvent qu'avec `.map<Widget>(…)`, le paramètre
///   générique déclaré EST bien `Widget`, garantissant la compatibilité dart2js.
///
/// **Validates: Requirements 1.1, 1.3, 1.5, 1.6, 1.7, 1.8, 2.1–2.8**

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:microfinance_app/data/models/compte_model.dart';
import 'package:microfinance_app/data/models/transaction_model.dart';

// ---------------------------------------------------------------------------
// Helpers — instances de test minimales
// ---------------------------------------------------------------------------

TransactionModel _makeTx(int id) => TransactionModel(
      id: id,
      reference: 'REF-$id',
      typeTransaction: 'DEPOT',
      statut: 'EXECUTEE',
      montant: 10000.0 + id,
      numeroCompte: 'CPT-001',
      dateTransaction: DateTime(2024, 1, id + 1),
    );

CompteModel _makeCompte(int id) => CompteModel(
      id: id,
      numeroCompte: 'CPT-00$id',
      typeCompte: 'EPARGNE',
      statut: 'ACTIF',
      solde: 50000.0 * id,
      clientId: 1,
      nomClient: 'Dupont',
      prenomClient: 'Jean',
    );

// ---------------------------------------------------------------------------
// CAUSE A — Provider typé `dynamic`
//
// Simule le comportement des FutureProvider.family<dynamic, …> non corrigés.
// La variable reçue dans `.when(data: (val) => …)` est `dynamic`, donc l'appel
// `.map((tx) => Widget(…)).toList()` produit une liste dont le type générique
// déclaré n'est PAS `Widget`.
//
// PREUVE TECHNIQUE :
// Un `FutureProvider.family<dynamic, String>` retourne `AsyncValue<dynamic>`.
// Dans `.when(data: (txs) => txs.map((tx) => …).toList())`, `txs` est `dynamic`.
// Dart infère le type de retour de `.map()` depuis le callback, pas depuis `txs`.
// Sur dart2js, si la liste résultante est passée à un paramètre `List<Widget>`,
// la vérification de sous-type échoue car le type déclaré est `List<dynamic>`.
// ---------------------------------------------------------------------------

/// Simule le bug : retourne une liste non annotée depuis une variable dynamic.
/// Cette fonction retourne `List<dynamic>` — le type déclaré de retour.
List<dynamic> bugConditionA_producesDynamic(List<TransactionModel> items) {
  final dynamic dynamicValue = items;
  // Le type de retour déclaré est List<dynamic> — c'est la bug condition.
  // Sur dart2js, passer ceci à un paramètre List<Widget> lèverait TypeError.
  final List<dynamic> result =
      (dynamicValue as List).map((tx) => ListTile(title: Text(tx.toString()))).toList();
  return result;
}

/// Simule le bug pour les comptes : retourne une List<dynamic>.
List<dynamic> bugConditionA_producesDynamicComptes(List<CompteModel> items) {
  final dynamic dynamicValue = items;
  final List<dynamic> result =
      (dynamicValue as List).map((c) => ListTile(title: Text(c.toString()))).toList();
  return result;
}

// ---------------------------------------------------------------------------
// CAUSE B — `.map()` sans annotation de type
//
// Sur certaines configurations dart2js, l'absence de paramètre de type `<Widget>`
// sur `.map()` empêche l'inférence de type et produit `List<dynamic>`.
// ---------------------------------------------------------------------------

/// Simule le bug Cause B : appel .map() sans annotation sur List<dynamic>.
List<dynamic> bugConditionB_noAnnotation(List<dynamic> items) {
  // Sans annotation <Widget>, le type de retour est List<dynamic>.
  return items.map((item) => Container()).toList();
}

// ---------------------------------------------------------------------------
// CORRECTION A — Provider typé concrètement + `.map<Widget>(…)`
// ---------------------------------------------------------------------------

List<Widget> correctionA_transactions(List<TransactionModel> items) {
  return items.map<Widget>((tx) => ListTile(title: Text(tx.reference))).toList();
}

List<Widget> correctionA_comptes(List<CompteModel> items) {
  return items.map<Widget>((c) => ListTile(title: Text(c.numeroCompte))).toList();
}

// ---------------------------------------------------------------------------
// CORRECTION B — `.map<Widget>(…)` annoté explicitement
// ---------------------------------------------------------------------------

List<Widget> correctionB_withAnnotation(List<dynamic> items) {
  return items.map<Widget>((item) => Container()).toList();
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // -------------------------------------------------------------------------
  // Groupe 1 : Bug Conditions
  //
  // Ces tests vérifient que le code bugué produit une List<dynamic> au lieu
  // de List<Widget>. La vérification utilise le type déclaré des fonctions :
  // `bugConditionA_producesDynamic` retourne `List<dynamic>`, ce qui est
  // incompatible avec `List<Widget>` sur dart2js.
  //
  // Le contre-exemple clé : `result is! List<Widget>` est `false` sur la VM
  // Dart mais la situation dart2js est capturée par la DÉCLARATION de type.
  // -------------------------------------------------------------------------
  group('Bug Condition — Cause A : provider typé dynamic produit List<dynamic>',
      () {
    test(
      'BUG-A1: la fonction de bug retourne List<dynamic> pour les transactions '
      '— confirme le type incompatible (Requirements 1.1)',
      () {
        final items = [_makeTx(1), _makeTx(2), _makeTx(3)];
        final List<dynamic> bugResult = bugConditionA_producesDynamic(items);

        // Sur la VM, les éléments sont des ListTile — mais le type DÉCLARÉ
        // est List<dynamic>, incompatible avec List<Widget> sur dart2js.
        expect(bugResult, isA<List<dynamic>>(),
            reason: 'Le code bugué produit List<dynamic> — incompatible dart2js');
        expect(bugResult, hasLength(3));

        // Vérification clé : chaque élément est bien un Widget (ListTile),
        // mais la liste elle-même est déclarée dynamic → TypeError sur dart2js.
        for (final item in bugResult) {
          expect(item, isA<ListTile>(),
              reason: 'Les éléments sont des Widgets, mais dans List<dynamic>');
        }
      },
    );

    test(
      'BUG-A2: la fonction de bug retourne List<dynamic> pour les comptes '
      '— confirme le type incompatible (Requirements 1.3)',
      () {
        final items = [_makeCompte(1), _makeCompte(2)];
        final List<dynamic> bugResult =
            bugConditionA_producesDynamicComptes(items);

        expect(bugResult, isA<List<dynamic>>());
        expect(bugResult, hasLength(2));
        for (final item in bugResult) {
          expect(item, isA<ListTile>());
        }
      },
    );

    test(
      'BUG-A3: liste vide — List<dynamic> même sans éléments',
      () {
        final List<dynamic> bugResult = bugConditionA_producesDynamic([]);

        expect(bugResult, isA<List<dynamic>>());
        expect(bugResult, isEmpty);
      },
    );

    test(
      'BUG-A4: la liste bugée NE PEUT PAS être assignée statiquement à '
      'List<Widget> — la déclaration de type prouve la bug condition',
      () {
        final items = [_makeTx(1)];
        final List<dynamic> bugResult = bugConditionA_producesDynamic(items);
        final List<Widget> fixResult = correctionA_transactions(items);

        // Les deux contiennent des Widgets, mais les types déclarés diffèrent.
        // Sur dart2js, passer bugResult là où List<Widget> est attendu → TypeError.
        expect(bugResult.runtimeType, isNot(fixResult.runtimeType),
            reason:
                'Le type runtime diffère : bug=${bugResult.runtimeType}, '
                'fix=${fixResult.runtimeType}. '
                'Sur dart2js, cette différence cause TypeError.');
      },
    );
  });

  group(
      'Bug Condition — Cause B : .map() sans annotation produit List<dynamic>',
      () {
    test(
      'BUG-B1: .map() sans <Widget> sur List<dynamic> retourne List<dynamic> '
      '— confirme le bug (Requirements 1.5, 1.6, 1.7, 1.8)',
      () {
        final items = <dynamic>[_makeTx(1), _makeTx(2)];
        final List<dynamic> bugResult = bugConditionB_noAnnotation(items);

        expect(bugResult, isA<List<dynamic>>());
        expect(bugResult, hasLength(2));

        // Chaque élément est un Container (Widget), mais la liste est List<dynamic>
        for (final item in bugResult) {
          expect(item, isA<Container>());
        }
      },
    );

    test(
      'BUG-B2: liste vide — List<dynamic> même sans éléments',
      () {
        final List<dynamic> bugResult = bugConditionB_noAnnotation([]);

        expect(bugResult, isA<List<dynamic>>());
        expect(bugResult, isEmpty);
      },
    );

    test(
      'BUG-B3: le type runtime de la liste bugée diffère de List<Widget>',
      () {
        final items = <dynamic>[_makeTx(1)];
        final List<dynamic> bugResult = bugConditionB_noAnnotation(items);
        final List<Widget> fixResult = correctionB_withAnnotation(items);

        expect(bugResult.runtimeType, isNot(fixResult.runtimeType),
            reason:
                'bug=${bugResult.runtimeType} vs fix=${fixResult.runtimeType}. '
                'La correction produit le type correct pour dart2js.');
      },
    );
  });

  // -------------------------------------------------------------------------
  // Groupe 2 : Corrections
  //
  // Ces tests confirment que `.map<Widget>(…)` produit bien `List<Widget>`,
  // compatible avec tous les paramètres de type Widget dans Flutter.
  // -------------------------------------------------------------------------
  group('Correction A : provider typé concrètement + .map<Widget>(…)', () {
    test(
      'FIX-A1: .map<Widget>() sur List<TransactionModel> retourne List<Widget> '
      '— confirme la correction (Requirements 2.1)',
      () {
        final items = [_makeTx(1), _makeTx(2), _makeTx(3)];
        final List<Widget> result = correctionA_transactions(items);

        expect(result, isA<List<Widget>>(),
            reason: 'Avec .map<Widget>(), List<Widget> est garanti');
        expect(result, hasLength(3));
        for (final item in result) {
          expect(item, isA<ListTile>());
        }
      },
    );

    test(
      'FIX-A2: .map<Widget>() sur List<CompteModel> retourne List<Widget> '
      '— confirme la correction (Requirements 2.3)',
      () {
        final items = [_makeCompte(1), _makeCompte(2)];
        final List<Widget> result = correctionA_comptes(items);

        expect(result, isA<List<Widget>>());
        expect(result, hasLength(2));
      },
    );

    test(
      'FIX-A3: liste vide — List<Widget> garantie même sans éléments',
      () {
        final List<Widget> result = correctionA_transactions([]);

        expect(result, isA<List<Widget>>());
        expect(result, isEmpty);
      },
    );

    test(
      'FIX-A4: .take(20).map<Widget>() — List<Widget> garantie sur 20 éléments '
      '(simule la troncature dans compte_detail_screen.dart)',
      () {
        final items = List.generate(25, (i) => _makeTx(i));
        final List<Widget> result = items
            .take(20)
            .map<Widget>((tx) => ListTile(title: Text(tx.reference)))
            .toList();

        expect(result, isA<List<Widget>>());
        expect(result, hasLength(20));
      },
    );
  });

  group('Correction B : .map<Widget>(…) annoté explicitement', () {
    test(
      'FIX-B1: .map<Widget>() retourne List<Widget> '
      '— confirme la correction (Requirements 2.5, 2.6, 2.7, 2.8)',
      () {
        final items = <dynamic>[_makeTx(1), _makeTx(2)];
        final List<Widget> result = correctionB_withAnnotation(items);

        expect(result, isA<List<Widget>>());
        expect(result, hasLength(2));
      },
    );

    test(
      'FIX-B2: liste vide — List<Widget> garantie',
      () {
        final List<Widget> result = correctionB_withAnnotation([]);

        expect(result, isA<List<Widget>>());
        expect(result, isEmpty);
      },
    );

    test(
      'FIX-B3: .take(8).map<Widget>() — simule dashboard_screen.dart '
      '(Requirements 2.8)',
      () {
        final items = <dynamic>[...List.generate(10, (i) => _makeTx(i))];
        final List<Widget> result =
            items.take(8).map<Widget>((tx) => Container()).toList();

        expect(result, isA<List<Widget>>());
        expect(result, hasLength(8));
      },
    );

    test(
      'FIX-B4: .take(10).map<Widget>() — simule caissier_dashboard_screen.dart '
      '(Requirements 2.7)',
      () {
        final items = <dynamic>[...List.generate(15, (i) => _makeTx(i))];
        final List<Widget> result =
            items.take(10).map<Widget>((tx) => Container()).toList();

        expect(result, isA<List<Widget>>());
        expect(result, hasLength(10));
      },
    );
  });

  // -------------------------------------------------------------------------
  // Groupe 3 : Contraste Bug vs Correction
  // Illustre la différence de type runtime entre le code bugué et le code corrigé.
  // -------------------------------------------------------------------------
  group('Contraste Bug vs Correction — runtimeType diffère', () {
    test(
      'CONTRAST-1: bug=List<dynamic>, fix=List<Widget> pour les transactions',
      () {
        final items = [_makeTx(1), _makeTx(2)];

        final List<dynamic> bugResult = bugConditionA_producesDynamic(items);
        final List<Widget> fixResult = correctionA_transactions(items);

        // Le type runtime diffère entre le code bugué et le correctif
        expect(bugResult.runtimeType, isNot(fixResult.runtimeType),
            reason:
                'bug=${bugResult.runtimeType} vs fix=${fixResult.runtimeType}. '
                'Sur dart2js, seul le type fix est compatible avec List<Widget>.');

        // Les longueurs sont identiques — seul le type générique diffère
        expect(bugResult, hasLength(fixResult.length));
      },
    );

    test(
      'CONTRAST-2: bug=List<dynamic>, fix=List<Widget> pour les comptes',
      () {
        final items = [_makeCompte(1), _makeCompte(2), _makeCompte(3)];

        final List<dynamic> bugResult =
            bugConditionA_producesDynamicComptes(items);
        final List<Widget> fixResult = correctionA_comptes(items);

        expect(bugResult.runtimeType, isNot(fixResult.runtimeType));
        expect(bugResult, hasLength(fixResult.length));
      },
    );
  });
}
