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

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'fajr': fajr.toIso8601String(),
        'sunrise': sunrise.toIso8601String(),
        'dhuhr': dhuhr.toIso8601String(),
        'asr': asr.toIso8601String(),
        'maghrib': maghrib.toIso8601String(),
        'isha': isha.toIso8601String(),
        'hijriDateLabel': hijriDateLabel,
        'calculationMethodId': calculationMethodId,
      };

  factory PrayerTimes.fromJson(Map<String, dynamic> json) => PrayerTimes(
        date: DateTime.parse(json['date'] as String),
        fajr: DateTime.parse(json['fajr'] as String),
        sunrise: DateTime.parse(json['sunrise'] as String),
        dhuhr: DateTime.parse(json['dhuhr'] as String),
        asr: DateTime.parse(json['asr'] as String),
        maghrib: DateTime.parse(json['maghrib'] as String),
        isha: DateTime.parse(json['isha'] as String),
        hijriDateLabel: json['hijriDateLabel'] as String,
        calculationMethodId: json['calculationMethodId'] as int,
      );
}
