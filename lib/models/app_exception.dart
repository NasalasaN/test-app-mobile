/// Erreur applicative avec un message français prêt à afficher, implémentée
/// par toutes les exceptions des services API de l'app (PrayerTimesApi,
/// WeatherApi, QuranApi, PoiApi, GeocodingApi). Permet aux écrans d'extraire
/// un message utilisateur sans connaître le type précis de l'exception.
abstract interface class AppException implements Exception {
  String get messageFr;
}

/// Message à afficher pour [error] : son [AppException.messageFr] s'il en
/// est une, sinon [fallback].
String friendlyErrorMessage(
  Object error, {
  String fallback = 'Erreur inattendue.',
}) {
  return error is AppException ? error.messageFr : fallback;
}
