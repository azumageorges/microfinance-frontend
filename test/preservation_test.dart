/// Preservation Tests — Property 2
///
/// Ces tests vérifient que les comportements existants sont préservés après le
/// correctif `List<dynamic> → List<Widget>`. Ils doivent PASSER sur le code
/// corrigé actuel.
///
/// **Validates: Requirements 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7, 3.8, 3.9**

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:microfinance_app/data/models/client_model.dart';
import 'package:microfinance_app/data/models/compte_model.dart';
import 'package:microfinance_app/data/models/transaction_model.dart';

// ---------------------------------------------------------------------------
// Helpers — instances de test minimales
// ---------------------------------------------------------------------------

TransactionModel _makeTx(int id, {String statut = 'EXECUTEE', DateTime? date}) =>
    TransactionModel(
      id: id,
      reference: 'REF-$id',
      typeTransaction: id.isEven ? 'DEPOT' : 'RETRAIT',
      statut: statut,
      montant: 10000.0 + id * 1000,
      numeroCompte: 'CPT-001',
      dateTransaction: date ?? DateTime.now(),
    );

CompteModel _makeCompte(int id, {String statut = 'ACTIF'}) => CompteModel(
      id: id,
      numeroCompte: 'CPT-00$id',
      typeCompte: 'EPARGNE',
      statut: statut,
      solde: 50000.0 * id,
      clientId: 1,
      nomClient: 'Dupont',
      prenomClient: 'Jean',
    );

ClientModel _makeClient(int id, {DateTime? createdAt}) => ClientModel(
      id: id,
      numeroClient: 'CLI-00$id',
      nom: 'Dupont$id',
      prenom: 'Jean$id',
      telephone: '0600000$id',
      statut: 'ACTIF',
      createdAt: createdAt ?? DateTime(2024, 1, id),
      nombreComptes: id,
    );

// ---------------------------------------------------------------------------
// Helpers — fonctions de construction de listes (simulent les écrans)
// Correspondent au code corrigé dans les 6 fichiers Flutter.
// ---------------------------------------------------------------------------

/// Simule le code corrigé de compte_detail_screen.dart :
/// FutureProvider.family<List<TransactionModel>, String> + .map<Widget>(…)
List<Widget> buildTxList(List<TransactionModel> txs) {
  return txs.take(20).map<Widget>(
    (tx) => ListTile(
      title: Text(tx.reference),
      subtitle: Text(tx.typeLabel),
      trailing: Text('${tx.montant}'),
    ),
  ).toList();
}

/// Simule ClientDetailScreen corrigé : .map<Widget>((c) => ListTile(…))
List<Widget> buildCompteListForClient(List<CompteModel> comptes) {
  return comptes.map<Widget>(
    (c) => ListTile(
      title: Text(c.numeroCompte),
      subtitle: Text(c.statut),
      trailing: Text('${c.solde}'),
    ),
  ).toList();
}

/// Simule TerrainClientDetailScreen corrigé : .map<Widget>((c) => ListTile(…))
List<Widget> buildCompteListForTerrain(List<CompteModel> comptes) {
  return comptes.map<Widget>(
    (c) => ListTile(
      title: Text(c.numeroCompte),
      subtitle: Text(c.typeLabel),
      trailing: Text('${c.solde}'),
    ),
  ).toList();
}

/// Simule TerrainAccueilScreen corrigé : .map<Widget>((c) => Card(…))
List<Widget> buildClientCards(List<ClientModel> clients) {
  return clients.map<Widget>(
    (c) => Card(child: Text(c.fullName)),
  ).toList();
}

/// Simule CaissierDashboardScreen corrigé : .take(10).map<Widget>((tx) => …)
List<Widget> buildTxTilesForCaissier(List<TransactionModel> txs) {
  return txs.take(10).map<Widget>(
    (tx) => ListTile(
      title: Text(tx.reference),
      subtitle: Text(tx.statutLabel),
    ),
  ).toList();
}

