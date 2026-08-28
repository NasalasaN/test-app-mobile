// Test de fumée : vérifie que l'application se lance sans exception et
// affiche son titre.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:miqat/main.dart';
import 'package:miqat/services/storage/storage_service.dart';

void main() {
  testWidgets('Miqat démarre et affiche le titre', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await StorageService.create();

    await tester.pumpWidget(MiqatApp(storage: storage));
    await tester.pump();

    expect(find.text('Miqat'), findsOneWidget);
  });
}
