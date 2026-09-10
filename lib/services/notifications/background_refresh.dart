import 'package:workmanager/workmanager.dart';

import '../api/prayer_times_api.dart';
import '../storage/storage_service.dart';
import 'notification_service.dart';

const backgroundRefreshUniqueName = 'miqat-refresh-prayer-times';
const backgroundRefreshTaskName = 'miqat.refresh_prayer_times';

/// Point d'entrée exécuté par le système (WorkManager sur Android,
/// BGTaskScheduler sur iOS) en arrière-plan, même application fermée. Relit
/// la localisation/les réglages stockés, récupère les horaires du jour et
/// reprogramme les notifications — permet de récupérer une éventuelle
/// coupure réseau et de préparer les horaires du lendemain sans que
/// l'utilisateur ait besoin de rouvrir l'app.
@pragma('vm:entry-point')
void backgroundRefreshDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      final storage = await StorageService.create();
      final location = storage.readLocation();
      if (location == null) return true;

      final methodId = storage.readCalculationMethodId();
      final notificationSettings = storage.readNotificationSettings();

      await NotificationService.instance.init();
      final useExactAlarms = await NotificationService.instance.canUseExactAlarms();

      final now = DateTime.now();
      final times = await PrayerTimesApi().fetchTimings(
        latitude: location.latitude,
        longitude: location.longitude,
        forDate: now,
        calculationMethodId: methodId,
      );
      await storage.writeCachedPrayerTimes(now, times);

      await NotificationService.instance.rescheduleAll(
        today: times,
        settings: notificationSettings,
        useExactAlarms: useExactAlarms,
      );
      return true;
    } catch (_) {
      // Échec silencieux : la prochaine exécution périodique (ou la
      // prochaine ouverture de l'app) réessaiera.
      return false;
    }
  });
}
