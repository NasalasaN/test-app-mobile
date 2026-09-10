import 'dart:math';

/// Coordonnées de la Kaaba, à La Mecque.
const kaabaLatitude = 21.4225;
const kaabaLongitude = 39.8262;

/// Calcule le cap (en degrés, 0 = nord, sens horaire) à suivre depuis
/// ([latitude], [longitude]) pour faire face à la Kaaba, via la formule du
/// cap initial sur une grande orthodromie (great-circle bearing).
double qiblaBearing(double latitude, double longitude) {
  final phi1 = latitude * pi / 180;
  final phi2 = kaabaLatitude * pi / 180;
  final deltaLambda = (kaabaLongitude - longitude) * pi / 180;

  final y = sin(deltaLambda) * cos(phi2);
  final x = cos(phi1) * sin(phi2) - sin(phi1) * cos(phi2) * cos(deltaLambda);
  final theta = atan2(y, x);

  return (theta * 180 / pi + 360) % 360;
}

/// Distance à vol d'oiseau (en km) entre ([latitude], [longitude]) et la
/// Kaaba, via la formule de Haversine.
double distanceToKaabaKm(double latitude, double longitude) {
  const earthRadiusKm = 6371.0;
  final phi1 = latitude * pi / 180;
  final phi2 = kaabaLatitude * pi / 180;
  final deltaPhi = (kaabaLatitude - latitude) * pi / 180;
  final deltaLambda = (kaabaLongitude - longitude) * pi / 180;

  final a = sin(deltaPhi / 2) * sin(deltaPhi / 2) +
      cos(phi1) * cos(phi2) * sin(deltaLambda / 2) * sin(deltaLambda / 2);
  final c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return earthRadiusKm * c;
}
