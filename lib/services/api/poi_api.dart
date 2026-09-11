import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/app_exception.dart';
import '../../models/point_of_interest_model.dart';

/// Erreur levée par [PoiApi] avec un message prêt à afficher à l'utilisateur.
class PoiApiException implements AppException {
  const PoiApiException(this.messageFr);

  @override
  final String messageFr;

  @override
  String toString() => messageFr;
}

/// Recherche de mosquées et de restaurants halal/vegan à proximité, via
/// l'API gratuite Overpass (données OpenStreetMap, sans clé).
class PoiApi {
  PoiApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// Plusieurs instances publiques d'Overpass : la première qui répond est
  /// utilisée. Ces serveurs communautaires étant parfois surchargés, avoir
  /// un repli évite qu'une simple lenteur ponctuelle ne bloque la carte.
  static const _endpoints = [
    'https://overpass-api.de/api/interpreter',
    'https://overpass.kumi.systems/api/interpreter',
  ];

  /// Récupère les mosquées et restaurants halal/vegan dans un rayon de
  /// [radiusMeters] autour de ([latitude], [longitude]), en une seule
  /// requête (les catégories sont déduites des tags OSM côté client).
  Future<List<PointOfInterest>> fetchNearby({
    required double latitude,
    required double longitude,
    double radiusMeters = 3000,
  }) async {
    final query = _combinedQuery(latitude, longitude, radiusMeters);

    Object? lastError;
    for (final endpoint in _endpoints) {
      try {
        final elements = await _fetchElements(endpoint, query);
        return elements
            .map(_toPointOfInterest)
            .whereType<PointOfInterest>()
            .toList();
      } catch (e) {
        lastError = e;
        continue;
      }
    }

    if (lastError is PoiApiException) throw lastError;
    throw const PoiApiException(
      'Impossible de récupérer les lieux à proximité. Réessayez dans un instant.',
    );
  }

  String _combinedQuery(double lat, double lon, double radius) => '''
[out:json][timeout:25];
(
  node["amenity"="place_of_worship"]["religion"="muslim"](around:$radius,$lat,$lon);
  way["amenity"="place_of_worship"]["religion"="muslim"](around:$radius,$lat,$lon);
  node["amenity"~"restaurant|fast_food|cafe"]["diet:halal"~"yes|only"](around:$radius,$lat,$lon);
  way["amenity"~"restaurant|fast_food|cafe"]["diet:halal"~"yes|only"](around:$radius,$lat,$lon);
  node["amenity"~"restaurant|fast_food|cafe"]["diet:vegan"~"yes|only"](around:$radius,$lat,$lon);
  way["amenity"~"restaurant|fast_food|cafe"]["diet:vegan"~"yes|only"](around:$radius,$lat,$lon);
);
out center tags;
''';

  Future<List<dynamic>> _fetchElements(String endpoint, String overpassQl) async {
    http.Response response;
    try {
      response = await _client
          .post(
            Uri.parse(endpoint),
            headers: const {'User-Agent': 'Miqat/1.0 (com.miqat.miqat)'},
            body: {'data': overpassQl},
          )
          .timeout(const Duration(seconds: 20));
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
      return json['elements'] as List<dynamic>;
    } catch (_) {
      throw const PoiApiException('Réponse invalide du service de cartographie.');
    }
  }

  PointOfInterest? _toPointOfInterest(dynamic element) {
    final map = element as Map<String, dynamic>;
    double? lat = (map['lat'] as num?)?.toDouble();
    double? lon = (map['lon'] as num?)?.toDouble();
    if (lat == null || lon == null) {
      final center = map['center'] as Map<String, dynamic>?;
      lat = (center?['lat'] as num?)?.toDouble();
      lon = (center?['lon'] as num?)?.toDouble();
    }
    if (lat == null || lon == null) return null;

    final tags = map['tags'] as Map<String, dynamic>? ?? {};
    final category = _categoryFor(tags);
    if (category == null) return null;

    final name = (tags['name'] as String?)?.trim();
    final street = tags['addr:street'] as String?;
    final houseNumber = tags['addr:housenumber'] as String?;
    final address = [houseNumber, street]
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .join(' ');

    return PointOfInterest(
      id: '${map['type']}/${map['id']}',
      name: (name?.isNotEmpty ?? false) ? name! : category.genericNameFr,
      latitude: lat,
      longitude: lon,
      category: category,
      address: address.isEmpty ? null : address,
    );
  }

  PoiCategory? _categoryFor(Map<String, dynamic> tags) {
    if (tags['amenity'] == 'place_of_worship' && tags['religion'] == 'muslim') {
      return PoiCategory.mosque;
    }
    final halal = tags['diet:halal'] as String?;
    if (halal == 'yes' || halal == 'only') return PoiCategory.halal;
    final vegan = tags['diet:vegan'] as String?;
    if (vegan == 'yes' || vegan == 'only') return PoiCategory.vegan;
    return null;
  }
}
