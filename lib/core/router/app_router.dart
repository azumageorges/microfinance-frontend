import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/providers.dart';

// ── Écrans communs ──────────────────────────────────────────────────────────
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/auth/acces_refuse_screen.dart';
import '../../presentation/screens/profil/profil_screen.dart';

// ── Écrans Web (Admin / Gestionnaire / Caissier) ────────────────────────────
import '../../presentation/screens/dashboard/dashboard_screen.dart';
import '../../presentation/screens/dashboard/caissier_dashboard_screen.dart';
import '../../presentation/screens/clients/clients_list_screen.dart';
import '../../presentation/screens/clients/client_detail_screen.dart';
import '../../presentation/screens/clients/client_form_screen.dart';
import '../../presentation/screens/comptes/comptes_list_screen.dart';
import '../../presentation/screens/comptes/compte_detail_screen.dart';
import '../../presentation/screens/comptes/compte_form_screen.dart';
import '../../presentation/screens/transactions/transactions_screen.dart';
import '../../presentation/screens/transactions/operation_screen.dart';
import '../../presentation/screens/credits/credits_list_screen.dart';
import '../../presentation/screens/credits/credit_detail_screen.dart';
import '../../presentation/screens/utilisateurs/utilisateurs_screen.dart';
import '../../presentation/screens/recherche/recherche_screen.dart';
import '../../presentation/screens/cartes/carte_membre_screen.dart';
import '../../presentation/screens/cartes/cartes_list_screen.dart';
import '../../presentation/screens/rapports/rapport_screen.dart';

// ── Écrans Mobile (Agent Terrain) ───────────────────────────────────────────
import '../../presentation/screens/terrain/terrain_clients_screen.dart';
import '../../presentation/screens/terrain/terrain_client_detail_screen.dart';
import '../../presentation/screens/terrain/terrain_profil_screen.dart';
import '../../presentation/screens/terrain/terrain_accueil_screen.dart';

