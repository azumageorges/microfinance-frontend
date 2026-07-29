import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/api_client.dart';
import '../data/models/auth_model.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/client_repository.dart';
import '../data/repositories/compte_repository.dart';
import '../data/repositories/transaction_repository.dart';
import '../data/repositories/credit_repository.dart';
import '../data/repositories/dashboard_repository.dart';
import '../data/repositories/utilisateur_repository.dart';
import '../data/repositories/carte_repository.dart';
import '../data/repositories/fichier_repository.dart';
import '../data/repositories/beneficiaire_repository.dart';

// ─── Infrastructure ───────────────────────────────────────────────────────────

/// Client HTTP — le callback onUnauthorized est configuré par AuthNotifier
/// après sa création pour éviter la circularité de dépendances.
final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

// ─── Repositories ─────────────────────────────────────────────────────────────

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(apiClientProvider)),
);

final clientRepositoryProvider = Provider<ClientRepository>(
  (ref) => ClientRepository(ref.watch(apiClientProvider)),
);

final compteRepositoryProvider = Provider<CompteRepository>(
  (ref) => CompteRepository(ref.watch(apiClientProvider)),
);

final transactionRepositoryProvider = Provider<TransactionRepository>(
  (ref) => TransactionRepository(ref.watch(apiClientProvider)),
);

final creditRepositoryProvider = Provider<CreditRepository>(
  (ref) => CreditRepository(ref.watch(apiClientProvider)),
);

final dashboardRepositoryProvider = Provider<DashboardRepository>(
  (ref) => DashboardRepository(ref.watch(apiClientProvider)),
);

final utilisateurRepositoryProvider = Provider<UtilisateurRepository>(
  (ref) => UtilisateurRepository(ref.watch(apiClientProvider)),
);

final carteRepositoryProvider = Provider<CarteRepository>(
  (ref) => CarteRepository(ref.watch(apiClientProvider)),
);

final fichierRepositoryProvider = Provider<FichierRepository>(
  (ref) => FichierRepository(ref.watch(apiClientProvider)),
);

final beneficiaireRepositoryProvider = Provider<BeneficiaireRepository>(
  (ref) => BeneficiaireRepository(ref.watch(apiClientProvider)),
);

// ─── Auth State ───────────────────────────────────────────────────────────────

final sessionExpiredMessageProvider = StateProvider<String?>((ref) => null);

final authProvider = StateNotifierProvider<AuthNotifier, AuthResponse?>(
  (ref) {
    final notifier = AuthNotifier(
      ref.watch(authRepositoryProvider),
      ref,
    );
    // Injecter le callback d'expiration après la création pour éviter la circularité
    ref.watch(apiClientProvider).onUnauthorized = () => notifier.handleUnauthorized();
    return notifier;
  },
);

class AuthNotifier extends StateNotifier<AuthResponse?> {
  final AuthRepository _repo;
  final Ref _ref;

  AuthNotifier(this._repo, this._ref) : super(null) {
    _loadStoredUser();
  }

  Future<void> _loadStoredUser() async {
    state = await _repo.getStoredUser();
  }

  Future<void> login(String email, String password) async {
    _ref.read(sessionExpiredMessageProvider.notifier).state = null;
    state = await _repo.login(email, password);
  }

  Future<void> logout() async {
    await _repo.logout();
    state = null;
    _ref.read(sessionExpiredMessageProvider.notifier).state = null;
  }

  Future<void> handleUnauthorized() async {
    await _repo.clearLocalSession();
    state = null;
    _ref.read(sessionExpiredMessageProvider.notifier).state =
        'Votre session a expiré. Veuillez vous reconnecter.';
  }
}

// ─── Data Providers ───────────────────────────────────────────────────────────

final clientsProvider = FutureProvider((ref) {
  return ref.watch(clientRepositoryProvider).getClients();
});

final comptesProvider = FutureProvider((ref) {
  return ref.watch(compteRepositoryProvider).getComptes();
});

final transactionsProvider = FutureProvider((ref) {
  // Utilise l'endpoint /all pour charger toutes les transactions sans pagination
  // (nécessaire pour le dashboard caissier et les rapports qui filtrent côté client)
  return ref.watch(transactionRepositoryProvider).getAllTransactions();
});

final creditsProvider = FutureProvider((ref) {
  return ref.watch(creditRepositoryProvider).getCredits();
});

final dashboardProvider = FutureProvider((ref) {
  return ref.watch(dashboardRepositoryProvider).getDashboard();
});

final utilisateursProvider = FutureProvider((ref) {
  return ref.watch(utilisateurRepositoryProvider).getUtilisateurs();
});
