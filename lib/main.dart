import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'data/local/app_database.dart';
import 'providers/providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR', null);

  // SQLite est uniquement utilisé sur mobile pour le mode offline
  // Sur le web, toutes les données viennent directement de PostgreSQL via l'API
  if (!kIsWeb) {
    final database = await AppDatabase.open();
    runApp(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
        ],
        child: const _AppBootstrap(),
      ),
    );
  } else {
    // Sur le web, pas de SQLite - providers utiliseront les repositories Web
    runApp(
      const ProviderScope(
        child: _AppBootstrap(),
      ),
    );
  }
}

/// Démarre le service de synchronisation (mobile uniquement) puis affiche l'application.
class _AppBootstrap extends ConsumerStatefulWidget {
  const _AppBootstrap();

  @override
  ConsumerState<_AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends ConsumerState<_AppBootstrap> {
  @override
  void initState() {
    super.initState();
    // La synchronisation offline est uniquement pour mobile
    if (!kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final syncService = ref.read(syncServiceProvider);
        syncService.startListening();
        syncService.syncPendingChanges();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return const MicroFinanceApp();
  }
}

class MicroFinanceApp extends ConsumerWidget {
  const MicroFinanceApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'MicroFinance',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
      locale: const Locale('fr', 'FR'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('fr', 'FR'), Locale('en', 'US')],
    );
  }
}