import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../models/ambiance_model.dart';
import '../../models/calculation_method_model.dart';
import '../../models/location_model.dart';
import '../../models/notification_settings_model.dart';

/// Persistance locale (localisation, méthode de calcul, préférences de
/// notification) via shared_preferences.
class StorageService {
  StorageService(this._prefs);

  final SharedPreferences _prefs;

  static const _keyLocation = 'location';
  static const _keyCalculationMethodId = 'calculation_method_id';
  static const _keyNotificationSettings = 'notification_settings';

  static Future<StorageService> create() async {
    return StorageService(await SharedPreferences.getInstance());
  }

  Location? readLocation() {
    final raw = _prefs.getString(_keyLocation);
    if (raw == null) return null;
    try {
      return Location.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> writeLocation(Location location) {
    return _prefs.setString(_keyLocation, jsonEncode(location.toJson()));
  }

  int readCalculationMethodId() {
    return _prefs.getInt(_keyCalculationMethodId) ??
        CalculationMethod.defaultMethodId;
  }

  Future<void> writeCalculationMethodId(int id) {
    return _prefs.setInt(_keyCalculationMethodId, id);
  }

  NotificationSettings readNotificationSettings() {
    final raw = _prefs.getString(_keyNotificationSettings);
    if (raw == null) return NotificationSettings.defaults();
    try {
      return NotificationSettings.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      return NotificationSettings.defaults();
    }
  }

  Future<void> writeNotificationSettings(NotificationSettings settings) {
    return _prefs.setString(
      _keyNotificationSettings,
      jsonEncode(settings.toJson()),
    );
  }

  // Cache local du Coran (pour une lecture hors-ligne après le premier
  // chargement de chaque sourate).
  static const _keyQuranSurahList = 'quran_surah_list';
  static String _keyQuranSurahDetail(int number) => 'quran_surah_$number';

  String? readCachedSurahListJson() => _prefs.getString(_keyQuranSurahList);

  Future<void> writeCachedSurahListJson(String json) {
    return _prefs.setString(_keyQuranSurahList, json);
  }

  String? readCachedSurahDetailJson(int number) =>
      _prefs.getString(_keyQuranSurahDetail(number));

  Future<void> writeCachedSurahDetailJson(int number, String json) {
    return _prefs.setString(_keyQuranSurahDetail(number), json);
  }

  // Ambiance visuelle de fond.
  static const _keyAmbiance = 'background_ambiance';

  BackgroundAmbiance readAmbiance() {
    final raw = _prefs.getString(_keyAmbiance);
    return BackgroundAmbiance.values.firstWhere(
      (a) => a.name == raw,
      orElse: () => BackgroundAmbiance.auto,
    );
  }

  Future<void> writeAmbiance(BackgroundAmbiance ambiance) {
    return _prefs.setString(_keyAmbiance, ambiance.name);
  }
}
