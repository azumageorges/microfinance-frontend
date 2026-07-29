import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/layout/scaffold_keys.dart';

/// Barre d'application : menu sur mobile (accueil) ou retour (sous-pages).
class AppAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AppAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.actions,
    this.showSearch = false,
  });

  final String? title;
  final Widget? titleWidget;
  final List<Widget>? actions;

  /// Affiche le bouton loupe (recherche globale)
  final bool showSearch;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 900;
    final canPop = context.canPop();

    final searchBtn = IconButton(
      icon: const Icon(Icons.search),
      tooltip: 'Recherche',
      onPressed: () => context.push('/recherche'),
    );

    final allActions = [
      if (showSearch) searchBtn,
      ...?actions,
    ];

    return AppBar(
      title: titleWidget ??
          (title != null
              ? Text(title!,
                  style: const TextStyle(fontWeight: FontWeight.w700))
              : null),
      actions: allActions.isNotEmpty ? allActions : null,
      automaticallyImplyLeading: false,
      leading: !isWide
          ? (canPop
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => context.pop(),
                )
              : IconButton(
                  icon: const Icon(Icons.menu),
                  tooltip: 'Menu',
                  onPressed: () =>
                      mainScaffoldKey.currentState?.openDrawer(),
                ))
          : null,
    );
  }
}
