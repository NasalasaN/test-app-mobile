import 'package:geolocator/geolocator.dart';

/// Levée quand le service de localisation du système est désactivé.
class LocationServiceDisabledException implements Exception {}

/// Levée quand la permission de localisation est refusée.
class LocationPermissionDeniedException implements Exception {
  const LocationPermissionDeniedException({required this.isPermanentlyDenied});

  final bool isPermanentlyDenied;
}

/// Accès à la position de l'appareil (permissions + GPS), via geolocator.
class LocationService {
  Future<bool> isServiceEnabled() => Geolocator.isLocationServiceEnabled();

  Future<LocationPermission> checkPermission() => Geolocator.checkPermission();

  Future<LocationPermission> requestPermission() =>
      Geolocator.requestPermission();

  Future<bool> openAppSettings() => Geolocator.openAppSettings();

  /// Vérifie service + permission puis retourne la position actuelle.
  /// Lève [LocationServiceDisabledException] ou
  /// [LocationPermissionDeniedException] selon le cas — jamais d'autre
  /// exception non gérée.
  Future<Position> getCurrentPosition() async {
    final serviceEnabled = await isServiceEnabled();
    if (!serviceEnabled) {
      throw LocationServiceDisabledException();
    }

    var permission = await checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      throw const LocationPermissionDeniedException(isPermanentlyDenied: true);
    }
    if (permission == LocationPermission.denied) {
      throw const LocationPermissionDeniedException(isPermanentlyDenied: false);
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 15),
      ),
    );
  }
}
