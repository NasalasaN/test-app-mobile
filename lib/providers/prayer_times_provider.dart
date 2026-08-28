import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/location_model.dart';
import '../models/notification_settings_model.dart';
import '../models/prayer_times_model.dart';
import '../services/api/prayer_times_api.dart';
import '../services/notifications/notification_service.dart';
import '../utils/prayer_time_utils.dart';
import 'load_status.dart';

/// État des horaires de prière du jour : chargement, compte à rebours vers
/// la prochaine prière, rafraîchissement automatique à minuit, et
/// reprogrammation des notifications.
class PrayerTimesProvider extends ChangeNotifier {
  // ignore: prefer_initializing_formals, keeps a public param name for callers.
  PrayerTimesProvider({required PrayerTimesApi api}) : _api = api;

  final PrayerTimesApi _api;

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
      _updateNextPrayer();
      _startCountdownTicker();
      _scheduleMidnightRefresh(notificationSettings);

      await _ensureExactAlarmsChecked();
      await NotificationService.instance.rescheduleAll(
        today: times,
        settings: notificationSettings,
        useExactAlarms: _useExactAlarms,
      );
    } on PrayerTimesApiException catch (e) {
      status = LoadStatus.error;
      errorMessageFr = e.messageFr;
      // On garde volontairement les anciens horaires (`today`) affichés
      // s'ils existent, plutôt que de vider l'écran.
    } catch (_) {
      status = LoadStatus.error;
      errorMessageFr = 'Erreur inattendue lors du chargement des horaires.';
    }
    notifyListeners();
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
