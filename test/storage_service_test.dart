import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:miqat/models/ambiance_model.dart';
import 'package:miqat/models/location_model.dart';
import 'package:miqat/models/notification_settings_model.dart';
import 'package:miqat/models/prayer_times_model.dart';
import 'package:miqat/services/storage/storage_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('sans valeur stockée, les lectures retombent sur des valeurs par défaut sûres', () async {
    final storage = await StorageService.create();

    expect(storage.readLocation(), isNull);
    expect(storage.readCalculationMethodId(), 21);
    expect(storage.readNotificationSettings().globalEnabled, isTrue);
    expect(storage.readAmbiance(), BackgroundAmbiance.auto);
    expect(storage.readHasSeenOnboarding(), isFalse);
    expect(storage.readCachedSurahListJson(), isNull);
  });

  test('localisation : écriture puis lecture', () async {
    final storage = await StorageService.create();
    const location = Location(
      latitude: 33.5731,
      longitude: -7.5898,
      cityName: 'Casablanca',
      country: 'Maroc',
    );

    await storage.writeLocation(location);
    final restored = storage.readLocation();

    expect(restored?.latitude, location.latitude);
    expect(restored?.longitude, location.longitude);
    expect(restored?.cityName, location.cityName);
  });

  test('méthode de calcul : écriture puis lecture', () async {
    final storage = await StorageService.create();
    await storage.writeCalculationMethodId(12);
    expect(storage.readCalculationMethodId(), 12);
  });

  test('réglages de notification : écriture puis lecture', () async {
    final storage = await StorageService.create();
    final settings = NotificationSettings.defaults().copyWith(globalEnabled: false);
    await storage.writeNotificationSettings(settings);
    expect(storage.readNotificationSettings().globalEnabled, isFalse);
  });

  test('ambiance : écriture puis lecture', () async {
    final storage = await StorageService.create();
    await storage.writeAmbiance(BackgroundAmbiance.stars);
    expect(storage.readAmbiance(), BackgroundAmbiance.stars);
  });

  test('onboarding : marqué comme vu de façon persistante', () async {
    final storage = await StorageService.create();
    expect(storage.readHasSeenOnboarding(), isFalse);
    await storage.writeHasSeenOnboarding();
    expect(storage.readHasSeenOnboarding(), isTrue);
  });

  test('horaires de prière : mis en cache par date, isolés entre deux dates différentes', () async {
    final storage = await StorageService.create();
    final day1 = DateTime(2026, 3, 10);
    final day2 = DateTime(2026, 3, 11);
    DateTime at(DateTime d, int h, int m) => DateTime(d.year, d.month, d.day, h, m);

    final timesDay1 = PrayerTimes(
      date: day1,
      fajr: at(day1, 5, 0),
      sunrise: at(day1, 6, 30),
      dhuhr: at(day1, 13, 0),
      asr: at(day1, 16, 30),
      maghrib: at(day1, 19, 30),
      isha: at(day1, 21, 0),
      hijriDateLabel: '20 Ramadan 1447',
      calculationMethodId: 21,
    );

    expect(storage.readCachedPrayerTimes(day1), isNull);

    await storage.writeCachedPrayerTimes(day1, timesDay1);

    expect(storage.readCachedPrayerTimes(day1)?.fajr, timesDay1.fajr);
    expect(storage.readCachedPrayerTimes(day2), isNull);
  });
}
