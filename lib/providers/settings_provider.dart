import 'package:flutter/foundation.dart';

import '../models/ambiance_model.dart';
import '../models/notification_settings_model.dart';
import '../models/prayer_times_model.dart';
import '../services/storage/storage_service.dart';

/// État des réglages persistés : méthode de calcul et préférences de
/// notification.
class SettingsProvider extends ChangeNotifier {
  // ignore: prefer_initializing_formals, keeps a public param name for callers.
  SettingsProvider({required StorageService storage}) : _storage = storage;

  final StorageService _storage;

  int calculationMethodId = 21;
  NotificationSettings notificationSettings = NotificationSettings.defaults();
  BackgroundAmbiance ambiance = BackgroundAmbiance.auto;

  Future<void> load() async {
    calculationMethodId = _storage.readCalculationMethodId();
    notificationSettings = _storage.readNotificationSettings();
    ambiance = _storage.readAmbiance();
    notifyListeners();
  }

  Future<void> setAmbiance(BackgroundAmbiance value) async {
    ambiance = value;
    notifyListeners();
    await _storage.writeAmbiance(value);
  }

  Future<void> setCalculationMethodId(int id) async {
    calculationMethodId = id;
    notifyListeners();
    await _storage.writeCalculationMethodId(id);
  }

  Future<void> setGlobalEnabled(bool enabled) async {
    notificationSettings = notificationSettings.copyWith(globalEnabled: enabled);
    notifyListeners();
    await _storage.writeNotificationSettings(notificationSettings);
  }

  Future<void> setPrayerEnabled(PrayerName prayer, bool enabled) async {
    final updated = Map<PrayerName, bool>.from(notificationSettings.enabledPrayers)
      ..[prayer] = enabled;
    notificationSettings = notificationSettings.copyWith(enabledPrayers: updated);
    notifyListeners();
    await _storage.writeNotificationSettings(notificationSettings);
  }

  /// Applique le son personnalisé choisi via le sélecteur natif.
  Future<void> setCustomSound(String uri, String? title) async {
    notificationSettings = notificationSettings.copyWith(
      customSoundUri: uri,
      customSoundTitle: title,
    );
    notifyListeners();
    await _storage.writeNotificationSettings(notificationSettings);
  }

  /// Revient au son système par défaut.
  Future<void> clearCustomSound() async {
    notificationSettings =
        notificationSettings.copyWith(clearCustomSoundUri: true);
    notifyListeners();
    await _storage.writeNotificationSettings(notificationSettings);
  }
}
