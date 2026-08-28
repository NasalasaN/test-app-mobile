import 'package:flutter_test/flutter_test.dart';
import 'package:miqat/models/prayer_times_model.dart';
import 'package:miqat/utils/prayer_time_utils.dart';

PrayerTimes _sampleTimes(DateTime day) {
  DateTime at(int h, int m) => DateTime(day.year, day.month, day.day, h, m);
  return PrayerTimes(
    date: day,
    fajr: at(5, 0),
    sunrise: at(6, 30),
    dhuhr: at(13, 0),
    asr: at(16, 30),
    maghrib: at(19, 30),
    isha: at(21, 0),
    hijriDateLabel: '1 Muharram 1448',
    calculationMethodId: 21,
  );
}

void main() {
  final day = DateTime(2026, 1, 15);
  final times = _sampleTimes(day);

  group('arcFraction', () {
    test('avant Fajr -> 0.0', () {
      final before = DateTime(day.year, day.month, day.day, 4, 0);
      expect(arcFraction(before, times.fajr, times.isha), 0.0);
    });

    test('après Isha -> 1.0', () {
      final after = DateTime(day.year, day.month, day.day, 22, 0);
      expect(arcFraction(after, times.fajr, times.isha), 1.0);
    });

    test('à Fajr -> 0.0', () {
      expect(arcFraction(times.fajr, times.fajr, times.isha), 0.0);
    });

    test('à Isha -> 1.0', () {
      expect(arcFraction(times.isha, times.fajr, times.isha), 1.0);
    });

    test('à mi-parcours -> environ 0.5', () {
      final middle = times.fajr.add(
        Duration(seconds: times.isha.difference(times.fajr).inSeconds ~/ 2),
      );
      expect(arcFraction(middle, times.fajr, times.isha), closeTo(0.5, 0.01));
    });
  });

  group('nextPrayer', () {
    test('juste avant Fajr -> Fajr', () {
      final now = times.fajr.subtract(const Duration(minutes: 1));
      final result = nextPrayer(times, now);
      expect(result.name, PrayerName.fajr);
      expect(result.isEstimatedTomorrow, isFalse);
    });

    test('entre Dhuhr et Asr -> Asr', () {
      final now = times.dhuhr.add(const Duration(hours: 1));
      final result = nextPrayer(times, now);
      expect(result.name, PrayerName.asr);
    });

    test('juste après Isha -> Fajr du lendemain (estimation)', () {
      final now = times.isha.add(const Duration(minutes: 1));
      final result = nextPrayer(times, now);
      expect(result.name, PrayerName.fajr);
      expect(result.isEstimatedTomorrow, isTrue);
      expect(result.time.day, times.fajr.day + 1);
    });
  });
}