// ── Layouts ─────────────────────────────────────────────────────────────────
import '../../presentation/layout/main_layout.dart';
import '../../presentation/layout/terrain_layout.dart';
import '../../presentation/widgets/loading_overlay.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoggedIn = auth != null;
      final location = state.matchedLocation;
      final isLoginRoute = location == '/login';
      final isAccesRefuse = location == '/acces-refuse';

      // Non connecté → login
      if (!isLoggedIn) {
        return (isLoginRoute || isAccesRefuse) ? null : '/login';
      }

      // Connecté → quitter le login
      if (isLoginRoute) return auth.homeRoute;

      // ── Vérification plateforme vs rôle ──────────────────────────────
      //
      // Web  → réservé à Admin / Gestionnaire / Caissier
      // Mobile → réservé à Agent terrain
      //
      if (kIsWeb && auth.isAgentTerrain) {
        // Agent terrain sur le web → accès refusé
        return isAccesRefuse ? null : '/acces-refuse';
      }
      if (!kIsWeb && auth.isWebUser) {
        // Admin/Gestionnaire/Caissier sur mobile → accès refusé
        return isAccesRefuse ? null : '/acces-refuse';
      }
      // ── Redirections par rôle sur les routes protégées ───────────────
      if (location.startsWith('/dashboard') && !auth.canAccessDashboard) {
        return auth.homeRoute;
      }
      if (location.startsWith('/caisse') && !auth.isCaissier && !auth.isAdmin) {
        return auth.homeRoute;
      }
      if (location.startsWith('/transactions') &&
          !auth.canAccessTransactions) {
        return auth.homeRoute;
      }
      if (location.startsWith('/utilisateurs') &&
          !auth.canAccessUtilisateurs) {
        return auth.homeRoute;
      }
      if (location.startsWith('/cartes') && !auth.canAccessDashboard) {
        return auth.homeRoute;
      }

      return null;
    },

    routes: [
      // ── Login (commun) ────────────────────────────────────────────────
      GoRoute(
        path: '/login',
        builder: (ctx, state) => const LoginScreen(),
      ),

      // ── Accès refusé (commun) ─────────────────────────────────────────
      GoRoute(
        path: '/acces-refuse',
        builder: (ctx, state) => AccesRefuseScreen(
          webUserOnMobile: !kIsWeb,
        ),
      ),

      // ════════════════════════════════════════════════════════════════
      // INTERFACE WEB — Admin / Gestionnaire / Caissier
      // ════════════════════════════════════════════════════════════════
      ShellRoute(
        builder: (ctx, state, child) => MainLayout(child: child),
        routes: [
          // Dashboard (Admin + Gestionnaire)
          GoRoute(
            path: '/dashboard',
            builder: (ctx, state) => const DashboardScreen(),
          ),

          // Dashboard Caissier
          GoRoute(
            path: '/caisse',
            builder: (ctx, state) => const CaissierDashboardScreen(),
          ),

          // Clients
          GoRoute(
            path: '/clients',
            builder: (ctx, state) => const ClientsListScreen(),
            routes: [
              GoRoute(
                path: 'nouveau',
                builder: (ctx, state) => const ClientFormScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (ctx, state) => ClientDetailScreen(
                  clientId: int.parse(state.pathParameters['id']!),
                ),
                routes: [
                  GoRoute(
                    path: 'modifier',
                    builder: (ctx, state) => ClientFormScreen(
                      clientId:
                          int.parse(state.pathParameters['id']!),
                    ),
                  ),
                  GoRoute(
                    path: 'carte',
                    builder: (ctx, state) {
                      final id = int.parse(state.pathParameters['id']!);
                      final client = state.extra;
                      // Si extra est null (navigation directe par URL),
                      // on affiche un écran de chargement qui charge le client
                      if (client == null) {
                        return _CarteByClientId(clientId: id);
                      }
                      return CarteMembre(
                        clientId: id,
                        client: client as dynamic,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),

          // Comptes
          GoRoute(
            path: '/comptes',
            builder: (ctx, state) => const ComptesListScreen(),
            routes: [
              GoRoute(
                path: 'nouveau',
                builder: (ctx, state) {
                  final clientId =
                      state.uri.queryParameters['clientId'];
                  return CompteFormScreen(
                    clientId: clientId != null
                        ? int.tryParse(clientId)
                        : null,
                  );
                },
              ),
              GoRoute(
                path: ':numero',
                builder: (ctx, state) => CompteDetailScreen(
                  numeroCompte: state.pathParameters['numero']!,
                ),
              ),
            ],
          ),

          // Transactions (Admin + Gestionnaire + Caissier)
          GoRoute(
            path: '/transactions',
            builder: (ctx, state) => const TransactionsScreen(),
            routes: [
              GoRoute(
                path: 'depot',
                builder: (ctx, state) =>
                    const OperationScreen(type: 'depot'),
              ),
              GoRoute(
                path: 'retrait',
                builder: (ctx, state) =>
                    const OperationScreen(type: 'retrait'),
              ),
              GoRoute(
                path: 'transfert',
                builder: (ctx, state) =>
                    const OperationScreen(type: 'transfert'),
              ),
            ],
          ),

          // Crédits
          GoRoute(
            path: '/credits',
            builder: (ctx, state) => const CreditsListScreen(),
            routes: [
              GoRoute(
                path: ':reference',
                builder: (ctx, state) => CreditDetailScreen(
                  reference: state.pathParameters['reference']!,
                ),
              ),
            ],
          ),

          // Utilisateurs (Admin seulement)
          GoRoute(
            path: '/utilisateurs',
            builder: (ctx, state) => const UtilisateursScreen(),
          ),

          // Cartes membres (Admin + Gestionnaire)
          GoRoute(
            path: '/cartes',
            builder: (ctx, state) => const CartesListScreen(),
          ),

          // Profil
          GoRoute(
            path: '/profil',
            builder: (ctx, state) => const ProfilScreen(),
          ),

          // Recherche globale
          GoRoute(
            path: '/recherche',
            builder: (ctx, state) => const RechercheScreen(),
          ),

          // Rapport d'activité (Admin + Gestionnaire)
          GoRoute(
            path: '/rapports',
            builder: (ctx, state) => const RapportScreen(),
          ),
        ],
      ),

      // ════════════════════════════════════════════════════════════════
      // INTERFACE MOBILE — Agent Terrain
      // ════════════════════════════════════════════════════════════════
      ShellRoute(
        builder: (ctx, state, child) => TerrainLayout(child: child),
        routes: [
          // Accueil terrain
          GoRoute(
            path: '/terrain',
            builder: (ctx, state) => const TerrainAccueilScreen(),
          ),
          GoRoute(
            path: '/terrain/clients',
            builder: (ctx, state) => const TerrainClientsScreen(),
          ),
          GoRoute(
            path: '/terrain/clients/nouveau',
            builder: (ctx, state) => const ClientFormScreen(),
          ),
          GoRoute(
            path: '/terrain/clients/:id',
            builder: (ctx, state) => TerrainClientDetailScreen(
              clientId:
                  int.parse(state.pathParameters['id']!),
            ),
            routes: [
              GoRoute(
                path: 'modifier',
                builder: (ctx, state) => ClientFormScreen(
                  clientId:
                      int.parse(state.pathParameters['id']!),
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/terrain/profil',
            builder: (ctx, state) => const TerrainProfilScreen(),
          ),
        ],
      ),
    ],
  );
});

// ─── Widget helper : charge un client par ID puis affiche sa carte ────────────
// Utilisé quand on navigue vers /clients/:id/carte sans passer extra

class _CarteByClientId extends ConsumerWidget {
  final int clientId;
  const _CarteByClientId({required this.clientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientAsync = ref.watch(
      FutureProvider.family<dynamic, int>(
        (r, id) => r.watch(clientRepositoryProvider).getClientById(id),
      )(clientId),
    );
    return clientAsync.when(
      loading: () => const Scaffold(body: LoadingOverlay()),
      error: (e, _) =>
          Scaffold(body: Center(child: Text('Erreur : $e'))),
      data: (client) => CarteMembre(clientId: clientId, client: client),
    );
  }
}
