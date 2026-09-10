import 'package:flutter_test/flutter_test.dart';
import 'package:miqat/utils/qibla_utils.dart';

void main() {
  group('qiblaBearing', () {
    test('point au nord de La Mecque, même longitude -> cap ~180° (sud)', () {
      final bearing = qiblaBearing(kaabaLatitude + 20, kaabaLongitude);
      expect(bearing, closeTo(180, 0.01));
    });

    test('point au sud de La Mecque, même longitude -> cap ~0° (nord)', () {
      final bearing = qiblaBearing(kaabaLatitude - 20, kaabaLongitude);
      expect(bearing, closeTo(0, 0.01));
    });

    test('retourne toujours une valeur dans [0, 360[', () {
      // Paris
      final bearing = qiblaBearing(48.8566, 2.3522);
      expect(bearing, greaterThanOrEqualTo(0));
      expect(bearing, lessThan(360));
    });
  });

  group('distanceToKaabaKm', () {
    test('depuis La Mecque elle-même -> ~0 km', () {
      expect(distanceToKaabaKm(kaabaLatitude, kaabaLongitude), closeTo(0, 0.01));
    });

    test('1° de latitude d\'écart -> environ 111 km', () {
      final distance = distanceToKaabaKm(kaabaLatitude + 1, kaabaLongitude);
      expect(distance, closeTo(111, 2));
    });
  });
}
