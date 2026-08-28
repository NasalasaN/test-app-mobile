class Location {
  final double latitude;
  final double longitude;
  final String cityName;
  final String? country;
  final bool isManuallySelected;

  const Location({
    required this.latitude,
    required this.longitude,
    required this.cityName,
    this.country,
    this.isManuallySelected = false,
  });

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'cityName': cityName,
        'country': country,
        'isManuallySelected': isManuallySelected,
      };

  factory Location.fromJson(Map<String, dynamic> json) => Location(
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        cityName: json['cityName'] as String,
        country: json['country'] as String?,
        isManuallySelected: json['isManuallySelected'] as bool? ?? false,
      );
}
