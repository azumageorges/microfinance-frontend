import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/providers.dart';

/// Layout pour l'interface mobile Agent Terrain
class TerrainLayout extends ConsumerWidget {
  final Widget child;

  const TerrainLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final location = GoRouterState.of(context).matchedLocation;

    const navItems = [
      _TerrainNavItem(
        icon: Icons.home_outlined,
        activeIcon: Icons.home,
        label: 'Accueil',
        path: '/terrain',
      ),
      _TerrainNavItem(
        icon: Icons.people_outlined,
        activeIcon: Icons.people,
        label: 'Clients',
        path: '/terrain/clients',
      ),
      _TerrainNavItem(
        icon: Icons.person_add_outlined,
        activeIcon: Icons.person_add,
        label: 'Nouveau',
        path: '/terrain/clients/nouveau',
      ),
      _TerrainNavItem(
        icon: Icons.account_circle_outlined,
        activeIcon: Icons.account_circle,
        label: 'Profil',
        path: '/terrain/profil',
      ),
    ];

    final currentIndex = navItems.indexWhere(
      (i) => location == i.path || location.startsWith('${i.path}/'),
    );

    return Scaffold(
      appBar: _TerrainAppBar(auth: auth),
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex < 0 ? 0 : currentIndex,
        onDestinationSelected: (i) => context.go(navItems[i].path),
        destinations: navItems
            .map((item) => NavigationDestination(
                  icon: Icon(item.icon),
                  selectedIcon: Icon(item.activeIcon),
                  label: item.label,
                ))
            .toList(),
      ),
    );
  }
}

class _TerrainAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final dynamic auth;

  const _TerrainAppBar({required this.auth});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppBar(
      backgroundColor: AppTheme.primary,
      foregroundColor: Colors.white,
      title: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.account_balance,
                color: Colors.white, size: 16),
          ),
          const SizedBox(width: 8),
          const Text(
            'MicroFinance',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: Colors.white,
            ),
          ),
        ],
      ),
      actions: [
        // Indicateur mode hors ligne
        ref.watch(isOnlineProvider).when(
              data: (online) => online
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Tooltip(
                        message: 'Mode hors ligne',
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.cloud_off, size: 14, color: Colors.white),
                              SizedBox(width: 4),
                              Text(
                                'Hors ligne',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
            ),
        // Compteur sync en attente
        ref.watch(pendingSyncCountProvider).when(
              data: (count) => count > 0
                  ? Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Tooltip(
                        message: '$count modification(s) en attente de sync',
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade700,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.sync, size: 14, color: Colors.white),
                              const SizedBox(width: 4),
                              Text(
                                '$count',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
            ),
        if (auth != null)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              child: Text(
                auth.fullName.isNotEmpty
                    ? auth.fullName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _TerrainNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String path;

  const _TerrainNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.path,
  });
}