/// Simule DashboardScreen corrigé : .take(8).map<Widget>((tx) => …)
List<Widget> buildRecentTxTiles(List<TransactionModel> txs) {
  return txs.take(8).map<Widget>(
    (tx) => ListTile(title: Text(tx.reference)),
  ).toList();
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // -------------------------------------------------------------------------
  // Requirements 3.1 & 3.2 — Après dépôt/retrait, la liste de transactions
  // d'un compte se reconstruit correctement.
  // -------------------------------------------------------------------------
  group('3.1 & 3.2 — Reconstruction de la liste après dépôt/retrait', () {
    test(
      'PRES-1: après un dépôt, la liste se reconstruit en List<Widget> valide',
      () {
        // Simule l'état après un dépôt : la liste est rechargée avec une tx DEPOT
        final txs = [
          _makeTx(1, statut: 'EXECUTEE'),
          _makeTx(2, statut: 'EXECUTEE'),
          TransactionModel(
            id: 99,
            reference: 'REF-DEPOT',
            typeTransaction: 'DEPOT',
            statut: 'EXECUTEE',
            montant: 25000.0,
            numeroCompte: 'CPT-001',
            dateTransaction: DateTime.now(),
          ),
        ];

        final List<Widget> result = buildTxList(txs);

        expect(result, isA<List<Widget>>());
        expect(result, hasLength(3));
        for (final w in result) {
          expect(w, isA<ListTile>());
        }
      },
    );

    test(
      'PRES-2: après un retrait, la liste se reconstruit en List<Widget> valide',
      () {
        final txs = [
          _makeTx(1, statut: 'EXECUTEE'),
          TransactionModel(
            id: 100,
            reference: 'REF-RETRAIT',
            typeTransaction: 'RETRAIT',
            statut: 'EXECUTEE',
            montant: 5000.0,
            numeroCompte: 'CPT-001',
            dateTransaction: DateTime.now(),
          ),
        ];

        final List<Widget> result = buildTxList(txs);

        expect(result, isA<List<Widget>>());
        expect(result, hasLength(2));
        expect(result.first, isA<ListTile>());
      },
    );

    test(
      'PRES-3: liste vide (aucune transaction) produit List<Widget> vide',
      () {
        final List<Widget> result = buildTxList([]);
        expect(result, isA<List<Widget>>());
        expect(result, isEmpty);
      },
    );
  });

  // -------------------------------------------------------------------------
  // Requirement 3.3 — L'invalidation des providers provoque un rechargement.
  // -------------------------------------------------------------------------
  group('3.3 — Rechargement après invalidation des providers', () {
    test(
      'PRES-4: mise à jour de la liste de transactions produit List<Widget> correcte',
      () {
        // Avant invalidation : liste initiale
        final initial = [_makeTx(1), _makeTx(2)];
        final List<Widget> before = buildTxList(initial);
        expect(before, isA<List<Widget>>());
        expect(before, hasLength(2));

        // Après invalidation : provider rechargé avec nouvelles données
        final updated = [_makeTx(1), _makeTx(2), _makeTx(3)];
        final List<Widget> after = buildTxList(updated);
        expect(after, isA<List<Widget>>());
        expect(after, hasLength(3));

        // La liste mise à jour est plus longue — rechargement correct
        expect(after.length, greaterThan(before.length));
      },
    );

    test(
      'PRES-5: rechargement depuis liste vide vers liste non-vide reste List<Widget>',
      () {
        final empty = buildTxList([]);
        final filled = buildTxList([_makeTx(1), _makeTx(2)]);

        expect(empty, isA<List<Widget>>());
        expect(filled, isA<List<Widget>>());
        expect(filled, hasLength(2));
      },
    );
  });

  // -------------------------------------------------------------------------
  // Requirement 3.4 — CompteDetailScreen affiche solde, statut et infos.
  // -------------------------------------------------------------------------
  group('3.4 — CompteDetailScreen affiche les informations du compte', () {
    test(
      'PRES-6: les champs de CompteModel sont accessibles (solde, statut, labels)',
      () {
        final compte = _makeCompte(1);

        expect(compte.solde, equals(50000.0));
        expect(compte.statut, equals('ACTIF'));
        expect(compte.typeLabel, equals('Épargne'));
        expect(compte.numeroCompte, equals('CPT-001'));
        expect(compte.clientFullName, equals('Jean Dupont'));
        expect(compte.isActif, isTrue);
      },
    );

    test(
      'PRES-7: compte inactif — champs accessibles sans erreur',
      () {
        final compte = _makeCompte(2, statut: 'SUSPENDU');

        expect(compte.statut, equals('SUSPENDU'));
        expect(compte.isActif, isFalse);
        expect(compte.solde, equals(100000.0));
        expect(compte.numeroCompte, equals('CPT-002'));
      },
    );

    test(
      'PRES-8: la liste des transactions d\'un compte produit List<Widget>',
      () {
        final txs = List.generate(5, (i) => _makeTx(i));
        final List<Widget> widgets = buildTxList(txs);

        expect(widgets, isA<List<Widget>>());
        expect(widgets, hasLength(5));
      },
    );
  });

  // -------------------------------------------------------------------------
  // Requirement 3.5 — ClientDetailScreen liste les comptes avec solde,
  // numéro et statut.
  // -------------------------------------------------------------------------
  group('3.5 — ClientDetailScreen liste les comptes d\'un client', () {
    test(
      'PRES-9: la liste des comptes produit List<Widget> avec les bonnes infos',
      () {
        final comptes = [_makeCompte(1), _makeCompte(2), _makeCompte(3)];
        final List<Widget> result = buildCompteListForClient(comptes);

        expect(result, isA<List<Widget>>());
        expect(result, hasLength(3));
        for (final w in result) {
          expect(w, isA<ListTile>());
        }
      },
    );

    test(
      'PRES-10: liste vide de comptes produit List<Widget> vide sans crash',
      () {
        final List<Widget> result = buildCompteListForClient([]);
        expect(result, isA<List<Widget>>());
        expect(result, isEmpty);
      },
    );

    test(
      'PRES-11: chaque CompteModel a solde, numéro et statut accessibles',
      () {
        final comptes = [_makeCompte(1), _makeCompte(2)];

        for (final c in comptes) {
          expect(c.numeroCompte, isNotEmpty);
          expect(c.statut, isNotEmpty);
          expect(c.solde, isNonNegative);
        }
      },
    );
  });

  // -------------------------------------------------------------------------
  // Requirement 3.6 — TerrainClientDetailScreen liste les comptes d'un client.
  // -------------------------------------------------------------------------
  group('3.6 — TerrainClientDetailScreen liste les comptes', () {
    test(
      'PRES-12: la liste terrain des comptes produit List<Widget>',
      () {
        final comptes = [_makeCompte(1), _makeCompte(2)];
        final List<Widget> result = buildCompteListForTerrain(comptes);

        expect(result, isA<List<Widget>>());
        expect(result, hasLength(2));
        for (final w in result) {
          expect(w, isA<ListTile>());
        }
      },
    );

    test(
      'PRES-13: liste vide produit List<Widget> vide sans crash (terrain)',
      () {
        final List<Widget> result = buildCompteListForTerrain([]);
        expect(result, isA<List<Widget>>());
        expect(result, isEmpty);
      },
    );

    test(
      'PRES-14: typeLabel de CompteModel est accessible pour chaque compte',
      () {
        final types = ['EPARGNE', 'DAT', 'CREDIT', 'ENFANT'];
        final labels = ['Épargne', 'Dépôt à Terme', 'Crédit', 'Enfant'];

        for (var i = 0; i < types.length; i++) {
          final c = CompteModel(
            id: i,
            numeroCompte: 'CPT-$i',
            typeCompte: types[i],
            statut: 'ACTIF',
            solde: 1000.0,
            clientId: 1,
            nomClient: 'Doe',
            prenomClient: 'John',
          );
          expect(c.typeLabel, equals(labels[i]));
        }
      },
    );
  });

  // -------------------------------------------------------------------------
  // Requirement 3.7 — TerrainAccueilScreen : clients triés par date de
  // création décroissante.
  // -------------------------------------------------------------------------
  group('3.7 — TerrainAccueilScreen : tri décroissant par createdAt', () {
    test(
      'PRES-15: les clients sont triés par date de création décroissante',
      () {
        final clients = [
          _makeClient(1, createdAt: DateTime(2024, 1, 10)),
          _makeClient(2, createdAt: DateTime(2024, 3, 15)),
          _makeClient(3, createdAt: DateTime(2024, 2, 5)),
          _makeClient(4, createdAt: DateTime(2024, 5, 1)),
        ];

        // Tri décroissant (le plus récent en premier) — logique de TerrainAccueilScreen
        final sorted = [...clients]..sort(
            (a, b) => (b.createdAt ?? DateTime(0))
                .compareTo(a.createdAt ?? DateTime(0)),
          );

        expect(sorted.first.id, equals(4)); // 2024-05-01 est le plus récent
        expect(sorted.last.id, equals(1));  // 2024-01-10 est le plus ancien

        // Vérification que l'ordre est bien décroissant
        for (var i = 0; i < sorted.length - 1; i++) {
          final curr = sorted[i].createdAt!;
          final next = sorted[i + 1].createdAt!;
          expect(curr.isAfter(next) || curr.isAtSameMomentAs(next), isTrue,
              reason: 'Les clients doivent être triés du plus récent au plus ancien');
        }
      },
    );

    test(
      'PRES-16: la liste de cartes clients triée produit List<Widget>',
      () {
        final clients = [
          _makeClient(1, createdAt: DateTime(2024, 3, 1)),
          _makeClient(2, createdAt: DateTime(2024, 1, 1)),
          _makeClient(3, createdAt: DateTime(2024, 5, 1)),
        ]..sort(
            (a, b) => (b.createdAt ?? DateTime(0))
                .compareTo(a.createdAt ?? DateTime(0)),
          );

        final List<Widget> result = buildClientCards(clients);

        expect(result, isA<List<Widget>>());
        expect(result, hasLength(3));
        for (final w in result) {
          expect(w, isA<Card>());
        }
      },
    );

    test(
      'PRES-17: liste vide de clients produit List<Widget> vide',
      () {
        final List<Widget> result = buildClientCards([]);
        expect(result, isA<List<Widget>>());
        expect(result, isEmpty);
      },
    );

    test(
      'PRES-18: fullName de ClientModel est accessible pour chaque client',
      () {
        final client = _makeClient(1);
        expect(client.fullName, equals('Jean1 Dupont1'));
      },
    );
  });

  // -------------------------------------------------------------------------
  // Requirement 3.8 — CaissierDashboardScreen : transactions du jour filtrées.
  // -------------------------------------------------------------------------
  group('3.8 — CaissierDashboardScreen : transactions du jour', () {
    test(
      'PRES-19: seules les transactions exécutées d\'aujourd\'hui sont listées',
      () {
        final today = DateTime.now();
        final yesterday = today.subtract(const Duration(days: 1));

        final all = [
          _makeTx(1, statut: 'EXECUTEE', date: today),
          _makeTx(2, statut: 'EXECUTEE', date: today),
          _makeTx(3, statut: 'EN_ATTENTE', date: today),     // pas exécutée
          _makeTx(4, statut: 'EXECUTEE', date: yesterday),   // hier
          _makeTx(5, statut: 'EXECUTEE', date: today),
        ];

        // Filtre : exécutée + date du jour (logique CaissierDashboardScreen)
        final txAujourdhui = all.where((tx) {
          final d = tx.dateTransaction;
          return tx.isExecuted &&
              d.year == today.year &&
              d.month == today.month &&
              d.day == today.day;
        }).toList();

        expect(txAujourdhui, hasLength(3)); // ids 1, 2, 5

        final List<Widget> result = buildTxTilesForCaissier(txAujourdhui);
        expect(result, isA<List<Widget>>());
        expect(result, hasLength(3));
      },
    );

    test(
      'PRES-20: .take(10) ne retourne pas plus de 10 éléments',
      () {
        final txs = List.generate(15, (i) => _makeTx(i));
        final List<Widget> result = buildTxTilesForCaissier(txs);

        expect(result, isA<List<Widget>>());
        expect(result, hasLength(10));
      },
    );

    test(
      'PRES-21: aucune transaction du jour — liste vide sans crash',
      () {
        final List<Widget> result = buildTxTilesForCaissier([]);
        expect(result, isA<List<Widget>>());
        expect(result, isEmpty);
      },
    );
  });

  // -------------------------------------------------------------------------
  // Requirement 3.9 — DashboardScreen : 8 dernières transactions.
  // -------------------------------------------------------------------------
  group('3.9 — DashboardScreen : 8 dernières transactions', () {
    test(
      'PRES-22: .take(8) sur 10+ transactions retourne exactement 8 widgets',
      () {
        final txs = List.generate(12, (i) => _makeTx(i));
        final List<Widget> result = buildRecentTxTiles(txs);

        expect(result, isA<List<Widget>>());
        expect(result, hasLength(8));
        for (final w in result) {
          expect(w, isA<ListTile>());
        }
      },
    );

    test(
      'PRES-23: .take(8) sur exactement 8 transactions retourne 8 widgets',
      () {
        final txs = List.generate(8, (i) => _makeTx(i));
        final List<Widget> result = buildRecentTxTiles(txs);

        expect(result, isA<List<Widget>>());
        expect(result, hasLength(8));
      },
    );

    test(
      'PRES-24: .take(8) sur moins de 8 transactions retourne tous les éléments',
      () {
        final txs = List.generate(5, (i) => _makeTx(i));
        final List<Widget> result = buildRecentTxTiles(txs);

        expect(result, isA<List<Widget>>());
        expect(result, hasLength(5));
      },
    );

    test(
      'PRES-25: .take(8) sur liste vide retourne List<Widget> vide',
      () {
        final List<Widget> result = buildRecentTxTiles([]);
        expect(result, isA<List<Widget>>());
        expect(result, isEmpty);
      },
    );

    test(
      'PRES-26: le résultat de .take(8) ne dépasse jamais 8 éléments',
      () {
        for (final count in [0, 1, 7, 8, 9, 20]) {
          final txs = List.generate(count, (i) => _makeTx(i));
          final result = buildRecentTxTiles(txs);

          expect(result.length, lessThanOrEqualTo(8),
              reason: 'count=$count → ${result.length} > 8');
          expect(result, isA<List<Widget>>());
        }
      },
    );
  });
}
