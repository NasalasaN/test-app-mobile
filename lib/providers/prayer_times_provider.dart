// ignore_for_file: prefer_initializing_formals, keeps public param names for callers.
import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/location_model.dart';
import '../models/notification_settings_model.dart';
import '../models/prayer_times_model.dart';
import '../services/api/prayer_times_api.dart';
import '../services/notifications/notification_service.dart';
import '../services/storage/storage_service.dart';
import '../utils/prayer_time_utils.dart';
import 'load_status.dart';

/// Nombre de jours pré-chargés en cache à l'avance, pour que l'app reste
/// utilisable hors-ligne plusieurs jours en cas de coupure réseau.
const _prefetchDays = 6;

/// État des horaires de prière du jour : chargement, compte à rebours vers
/// la prochaine prière, rafraîchissement automatique à minuit, et
/// reprogrammation des notifications.
class PrayerTimesProvider extends ChangeNotifier {
  PrayerTimesProvider({required PrayerTimesApi api, required StorageService storage})
      : _api = api,
        _storage = storage;

  final PrayerTimesApi _api;
  final StorageService _storage;

  LoadStatus status = LoadStatus.initial;
  PrayerTimes? today;
  String? errorMessageFr;
  NextPrayerInfo? next;
  Duration? remaining;

  Location? _lastLocation;
  int? _lastMethodId;
  Timer? _countdownTimer;
  Timer? _midnightTimer;
  bool _exactAlarmsChecked = false;
  bool _useExactAlarms = false;

  /// Recharge les horaires si la localisation ou la méthode de calcul ont
  /// changé (no-op sinon, pour éviter les rafraîchissements en boucle).
  Future<void> syncWith(
    Location location,
    int methodId,
    NotificationSettings notificationSettings,
  ) async {
    final unchanged = _lastLocation != null &&
        _lastLocation!.latitude == location.latitude &&
        _lastLocation!.longitude == location.longitude &&
        _lastMethodId == methodId;
    if (unchanged) return;

    _lastLocation = location;
    _lastMethodId = methodId;
    await _fetch(DateTime.now(), notificationSettings);
  }

  /// Reprogramme uniquement les notifications (horaires déjà chargés) —
  /// utile quand seules les préférences de notification changent.
  Future<void> rescheduleNotificationsOnly(
    NotificationSettings notificationSettings,
  ) async {
    if (today == null) return;
    await _ensureExactAlarmsChecked();
    await NotificationService.instance.rescheduleAll(
      today: today!,
      settings: notificationSettings,
      useExactAlarms: _useExactAlarms,
    );
  }

  Future<void> _fetch(
    DateTime forDate,
    NotificationSettings notificationSettings,
  ) async {
    if (_lastLocation == null || _lastMethodId == null) return;
    status = LoadStatus.loading;
    notifyListeners();

    try {
      final times = await _api.fetchTimings(
        latitude: _lastLocation!.latitude,
        longitude: _lastLocation!.longitude,
        forDate: forDate,
        calculationMethodId: _lastMethodId!,
      );
      today = times;
      status = LoadStatus.loaded;
      errorMessageFr = null;
      await _storage.writeCachedPrayerTimes(forDate, times);
      _updateNextPrayer();
      _startCountdownTicker();
      _scheduleMidnightRefresh(notificationSettings);

      await _ensureExactAlarmsChecked();
      await NotificationService.instance.rescheduleAll(
        today: times,
        settings: notificationSettings,
        useExactAlarms: _useExactAlarms,
      );

      unawaited(_prefetchUpcomingDays());
    } on PrayerTimesApiException catch (e) {
      final cached = _storage.readCachedPrayerTimes(forDate);
      if (cached != null) {
        today = cached;
        status = LoadStatus.loaded;
        errorMessageFr = null;
        _updateNextPrayer();
        _startCountdownTicker();
        _scheduleMidnightRefresh(notificationSettings);
      } else {
        status = LoadStatus.error;
        errorMessageFr = e.messageFr;
        // On garde volontairement les anciens horaires (`today`) affichés
        // s'ils existent, plutôt que de vider l'écran.
      }
    } catch (_) {
      status = LoadStatus.error;
      errorMessageFr = 'Erreur inattendue lors du chargement des horaires.';
    }
    notifyListeners();
  }

  /// Précharge silencieusement les [_prefetchDays] jours suivants dans le
  /// cache local, en tâche de fond (échecs ignorés — c'est un confort, pas
  /// une opération critique). Permet à l'app de rester utilisable même
  /// après plusieurs jours sans connexion.
  Future<void> _prefetchUpcomingDays() async {
    if (_lastLocation == null || _lastMethodId == null) return;
    for (var i = 1; i <= _prefetchDays; i++) {
      final date = DateTime.now().add(Duration(days: i));
      if (_storage.readCachedPrayerTimes(date) != null) continue;
      try {
        final times = await _api.fetchTimings(
          latitude: _lastLocation!.latitude,
          longitude: _lastLocation!.longitude,
          forDate: date,
          calculationMethodId: _lastMethodId!,
        );
        await _storage.writeCachedPrayerTimes(date, times);
      } catch (_) {
        // Best-effort : on retentera au prochain lancement avec réseau.
        return;
      }
    }
  }

  Future<void> _ensureExactAlarmsChecked() async {
    if (_exactAlarmsChecked) return;
    _useExactAlarms = await NotificationService.instance.canUseExactAlarms();
    _exactAlarmsChecked = true;
  }

  void _updateNextPrayer() {
    if (today == null) return;
    final now = DateTime.now();
    next = nextPrayer(today!, now);
    remaining = next!.time.difference(now);
  }

  void _startCountdownTicker() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateNextPrayer();
      notifyListeners();
    });
  }

  void _scheduleMidnightRefresh(NotificationSettings notificationSettings) {
    _midnightTimer?.cancel();
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    _midnightTimer = Timer(nextMidnight.difference(now), () async {
      await _fetch(DateTime.now(), notificationSettings);
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _midnightTimer?.cancel();
    super.dispose();
  }
}
