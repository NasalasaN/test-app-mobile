import 'package:flutter/foundation.dart';

import '../models/location_model.dart';
import '../models/weather_model.dart';
import '../services/api/weather_api.dart';
import 'load_status.dart';

/// État de la météo actuelle, isolé des autres providers : une erreur
/// météo n'affecte ni la localisation ni les horaires de prière.
class WeatherProvider extends ChangeNotifier {
  // ignore: prefer_initializing_formals, keeps a public param name for callers.
  WeatherProvider({required WeatherApi api}) : _api = api;

  final WeatherApi _api;

  LoadStatus status = LoadStatus.initial;
  WeatherData? data;
  String? errorMessageFr;

  Location? _lastLocation;

  Future<void> syncWith(Location location) async {
    final unchanged = _lastLocation != null &&
        _lastLocation!.latitude == location.latitude &&
        _lastLocation!.longitude == location.longitude;
    if (unchanged) return;
    _lastLocation = location;

    status = LoadStatus.loading;
    notifyListeners();

    try {
      data = await _api.fetchCurrentWeather(
        latitude: location.latitude,
        longitude: location.longitude,
      );
      status = LoadStatus.loaded;
      errorMessageFr = null;
    } on WeatherApiException catch (e) {
      status = LoadStatus.error;
      errorMessageFr = e.messageFr;
    } catch (_) {
      status = LoadStatus.error;
      errorMessageFr = 'Erreur inattendue lors du chargement de la météo.';
    }
    notifyListeners();
  }
}
