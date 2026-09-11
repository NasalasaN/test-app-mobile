import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/app_exception.dart';
import '../../models/weather_model.dart';

/// Erreur levée par [WeatherApi.fetchCurrentWeather] avec un message prêt à
/// afficher à l'utilisateur.
class WeatherApiException implements AppException {
  const WeatherApiException(this.messageFr);

  @override
  final String messageFr;

  @override
  String toString() => messageFr;
}

/// Récupération de la météo actuelle via l'API Open-Meteo.
class WeatherApi {
  WeatherApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _baseUrl = 'https://api.open-meteo.com/v1/forecast';

  Future<WeatherData> fetchCurrentWeather({
    required double latitude,
    required double longitude,
  }) async {
    final uri = Uri.parse(_baseUrl).replace(queryParameters: {
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      'current':
          'temperature_2m,relative_humidity_2m,apparent_temperature,weather_code,wind_speed_10m',
      'timezone': 'auto',
    });

    http.Response response;
    try {
      response = await _client.get(uri).timeout(const Duration(seconds: 10));
    } catch (_) {
      throw const WeatherApiException(
        'Impossible de récupérer la météo. Vérifiez votre connexion.',
      );
    }

    if (response.statusCode != 200) {
      throw const WeatherApiException(
        'Impossible de récupérer la météo. Vérifiez votre connexion.',
      );
    }

    try {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final current = json['current'] as Map<String, dynamic>;
      return WeatherData.fromJson(current);
    } catch (_) {
      throw const WeatherApiException('Réponse météo invalide.');
    }
  }
}
