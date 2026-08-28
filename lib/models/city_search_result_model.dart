class CitySearchResult {
  final String name;
  final String? admin1;
  final String? country;
  final double latitude;
  final double longitude;

  const CitySearchResult({
    required this.name,
    this.admin1,
    this.country,
    required this.latitude,
    required this.longitude,
  });

  factory CitySearchResult.fromJson(Map<String, dynamic> json) {
    return CitySearchResult(
      name: json['name'] as String,
      admin1: json['admin1'] as String?,
      country: json['country'] as String?,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }

  String get displayLabel =>
      [name, admin1, country].whereType<String>().where((e) => e.isNotEmpty).join(', ');
}
