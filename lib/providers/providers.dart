import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/api_client.dart';
import '../core/network/connectivity_service.dart';
import '../core/sync/sync_service.dart';
import '../data/local/app_database.dart';
import '../data/local/client_local_store.dart';
import '../data/local/compte_local_store.dart';
import '../data/local/credit_local_store.dart';
import '../data/local/sync_queue_store.dart';
import '../data/local/transaction_local_store.dart';
import '../data/models/auth_model.dart';
import '../data/models/client_model.dart';
import '../data/models/compte_model.dart';
import '../data/models/credit_model.dart';
import '../data/models/dashboard_model.dart';
import '../data/models/transaction_model.dart';
import '../data/models/utilisateur_model.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/beneficiaire_repository.dart';
import '../data/repositories/carte_repository.dart';
import '../data/repositories/client_repository.dart';
import '../data/repositories/compte_repository.dart';
import '../data/repositories/credit_repository.dart';
import '../data/repositories/dashboard_repository.dart';
import '../data/repositories/fichier_repository.dart';
import '../data/repositories/transaction_repository.dart';
import '../data/repositories/utilisateur_repository.dart';

// ─── Infrastructure ───────────────────────────────────────────────────────────

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError('AppDatabase must be overridden in main.dart');
});

final connectivityServiceProvider = Provider<ConnectivityService>(
  (ref) => ConnectivityService(),
);

/// Client HTTP — le callback onUnauthorized est configuré par AuthNotifier
/// après sa création pour éviter la circularité de dépendances.
final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

// ─── Local stores ─────────────────────────────────────────────────────────────

final clientLocalStoreProvider = Provider<ClientLocalStore>(
  (ref) => ClientLocalStore(ref.watch(appDatabaseProvider)),
);

final compteLocalStoreProvider = Provider<CompteLocalStore>(
  (ref) => CompteLocalStore(ref.watch(appDatabaseProvider)),
);

final transactionLocalStoreProvider = Provider<TransactionLocalStore>(
  (ref) => TransactionLocalStore(ref.watch(appDatabaseProvider)),
);

final creditLocalStoreProvider = Provider<CreditLocalStore>(
  (ref) => CreditLocalStore(ref.watch(appDatabaseProvider)),
);

final syncQueueStoreProvider = Provider<SyncQueueStore>(
  (ref) => SyncQueueStore(ref.watch(appDatabaseProvider)),
);

final Provider<SyncService> syncServiceProvider = Provider<SyncService>((ref) {
  final service = SyncService(
    apiClient: ref.watch(apiClientProvider),
    clientStore: ref.watch(clientLocalStoreProvider),
    compteStore: ref.watch(compteLocalStoreProvider),
    transactionStore: ref.watch(transactionLocalStoreProvider),
    creditStore: ref.watch(creditLocalStoreProvider),
    syncQueue: ref.watch(syncQueueStoreProvider),
    connectivity: ref.watch(connectivityServiceProvider),
    onSyncCompleted: () {
      ref.invalidate(clientsProvider);
      ref.invalidate(comptesProvider);
      ref.invalidate(transactionsProvider);
      ref.invalidate(creditsProvider);
      ref.invalidate(pendingSyncCountProvider);
    },
  );
  ref.onDispose(service.dispose);
  return service;
});

// ─── Repositories ─────────────────────────────────────────────────────────────

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(apiClientProvider)),
);

final Provider<ClientRepository> clientRepositoryProvider = Provider<ClientRepository>(
  (ref) => ClientRepository(
    ref.watch(apiClientProvider),
    localStore: ref.watch(clientLocalStoreProvider),
    syncQueue: ref.watch(syncQueueStoreProvider),
    connectivity: ref.watch(connectivityServiceProvider),
    syncService: ref.watch(syncServiceProvider),
  ),
);

final compteRepositoryProvider = Provider<CompteRepository>(
  (ref) => CompteRepository(
    ref.watch(apiClientProvider),
    localStore: ref.watch(compteLocalStoreProvider),
    connectivity: ref.watch(connectivityServiceProvider),
  ),
);

final transactionRepositoryProvider = Provider<TransactionRepository>(
  (ref) => TransactionRepository(
    ref.watch(apiClientProvider),
    localStore: ref.watch(transactionLocalStoreProvider),
    compteStore: ref.watch(compteLocalStoreProvider),
    syncQueue: ref.watch(syncQueueStoreProvider),
    connectivity: ref.watch(connectivityServiceProvider),
  ),
);

final creditRepositoryProvider = Provider<CreditRepository>(
  (ref) => CreditRepository(
    ref.watch(apiClientProvider),
    localStore: ref.watch(creditLocalStoreProvider),
    connectivity: ref.watch(connectivityServiceProvider),
  ),
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

// ─── Connectivity & Sync State ────────────────────────────────────────────────

final isOnlineProvider = StreamProvider<bool>((ref) {
  return ref.watch(connectivityServiceProvider).onConnectivityChanged();
});

final pendingSyncCountProvider = FutureProvider<int>((ref) async {
  final queueCount = await ref.watch(syncQueueStoreProvider).count();
  final pendingClients = await ref.watch(clientLocalStoreProvider).countPending();
  final pendingTxs = await ref.watch(transactionLocalStoreProvider).countPending();
  final pendingTotal = pendingClients + pendingTxs;
  return queueCount > 0 ? queueCount : pendingTotal;
});

// ─── Data Providers ───────────────────────────────────────────────────────────

final FutureProvider<List<ClientModel>> clientsProvider = FutureProvider<List<ClientModel>>((ref) {
  return ref.watch(clientRepositoryProvider).getClients();
});

final comptesProvider = FutureProvider<List<CompteModel>>((ref) {
  return ref.watch(compteRepositoryProvider).getComptes();
});

final transactionsProvider = FutureProvider<List<TransactionModel>>((ref) {
  return ref.watch(transactionRepositoryProvider).getAllTransactions();
});

final creditsProvider = FutureProvider<List<CreditModel>>((ref) {
  return ref.watch(creditRepositoryProvider).getCredits();
});

final dashboardProvider = FutureProvider<DashboardModel>((ref) {
  return ref.watch(dashboardRepositoryProvider).getDashboard();
});

final utilisateursProvider = FutureProvider<List<UtilisateurModel>>((ref) {
  return ref.watch(utilisateurRepositoryProvider).getUtilisateurs();
});

