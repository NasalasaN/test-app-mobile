/// Les 6 temps affichés dans l'application, dans leur ordre chronologique.
enum PrayerName { fajr, sunrise, dhuhr, asr, maghrib, isha }

extension PrayerNameLabel on PrayerName {
  String get labelFr {
    switch (this) {
      case PrayerName.fajr:
        return 'Fajr';
      case PrayerName.sunrise:
        return 'Lever du soleil';
      case PrayerName.dhuhr:
        return 'Dhuhr';
      case PrayerName.asr:
        return 'Asr';
      case PrayerName.maghrib:
        return 'Maghrib';
      case PrayerName.isha:
        return 'Isha';
    }
  }
}

class PrayerTimes {
  final DateTime date;
  final DateTime fajr;
  final DateTime sunrise;
  final DateTime dhuhr;
  final DateTime asr;
  final DateTime maghrib;
  final DateTime isha;
  final String hijriDateLabel;
  final int calculationMethodId;

  const PrayerTimes({
    required this.date,
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
    required this.hijriDateLabel,
    required this.calculationMethodId,
  });

  /// Les 6 horaires dans l'ordre chronologique Fajr -> Isha, utilisé par
  /// l'arc du jour et par la planification des notifications.
  List<MapEntry<PrayerName, DateTime>> get orderedEntries => [
        MapEntry(PrayerName.fajr, fajr),
        MapEntry(PrayerName.sunrise, sunrise),
        MapEntry(PrayerName.dhuhr, dhuhr),
        MapEntry(PrayerName.asr, asr),
        MapEntry(PrayerName.maghrib, maghrib),
        MapEntry(PrayerName.isha, isha),
      ];
}
