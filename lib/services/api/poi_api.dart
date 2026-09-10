import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/point_of_interest_model.dart';

/// Erreur levée par [PoiApi] avec un message prêt à afficher à l'utilisateur.
class PoiApiException implements Exception {
  const PoiApiException(this.messageFr);

  final String messageFr;

  @override
  String toString() => messageFr;
}

/// Recherche de mosquées et de restaurants halal/vegan à proximité, via
/// l'API gratuite Overpass (données OpenStreetMap, sans clé).
class PoiApi {
  PoiApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _endpoint = 'https://overpass-api.de/api/interpreter';

  /// Récupère les mosquées et restaurants halal/vegan dans un rayon de
  /// [radiusMeters] autour de ([latitude], [longitude]).
  Future<List<PointOfInterest>> fetchNearby({
    required double latitude,
    required double longitude,
    double radiusMeters = 3000,
  }) async {
    try {
      final results = await Future.wait([
        _query(_mosqueQuery(latitude, longitude, radiusMeters), PoiCategory.mosque),
        _query(_dietQuery(latitude, longitude, radiusMeters, 'halal'), PoiCategory.halal),
        _query(_dietQuery(latitude, longitude, radiusMeters, 'vegan'), PoiCategory.vegan),
      ]);
      return results.expand((e) => e).toList();
    } on PoiApiException {
      rethrow;
    } catch (_) {
      throw const PoiApiException(
        'Impossible de récupérer les lieux à proximité. Vérifiez votre connexion.',
      );
    }
  }

  String _mosqueQuery(double lat, double lon, double radius) => '''
[out:json][timeout:25];
(
  node["amenity"="place_of_worship"]["religion"="muslim"](around:$radius,$lat,$lon);
  way["amenity"="place_of_worship"]["religion"="muslim"](around:$radius,$lat,$lon);
);
out center tags;
''';

  String _dietQuery(double lat, double lon, double radius, String diet) => '''
[out:json][timeout:25];
(
  node["amenity"~"restaurant|fast_food|cafe"]["diet:$diet"~"yes|only"](around:$radius,$lat,$lon);
  way["amenity"~"restaurant|fast_food|cafe"]["diet:$diet"~"yes|only"](around:$radius,$lat,$lon);
);
out center tags;
''';

  Future<List<PointOfInterest>> _query(String overpassQl, PoiCategory category) async {
    http.Response response;
    try {
      response = await _client
          .post(Uri.parse(_endpoint), body: {'data': overpassQl})
          .timeout(const Duration(seconds: 25));
    } catch (_) {
      throw const PoiApiException(
        'Impossible de récupérer les lieux à proximité. Vérifiez votre connexion.',
      );
    }

    if (response.statusCode != 200) {
      throw const PoiApiException(
        'Impossible de récupérer les lieux à proximité. Vérifiez votre connexion.',
      );
    }

    try {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final elements = json['elements'] as List<dynamic>;
      final pois = <PointOfInterest>[];
      for (final element in elements) {
        final map = element as Map<String, dynamic>;
        double? lat = (map['lat'] as num?)?.toDouble();
        double? lon = (map['lon'] as num?)?.toDouble();
        if (lat == null || lon == null) {
          final center = map['center'] as Map<String, dynamic>?;
          lat = (center?['lat'] as num?)?.toDouble();
          lon = (center?['lon'] as num?)?.toDouble();
        }
        if (lat == null || lon == null) continue;

        final tags = map['tags'] as Map<String, dynamic>? ?? {};
        final name = (tags['name'] as String?)?.trim();
        final street = tags['addr:street'] as String?;
        final houseNumber = tags['addr:housenumber'] as String?;
        final address = [houseNumber, street]
            .whereType<String>()
            .where((s) => s.isNotEmpty)
            .join(' ');

        pois.add(PointOfInterest(
          id: '${map['type']}/${map['id']}',
          name: (name?.isNotEmpty ?? false) ? name! : category.genericNameFr,
          latitude: lat,
          longitude: lon,
          category: category,
          address: address.isEmpty ? null : address,
        ));
      }
      return pois;
    } catch (_) {
      throw const PoiApiException('Réponse invalide du service de cartographie.');
    }
  }
}
