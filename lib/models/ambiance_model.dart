/// Ambiance visuelle de fond de l'application.
enum BackgroundAmbiance { auto, stars, clouds, none }

extension BackgroundAmbianceLabel on BackgroundAmbiance {
  String get labelFr {
    switch (this) {
      case BackgroundAmbiance.auto:
        return 'Automatique (jour/nuit)';
      case BackgroundAmbiance.stars:
        return 'Ciel étoilé';
      case BackgroundAmbiance.clouds:
        return 'Nuages';
      case BackgroundAmbiance.none:
        return 'Aucune (fond uni)';
    }
  }
}
