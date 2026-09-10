// Tests de fumée : vérifient que l'application se lance sans exception,
// avec ou sans l'écran d'accueil explicatif du premier lancement.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:miqat/main.dart';
import 'package:miqat/services/storage/storage_service.dart';

void main() {
  testWidgets('premier lancement -> affiche l\'écran d\'accueil explicatif', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await StorageService.create();

    await tester.pumpWidget(MiqatApp(storage: storage));
    await tester.pump();

    expect(find.text('Bienvenue sur Miqat'), findsOneWidget);
  });

  testWidgets('lancement suivant -> affiche directement l\'app et son titre', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({'has_seen_onboarding': true});
    final storage = await StorageService.create();

    await tester.pumpWidget(MiqatApp(storage: storage));
    await tester.pump();

    expect(find.text('Miqat'), findsOneWidget);
  });
}
