// ignore_for_file: prefer_initializing_formals, private fields can't be
// named constructor parameters and stay usable from other libraries.
import 'package:flutter/foundation.dart';

import '../models/location_model.dart';
import '../services/api/geocoding_api.dart';
import '../services/location_service.dart';
import '../services/storage/storage_service.dart';
import 'load_status.dart';

/// État de la localisation choisie : géolocalisation automatique, recherche
/// manuelle en repli, et persistance locale du choix.
class LocationProvider extends ChangeNotifier {
  LocationProvider({
    required LocationService locationService,
    required GeocodingApi geocodingApi,
    required StorageService storage,
  })  : _locationService = locationService,
        _geocodingApi = geocodingApi,
        _storage = storage;

  final LocationService _locationService;
  final GeocodingApi _geocodingApi;
  final StorageService _storage;

  LoadStatus status = LoadStatus.initial;
  Location? location;
  String? errorMessageFr;
  bool permissionPermanentlyDenied = false;

  /// À appeler une fois au démarrage : réutilise la localisation stockée si
  /// elle existe, sinon tente la géolocalisation automatique.
  Future<void> init() async {
    final stored = _storage.readLocation();
    if (stored != null) {
      location = stored;
      status = LoadStatus.loaded;
      notifyListeners();
      return;
    }
    await useCurrentLocation();
  }

  /// Tente la géolocalisation automatique (demande la permission si besoin).
  /// En cas d'échec, laisse `location` à `null` : l'UI doit alors proposer
  /// la recherche manuelle de ville.
  Future<void> useCurrentLocation() async {
    status = LoadStatus.loading;
    errorMessageFr = null;
    permissionPermanentlyDenied = false;
    notifyListeners();

    try {
      final position = await _locationService.getCurrentPosition();
      final resolved = await _geocodingApi.reverseGeocode(
        position.latitude,
        position.longitude,
      );
      final newLocation = resolved ??
          Location(
            latitude: position.latitude,
            longitude: position.longitude,
            cityName: 'Position actuelle',
            isManuallySelected: false,
          );
      location = newLocation;
      status = LoadStatus.loaded;
      await _storage.writeLocation(newLocation);
    } on LocationServiceDisabledException {
      status = LoadStatus.error;
      errorMessageFr =
          'La localisation est désactivée. Activez-la ou choisissez une ville manuellement.';
    } on LocationPermissionDeniedException catch (e) {
      status = LoadStatus.error;
      permissionPermanentlyDenied = e.isPermanentlyDenied;
      errorMessageFr = e.isPermanentlyDenied
          ? 'Permission de localisation refusée définitivement. Autorisez-la dans les réglages, ou choisissez une ville manuellement.'
          : 'Permission de localisation refusée. Choisissez une ville manuellement.';
    } catch (_) {
      status = LoadStatus.error;
      errorMessageFr =
          'Impossible d\'obtenir votre position. Choisissez une ville manuellement.';
    }
    notifyListeners();
  }

  /// Enregistre une localisation choisie manuellement (recherche de ville).
  Future<void> setManualLocation(Location newLocation) async {
    location = newLocation;
    status = LoadStatus.loaded;
    errorMessageFr = null;
    notifyListeners();
    await _storage.writeLocation(newLocation);
  }

  Future<void> retry() => useCurrentLocation();
}
