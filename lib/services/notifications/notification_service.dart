import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../models/notification_settings_model.dart';
import '../../models/prayer_times_model.dart';

const _androidChannelSystemId = 'prayer_times_system';

/// Programmation des notifications locales pour les horaires de prière, via
/// flutter_local_notifications + timezone. Fonctionne même application
/// fermée grâce aux alarmes système.
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Canaux Android déjà créés lors de cette exécution (le son d'un canal
  /// est immuable après sa création — un nouveau son personnalisé implique
  /// donc un nouveau canal, identifié par le hash de son URI).
  final Set<String> _createdChannelIds = {};

  /// Initialise le plugin, le fuseau horaire et les canaux Android. À
  /// appeler une seule fois au démarrage, avant toute programmation. Ne
  /// demande aucune permission (voir [requestPermissions]).
  Future<void> init() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    try {
      final tzInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(tzInfo.identifier));
    } catch (_) {
      // Le fuseau local reste UTC par défaut si la détection échoue —
      // dégradation silencieuse plutôt qu'un crash au démarrage.
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _androidChannelSystemId,
          'Horaires de prière (son système)',
          description: 'Notifications aux heures de prière, son système par défaut',
          importance: Importance.high,
        ),
      );
      _createdChannelIds.add(_androidChannelSystemId);
    }

    _initialized = true;
  }

  /// Demande les permissions nécessaires (notifications Android 13+/iOS,
  /// alarmes exactes Android). Retourne `true` si les alarmes exactes sont
  /// disponibles (sinon un repli en mode approximatif est utilisé).
  Future<bool> requestPermissions() async {
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
      var canExact = await androidPlugin.canScheduleExactNotifications();
      if (canExact != true) {
        canExact = await androidPlugin.requestExactAlarmsPermission();
      }
      return canExact ?? false;
    }

    final iosPlugin = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (iosPlugin != null) {
      await iosPlugin.requestPermissions(alert: true, badge: false, sound: true);
    }
    return true;
  }

  /// Vérifie si les alarmes exactes sont actuellement autorisées côté
  /// Android (à réévaluer par ex. au retour au premier plan de l'app).
  Future<bool> canUseExactAlarms() async {
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin == null) return true;
    return (await androidPlugin.canScheduleExactNotifications()) ?? false;
  }

  /// Annule toutes les notifications programmées puis reprogramme celles du
  /// jour selon [settings], pour les horaires encore à venir dans [today].
  Future<void> rescheduleAll({
    required PrayerTimes today,
    required NotificationSettings settings,
    required bool useExactAlarms,
  }) async {
    await _plugin.cancelAll();
    if (!settings.globalEnabled) return;

    final now = DateTime.now();
    for (final entry in today.orderedEntries) {
      if (settings.enabledPrayers[entry.key] != true) continue;
      if (!entry.value.isAfter(now)) continue;
      await _scheduleOne(
        id: 100 + entry.key.index,
        prayer: entry.key,
        time: entry.value,
        settings: settings,
        useExactAlarms: useExactAlarms,
      );
    }
  }

  Future<void> _scheduleOne({
    required int id,
    required PrayerName prayer,
    required DateTime time,
    required NotificationSettings settings,
    required bool useExactAlarms,
  }) async {
    final customUri = settings.customSoundUri;
    final channelId = customUri == null
        ? _androidChannelSystemId
        : 'prayer_times_custom_${customUri.hashCode.toUnsigned(32)}';

    if (customUri != null) {
      await _ensureCustomChannel(channelId, customUri, settings.customSoundTitle);
    }

    await _plugin.zonedSchedule(
      id: id,
      title: 'Miqat',
      body: "${prayer.labelFr} — il est l'heure de la prière.",
      scheduledDate: tz.TZDateTime.from(time, tz.local),
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          customUri == null
              ? 'Horaires de prière (son système)'
              : 'Horaires de prière (son personnalisé)',
          channelDescription: 'Notifications pour les heures de prière',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
        ),
        // iOS ne permet pas de choisir un son arbitraire du système ou
        // importé par l'utilisateur pour une notification locale tierce :
        // seul le son système par défaut est utilisé sur cette plateforme.
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
          presentBadge: false,
        ),
      ),
      androidScheduleMode: useExactAlarms
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  Future<void> _ensureCustomChannel(
    String channelId,
    String soundUri,
    String? title,
  ) async {
    if (_createdChannelIds.contains(channelId)) return;
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin == null) return;

    await androidPlugin.createNotificationChannel(
      AndroidNotificationChannel(
        channelId,
        'Horaires de prière — ${title ?? 'son personnalisé'}',
        description: 'Notifications aux heures de prière, son personnalisé',
        importance: Importance.high,
        sound: UriAndroidNotificationSound(soundUri),
      ),
    );
    _createdChannelIds.add(channelId);
  }
}
