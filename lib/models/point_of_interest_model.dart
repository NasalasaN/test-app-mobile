/// Catégories de lieux affichés sur la carte.
enum PoiCategory { mosque, halal, vegan }

extension PoiCategoryLabel on PoiCategory {
  String get labelFr {
    switch (this) {
      case PoiCategory.mosque:
        return 'Mosquées';
      case PoiCategory.halal:
        return 'Restaurants halal';
      case PoiCategory.vegan:
        return 'Restaurants vegan';
    }
  }

  String get genericNameFr {
    switch (this) {
      case PoiCategory.mosque:
        return 'Mosquée';
      case PoiCategory.halal:
        return 'Restaurant halal';
      case PoiCategory.vegan:
        return 'Restaurant vegan';
    }
  }
}

/// Un lieu affiché sur la carte (mosquée, restaurant halal ou vegan).
class PointOfInterest {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final PoiCategory category;
  final String? address;

  const PointOfInterest({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.category,
    this.address,
  });
}
