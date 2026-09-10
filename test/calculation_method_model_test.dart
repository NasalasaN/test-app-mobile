import 'package:flutter_test/flutter_test.dart';
import 'package:miqat/models/calculation_method_model.dart';

void main() {
  test('la méthode par défaut est le Maroc (21)', () {
    expect(CalculationMethod.defaultMethodId, 21);
  });

  test('byId retrouve la bonne méthode', () {
    expect(CalculationMethod.byId(12).label, contains('France'));
    expect(CalculationMethod.byId(4).label, contains('Umm Al-Qura'));
  });

  test('byId sur un id inconnu retombe sur la première méthode de la liste', () {
    final fallback = CalculationMethod.byId(9999);
    expect(fallback, CalculationMethod.all.first);
  });

  test('toutes les méthodes annoncées dans le cahier des charges sont présentes', () {
    final ids = CalculationMethod.all.map((m) => m.id).toSet();
    expect(ids, {21, 12, 3, 5, 4, 2, 19, 18});
  });
}
