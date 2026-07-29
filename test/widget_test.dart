import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:microfinance_app/main.dart';

void main() {
  testWidgets('App affiche l\'écran de connexion', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MicroFinanceApp()));
    await tester.pumpAndSettle();

    expect(find.text('MicroFinance'), findsOneWidget);
    expect(find.text('Se connecter'), findsOneWidget);
  });
}
