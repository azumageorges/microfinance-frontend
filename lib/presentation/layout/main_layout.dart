import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/auth_model.dart';
import '../../providers/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/layout/scaffold_keys.dart';

class MainLayout extends ConsumerWidget {
  final Widget child;

  const MainLayout({super.key, required this.child});

  static const _allNavItems = [
    _NavItem(
        icon: Icons.dashboard_outlined,
        activeIcon: Icons.dashboard,
        label: 'Tableau de bord',
        path: '/dashboard',
        roles: ['ADMIN', 'GESTIONNAIRE_COMPTE']),
    _NavItem(
        icon: Icons.point_of_sale_outlined,
        activeIcon: Icons.point_of_sale,
        label: 'Ma caisse',
        path: '/caisse',
        roles: ['CAISSIER']),
    _NavItem(
        icon: Icons.people_outlined,
        activeIcon: Icons.people,
        label: 'Clients',
        path: '/clients',
        roles: ['ADMIN', 'GESTIONNAIRE_COMPTE']),
    _NavItem(
        icon: Icons.account_balance_wallet_outlined,
        activeIcon: Icons.account_balance_wallet,
        label: 'Comptes',
        path: '/comptes',
        roles: ['ADMIN', 'GESTIONNAIRE_COMPTE', 'CAISSIER']),
    _NavItem(
        icon: Icons.swap_horiz_outlined,
        activeIcon: Icons.swap_horiz,
        label: 'Transactions',
        path: '/transactions',
        roles: ['ADMIN', 'GESTIONNAIRE_COMPTE', 'CAISSIER']),
    _NavItem(
        icon: Icons.credit_score_outlined,
        activeIcon: Icons.credit_score,
        label: 'Crédits',
        path: '/credits',
        roles: ['ADMIN', 'GESTIONNAIRE_COMPTE', 'CAISSIER']),
    _NavItem(
        icon: Icons.badge_outlined,
        activeIcon: Icons.badge,
        label: 'Cartes',
        path: '/cartes',
        roles: ['ADMIN', 'GESTIONNAIRE_COMPTE']),
    _NavItem(
        icon: Icons.bar_chart_outlined,
        activeIcon: Icons.bar_chart,
        label: 'Rapports',
        path: '/rapports',
        roles: ['ADMIN', 'GESTIONNAIRE_COMPTE']),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final isWide = MediaQuery.of(context).size.width >= 900;
    final location = GoRouterState.of(context).matchedLocation;

    // Items filtrés selon le rôle
    final items = _allNavItems.where((item) {
      if (auth == null) return false;
      return item.roles.contains(auth.role);
    }).toList();

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            _SideNav(items: items, currentPath: location, auth: auth),
            const VerticalDivider(width: 1),
            Expanded(child: child),
          ],
        ),
      );
    }

    // Mobile — bottom nav + drawer
    final currentIndex = items.indexWhere(
      (i) => location.startsWith(i.path),
    );

    return Scaffold(
      key: mainScaffoldKey,
      drawer: _MobileDrawer(
        auth: auth,
        items: items,
        currentPath: location,
      ),
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex < 0 ? 0 : currentIndex,
        onDestinationSelected: (i) => context.go(items[i].path),
        destinations: items
            .map<NavigationDestination>((item) => NavigationDestination(
                  icon: Icon(item.icon),
                  selectedIcon: Icon(item.activeIcon),
                  label: item.label,
                ))
            .toList(),
      ),
    );
  }
}

// ─── Drawer mobile ────────────────────────────────────────────────────────────

class _MobileDrawer extends ConsumerWidget {
  final AuthResponse? auth;
  final List<_NavItem> items;
  final String currentPath;

