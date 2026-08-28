import '../models/prayer_times_model.dart';

/// Position (0.0 à 1.0) de [reference] sur l'arc du jour allant de Fajr à
/// Isha. Clampée aux bornes avant Fajr / après Isha.
double arcFraction(DateTime reference, DateTime fajr, DateTime isha) {
  final totalSeconds = isha.difference(fajr).inSeconds;
  if (totalSeconds <= 0) return 0.0;
  final elapsedSeconds = reference.difference(fajr).inSeconds;
  final t = elapsedSeconds / totalSeconds;
  return t.clamp(0.0, 1.0);
}

class NextPrayerInfo {
  final PrayerName name;
  final DateTime time;

  /// true si l'horaire retourné est une estimation pour le Fajr du
  /// lendemain (données du jour suivant pas encore chargées).
  final bool isEstimatedTomorrow;

  const NextPrayerInfo({
    required this.name,
    required this.time,
    this.isEstimatedTomorrow = false,
  });
}

/// Détermine la prochaine prière à venir à partir de [now]. Si toutes les
/// prières du jour sont passées, retourne une estimation du Fajr du
/// lendemain (même heure que celui d'aujourd'hui) le temps que les horaires
/// réels du jour suivant soient récupérés.
NextPrayerInfo nextPrayer(PrayerTimes times, DateTime now) {
  for (final entry in times.orderedEntries) {
    if (entry.value.isAfter(now)) {
      return NextPrayerInfo(name: entry.key, time: entry.value);
    }
  }
  return NextPrayerInfo(
    name: PrayerName.fajr,
    time: times.fajr.add(const Duration(days: 1)),
    isEstimatedTomorrow: true,
  );
}
