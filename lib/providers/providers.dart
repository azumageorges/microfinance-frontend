import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/api_client.dart';
import '../core/network/connectivity_service.dart';
import '../core/sync/sync_service.dart';
import '../core/websocket/websocket_service.dart';
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
import '../data/repositories/client_repository_interface.dart';
import '../data/repositories/client_repository_web.dart';
import '../data/repositories/compte_repository.dart';
import '../data/repositories/compte_repository_interface.dart';
import '../data/repositories/compte_repository_web.dart';
import '../data/repositories/credit_repository.dart';
import '../data/repositories/credit_repository_interface.dart';
import '../data/repositories/credit_repository_web.dart';
import '../data/repositories/dashboard_repository.dart';
import '../data/repositories/fichier_repository.dart';
import '../data/repositories/report_repository_interface.dart';
import '../data/repositories/report_repository_web.dart';
import '../data/repositories/transaction_repository.dart';
import '../data/repositories/transaction_repository_interface.dart';
import '../data/repositories/transaction_repository_web.dart';
import '../data/repositories/utilisateur_repository.dart';

// ─── Infrastructure ───────────────────────────────────────────────────────────

final webSocketServiceProvider = Provider<WebSocketService>((ref) {
  final service = WebSocketService();
  ref.onDispose(service.dispose);
  return service;
});

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError('AppDatabase must be overridden in main.dart');
});

final connectivityServiceProvider = Provider<ConnectivityService>(
  (ref) => ConnectivityService(),
);

/// Client HTTP — le callback onUnauthorized est configuré par AuthNotifier
/// après sa création pour éviter la circularité de dépendances.
final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

// ─── Local stores (uniquement pour mobile) ─────────────────────────────────────

final clientLocalStoreProvider = Provider<ClientLocalStore>((ref) {
  if (kIsWeb) {
    throw UnimplementedError('clientLocalStoreProvider should not be used on web');
  }
  return ClientLocalStore(ref.watch(appDatabaseProvider));
});

final compteLocalStoreProvider = Provider<CompteLocalStore>((ref) {
  if (kIsWeb) {
    throw UnimplementedError('compteLocalStoreProvider should not be used on web');
  }
  return CompteLocalStore(ref.watch(appDatabaseProvider));
});

final transactionLocalStoreProvider = Provider<TransactionLocalStore>((ref) {
  if (kIsWeb) {
    throw UnimplementedError('transactionLocalStoreProvider should not be used on web');
  }
  return TransactionLocalStore(ref.watch(appDatabaseProvider));
});

final creditLocalStoreProvider = Provider<CreditLocalStore>((ref) {
  if (kIsWeb) {
    throw UnimplementedError('creditLocalStoreProvider should not be used on web');
  }
  return CreditLocalStore(ref.watch(appDatabaseProvider));
});

final syncQueueStoreProvider = Provider<SyncQueueStore>((ref) {
  if (kIsWeb) {
    throw UnimplementedError('syncQueueStoreProvider should not be used on web');
  }
  return SyncQueueStore(ref.watch(appDatabaseProvider));
});

final syncServiceProvider = Provider<SyncService>((ref) {
  if (kIsWeb) {
    throw UnimplementedError('syncServiceProvider should not be used on web');
  }
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

// ─── Repositories (sélection conditionnelle Web/Mobile) ───────────────────────

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(apiClientProvider)),
);

/// Provider conditionnel pour ClientRepository
/// Web → ClientRepositoryWeb (API uniquement)
/// Mobile → ClientRepository (SQLite + sync)
final clientRepositoryProvider = Provider<IClientRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  if (kIsWeb) {
    return ClientRepositoryWeb(apiClient);
  } else {
    return ClientRepository(
      apiClient,
      localStore: ref.watch(clientLocalStoreProvider),
      syncQueue: ref.watch(syncQueueStoreProvider),
      connectivity: ref.watch(connectivityServiceProvider),
    );
  }
});

