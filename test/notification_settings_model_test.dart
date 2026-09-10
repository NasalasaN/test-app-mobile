import 'package:flutter_test/flutter_test.dart';
import 'package:miqat/models/notification_settings_model.dart';
import 'package:miqat/models/prayer_times_model.dart';

void main() {
  test('defaults() active Fajr/Dhuhr/Asr/Maghrib/Isha, désactive le lever du soleil', () {
    final defaults = NotificationSettings.defaults();
    expect(defaults.globalEnabled, isTrue);
    expect(defaults.enabledPrayers[PrayerName.fajr], isTrue);
    expect(defaults.enabledPrayers[PrayerName.sunrise], isFalse);
    expect(defaults.enabledPrayers[PrayerName.dhuhr], isTrue);
    expect(defaults.enabledPrayers[PrayerName.asr], isTrue);
    expect(defaults.enabledPrayers[PrayerName.maghrib], isTrue);
    expect(defaults.enabledPrayers[PrayerName.isha], isTrue);
    expect(defaults.customSoundUri, isNull);
  });

  test('toJson puis fromJson redonne les mêmes réglages', () {
    final original = NotificationSettings.defaults().copyWith(
      globalEnabled: false,
      customSoundUri: 'content://media/custom',
      customSoundTitle: 'Argon',
    );

    final restored = NotificationSettings.fromJson(original.toJson());

    expect(restored.globalEnabled, isFalse);
    expect(restored.customSoundUri, 'content://media/custom');
    expect(restored.customSoundTitle, 'Argon');
    expect(restored.enabledPrayers, original.enabledPrayers);
  });

  test('copyWith clearCustomSoundUri efface le son personnalisé', () {
    final withCustomSound = NotificationSettings.defaults().copyWith(
      customSoundUri: 'content://media/custom',
      customSoundTitle: 'Argon',
    );
    final cleared = withCustomSound.copyWith(clearCustomSoundUri: true);

    expect(cleared.customSoundUri, isNull);
    expect(cleared.customSoundTitle, isNull);
  });

  test('fromJson avec un JSON partiel retombe sur les valeurs par défaut manquantes', () {
    final restored = NotificationSettings.fromJson({'globalEnabled': false});
    expect(restored.globalEnabled, isFalse);
    expect(restored.enabledPrayers[PrayerName.fajr], isTrue);
    expect(restored.enabledPrayers[PrayerName.sunrise], isFalse);
  });
}