  const _MobileDrawer({
    required this.auth,
    required this.items,
    required this.currentPath,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = auth;

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (user != null)
              InkWell(
                onTap: () {
                  Navigator.pop(context);
                  context.go('/profil');
                },
                child: UserAccountsDrawerHeader(
                  decoration: const BoxDecoration(color: AppTheme.primary),
                  currentAccountPicture: CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Text(
                      user.fullName.isNotEmpty
                          ? user.fullName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  accountName: Text(user.fullName),
                  accountEmail: Text(user.email),
                ),
              ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  ...items.map<Widget>((item) {
                    final isActive = currentPath.startsWith(item.path);
                    return ListTile(
                      leading: Icon(
                        isActive ? item.activeIcon : item.icon,
                        color: isActive ? AppTheme.primary : null,
                      ),
                      title: Text(item.label),
                      selected: isActive,
                      onTap: () {
                        Navigator.pop(context);
                        context.go(item.path);
                      },
                    );
                  }),
                  // Utilisateurs — admin seulement (absent de _allNavItems)
                  if (user?.isAdmin == true)
                    ListTile(
                      leading: Icon(
                        currentPath.startsWith('/utilisateurs')
                            ? Icons.manage_accounts
                            : Icons.manage_accounts_outlined,
                        color: currentPath.startsWith('/utilisateurs')
                            ? AppTheme.primary
                            : null,
                      ),
                      title: const Text('Utilisateurs'),
                      selected: currentPath.startsWith('/utilisateurs'),
                      onTap: () {
                        Navigator.pop(context);
                        context.go('/utilisateurs');
                      },
                    ),
                  // Rapports est déjà dans _allNavItems pour Admin/Gestionnaire
                  // → pas de duplication ici
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.person_outline,
                  color: AppTheme.primary),
              title: const Text('Mon profil'),
              onTap: () {
                Navigator.pop(context);
                context.go('/profil');
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: AppTheme.error),
              title: const Text('Se déconnecter',
                  style: TextStyle(color: AppTheme.error)),
              onTap: () async {
                Navigator.pop(context);
                await ref.read(authProvider.notifier).logout();
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Sidebar desktop ──────────────────────────────────────────────────────────

class _SideNav extends ConsumerWidget {
  final List<_NavItem> items;
  final String currentPath;
  final AuthResponse? auth;

  const _SideNav({
    required this.items,
    required this.currentPath,
    required this.auth,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = auth;

    return Container(
      width: 240,
      color: Colors.white,
      child: Column(
        children: [
          // Logo / Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.account_balance,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'MicroFinance',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          const SizedBox(height: 8),

          // Nav items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: [
                ...items.map<Widget>((item) {
                  final isActive = currentPath.startsWith(item.path);
                  return _SideNavItem(item: item, isActive: isActive);
                }),
                // Utilisateurs — admin seulement
                if (user?.isAdmin == true)
                  _SideNavItem(
                    item: const _NavItem(
                      icon: Icons.manage_accounts_outlined,
                      activeIcon: Icons.manage_accounts,
                      label: 'Utilisateurs',
                      path: '/utilisateurs',
                      roles: ['ADMIN'],
                    ),
                    isActive: currentPath.startsWith('/utilisateurs'),
                  ),
              ],
            ),
          ),

          const Divider(height: 1),

          // User footer — clic → profil
          if (user != null)
            InkWell(
              onTap: () => context.go('/profil'),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: AppTheme.primaryLight,
                      child: Text(
                        user.fullName.isNotEmpty
                            ? user.fullName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            user.fullName,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            _roleLabel(user.role),
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.logout,
                          size: 18, color: AppTheme.textSecondary),
                      tooltip: 'Se déconnecter',
                      onPressed: () async {
                        await ref.read(authProvider.notifier).logout();
                      },
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _roleLabel(String role) {
    const labels = {
      'ADMIN': 'Administrateur',
      'AGENT_TERRAIN': 'Agent terrain',
      'GESTIONNAIRE_COMPTE': 'Gestionnaire',
      'CAISSIER': 'Caissier',
    };
    return labels[role] ?? role;
  }
}

// ─── Widgets internes ─────────────────────────────────────────────────────────

class _SideNavItem extends StatelessWidget {
  final _NavItem item;
  final bool isActive;

  const _SideNavItem({required this.item, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.go(item.path),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primaryLight : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              isActive ? item.activeIcon : item.icon,
              size: 20,
              color: isActive ? AppTheme.primary : AppTheme.textSecondary,
            ),
            const SizedBox(width: 10),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 14,
                fontWeight:
                    isActive ? FontWeight.w600 : FontWeight.normal,
                color: isActive ? AppTheme.primary : AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String path;
  final List<String> roles;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.path,
    required this.roles,
  });
}
