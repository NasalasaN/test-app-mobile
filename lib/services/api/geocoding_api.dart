import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/city_search_result_model.dart';
import '../../models/location_model.dart';

/// Erreur levée par [GeocodingApi.searchCities] avec un message prêt à
/// afficher à l'utilisateur.
class GeocodingApiException implements Exception {
  const GeocodingApiException(this.messageFr);

  final String messageFr;

  @override
  String toString() => messageFr;
}

/// Recherche de ville et géocodage inverse, tous deux gratuits et sans clé.
class GeocodingApi {
  GeocodingApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _searchBaseUrl = 'https://geocoding-api.open-meteo.com/v1/search';
  static const _reverseBaseUrl =
      'https://api.bigdatacloud.net/data/reverse-geocode-client';

  /// Recherche des villes correspondant à [query]. Retourne une liste vide
  /// si aucun résultat (ce n'est pas une erreur).
  Future<List<CitySearchResult>> searchCities(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const [];

    final uri = Uri.parse(_searchBaseUrl).replace(queryParameters: {
      'name': trimmed,
      'count': '6',
      'language': 'fr',
      'format': 'json',
    });

    http.Response response;
    try {
      response = await _client.get(uri).timeout(const Duration(seconds: 10));
    } catch (_) {
      throw const GeocodingApiException(
        'Impossible de rechercher cette ville. Vérifiez votre connexion.',
      );
    }

    if (response.statusCode != 200) {
      throw const GeocodingApiException(
        'Impossible de rechercher cette ville. Vérifiez votre connexion.',
      );
    }

    try {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final results = json['results'] as List<dynamic>?;
      if (results == null) return const [];
      return results
          .map((e) => CitySearchResult.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      throw const GeocodingApiException(
        'Réponse invalide du service de recherche de villes.',
      );
    }
  }

  /// Géocodage inverse pour obtenir le nom de ville à partir de coordonnées.
  /// Ne lève jamais d'exception : retourne `null` en cas d'échec, les
  /// coordonnées GPS restant utilisables même sans nom de ville.
  Future<Location?> reverseGeocode(double latitude, double longitude) async {
    final uri = Uri.parse(_reverseBaseUrl).replace(queryParameters: {
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      'localityLanguage': 'fr',
    });

    try {
      final response =
          await _client.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return null;

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final cityName = (json['city'] as String?)?.trim();
      final locality = (json['locality'] as String?)?.trim();
      final name = (cityName?.isNotEmpty ?? false)
          ? cityName!
          : (locality?.isNotEmpty ?? false)
              ? locality!
              : 'Position actuelle';
      final country = json['countryName'] as String?;

      return Location(
        latitude: latitude,
        longitude: longitude,
        cityName: name,
        country: country,
        isManuallySelected: false,
      );
    } catch (_) {
      return null;
    }
  }
}
