import 'package:flutter_test/flutter_test.dart';
import 'package:miqat/utils/weather_code_mapper.dart';

void main() {
  group('weatherInfoForCode', () {
    test('code 0 -> ciel dégagé', () {
      expect(weatherInfoForCode(0).label, 'Ciel dégagé');
    });

    test('code 61 -> pluie', () {
      expect(weatherInfoForCode(61).label, 'Pluie');
    });

    test('code 71 -> neige', () {
      expect(weatherInfoForCode(71).label, 'Neige');
    });

    test('code 95 -> orage', () {
      expect(weatherInfoForCode(95).label, 'Orage');
    });

    test('code 99 -> orage avec grêle', () {
      expect(weatherInfoForCode(99).label, 'Orage avec grêle');
    });

    test('code inconnu -> libellé générique', () {
      expect(weatherInfoForCode(-1).label, 'Conditions inconnues');
    });
  });
}
