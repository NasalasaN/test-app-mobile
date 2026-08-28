import 'prayer_times_model.dart';

class NotificationSettings {
  final bool globalEnabled;
  final Map<PrayerName, bool> enabledPrayers;

  /// URI (`content://…`) du son personnalisé choisi via le sélecteur natif,
  /// ou `null` pour utiliser le son système par défaut.
  final String? customSoundUri;

  /// Nom lisible du son personnalisé (mis en cache pour l'affichage, évite
  /// de re-résoudre l'URI à chaque ouverture des réglages).
  final String? customSoundTitle;

  const NotificationSettings({
    required this.globalEnabled,
    required this.enabledPrayers,
    this.customSoundUri,
    this.customSoundTitle,
  });

  /// Réglages par défaut : les 5 prières activées, le lever du soleil
  /// désactivé, son système.
  factory NotificationSettings.defaults() => const NotificationSettings(
        globalEnabled: true,
        enabledPrayers: {
          PrayerName.fajr: true,
          PrayerName.sunrise: false,
          PrayerName.dhuhr: true,
          PrayerName.asr: true,
          PrayerName.maghrib: true,
          PrayerName.isha: true,
        },
      );

  NotificationSettings copyWith({
    bool? globalEnabled,
    Map<PrayerName, bool>? enabledPrayers,
    String? customSoundUri,
    bool clearCustomSoundUri = false,
    String? customSoundTitle,
  }) {
    return NotificationSettings(
      globalEnabled: globalEnabled ?? this.globalEnabled,
      enabledPrayers: enabledPrayers ?? this.enabledPrayers,
      customSoundUri:
          clearCustomSoundUri ? null : (customSoundUri ?? this.customSoundUri),
      customSoundTitle: clearCustomSoundUri
          ? null
          : (customSoundTitle ?? this.customSoundTitle),
    );
  }

  Map<String, dynamic> toJson() => {
        'globalEnabled': globalEnabled,
        'enabledPrayers':
            enabledPrayers.map((key, value) => MapEntry(key.name, value)),
        'customSoundUri': customSoundUri,
        'customSoundTitle': customSoundTitle,
      };

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    final defaults = NotificationSettings.defaults();
    final rawPrayers = json['enabledPrayers'] as Map<String, dynamic>?;
    final enabledPrayers = <PrayerName, bool>{
      for (final name in PrayerName.values)
        name: rawPrayers?[name.name] as bool? ??
            defaults.enabledPrayers[name]!,
    };
    return NotificationSettings(
      globalEnabled: json['globalEnabled'] as bool? ?? true,
      enabledPrayers: enabledPrayers,
      customSoundUri: json['customSoundUri'] as String?,
      customSoundTitle: json['customSoundTitle'] as String?,
    );
  }
}