/// Provider conditionnel pour CompteRepository
/// Web → CompteRepositoryWeb (API uniquement)
/// Mobile → CompteRepository (SQLite + sync)
final compteRepositoryProvider = Provider<ICompteRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  if (kIsWeb) {
    return CompteRepositoryWeb(apiClient);
  } else {
    return CompteRepository(
      apiClient,
      localStore: ref.watch(compteLocalStoreProvider),
      connectivity: ref.watch(connectivityServiceProvider),
    );
  }
});

/// Provider conditionnel pour TransactionRepository
/// Web → TransactionRepositoryWeb (API uniquement)
/// Mobile → TransactionRepository (SQLite + sync)
final transactionRepositoryProvider = Provider<ITransactionRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  if (kIsWeb) {
    return TransactionRepositoryWeb(apiClient);
  } else {
    return TransactionRepository(
      apiClient,
      localStore: ref.watch(transactionLocalStoreProvider),
      compteStore: ref.watch(compteLocalStoreProvider),
      syncQueue: ref.watch(syncQueueStoreProvider),
      connectivity: ref.watch(connectivityServiceProvider),
    );
  }
});

/// Provider conditionnel pour CreditRepository
/// Web → CreditRepositoryWeb (API uniquement)
/// Mobile → CreditRepository (SQLite + sync)
final creditRepositoryProvider = Provider<ICreditRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  if (kIsWeb) {
    return CreditRepositoryWeb(apiClient);
  } else {
    return CreditRepository(
      apiClient,
      localStore: ref.watch(creditLocalStoreProvider),
      connectivity: ref.watch(connectivityServiceProvider),
    );
  }
});

final dashboardRepositoryProvider = Provider<DashboardRepository>(
  (ref) => DashboardRepository(ref.watch(apiClientProvider)),
);

final reportRepositoryProvider = Provider<IReportRepository>((ref) {
  return ReportRepositoryWeb(ref.watch(apiClientProvider));
});

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
    if (state != null) {
      _connectWebSocket();
    }
  }

  Future<void> login(String email, String password) async {
    _ref.read(sessionExpiredMessageProvider.notifier).state = null;
    state = await _repo.login(email, password);
    if (state != null) {
      _connectWebSocket();
    }
  }

  Future<void> logout() async {
    _ref.read(webSocketServiceProvider).disconnect();
    await _repo.logout();
    state = null;
    _ref.read(sessionExpiredMessageProvider.notifier).state = null;
  }

  Future<void> handleUnauthorized() async {
    _ref.read(webSocketServiceProvider).disconnect();
    await _repo.clearLocalSession();
    state = null;
    _ref.read(sessionExpiredMessageProvider.notifier).state =
        'Votre session a expiré. Veuillez vous reconnecter.';
  }

  void _connectWebSocket() {
    final wsService = _ref.read(webSocketServiceProvider);
    final apiClient = _ref.read(apiClientProvider);
    final token = state?.token;
    final baseUrl = apiClient.dio.options.baseUrl;

    if (token != null && baseUrl.isNotEmpty) {
      wsService.connect(baseUrl, token);
    }
  }
}

// ─── Connectivity & Sync State ────────────────────────────────────────────────

final isOnlineProvider = StreamProvider<bool>((ref) {
  return ref.watch(connectivityServiceProvider).onConnectivityChanged();
});

/// Provider pour le compteur de synchronisation en attente
/// Web → toujours 0 (pas de sync offline)
/// Mobile → compte réel des opérations en attente
final pendingSyncCountProvider = FutureProvider<int>((ref) async {
  if (kIsWeb) return 0;

  final syncQueue = ref.watch(syncQueueStoreProvider);
  final clientStore = ref.watch(clientLocalStoreProvider);
  final transactionStore = ref.watch(transactionLocalStoreProvider);

  final queueCount = await syncQueue.count();
  final pendingClients = await clientStore.countPending();
  final pendingTxs = await transactionStore.countPending();
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

