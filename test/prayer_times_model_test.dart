import 'package:flutter_test/flutter_test.dart';
import 'package:miqat/models/prayer_times_model.dart';

void main() {
  test('toJson puis fromJson redonne les mêmes horaires', () {
    final day = DateTime(2026, 3, 10);
    DateTime at(int h, int m) => DateTime(day.year, day.month, day.day, h, m);
    final original = PrayerTimes(
      date: day,
      fajr: at(5, 12),
      sunrise: at(6, 40),
      dhuhr: at(13, 5),
      asr: at(16, 20),
      maghrib: at(19, 10),
      isha: at(20, 35),
      hijriDateLabel: '20 Ramadan 1447',
      calculationMethodId: 21,
    );

    final restored = PrayerTimes.fromJson(original.toJson());

    expect(restored.date, original.date);
    expect(restored.fajr, original.fajr);
    expect(restored.sunrise, original.sunrise);
    expect(restored.dhuhr, original.dhuhr);
    expect(restored.asr, original.asr);
    expect(restored.maghrib, original.maghrib);
    expect(restored.isha, original.isha);
    expect(restored.hijriDateLabel, original.hijriDateLabel);
    expect(restored.calculationMethodId, original.calculationMethodId);
  });
}
