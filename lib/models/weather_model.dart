class WeatherData {
  final double temperature;
  final double apparentTemperature;
  final int humidity;
  final double windSpeedKmh;
  final int weatherCode;
  final DateTime fetchedAt;

  const WeatherData({
    required this.temperature,
    required this.apparentTemperature,
    required this.humidity,
    required this.windSpeedKmh,
    required this.weatherCode,
    required this.fetchedAt,
  });

  /// Construit à partir de l'objet `current` renvoyé par l'API Open-Meteo.
  factory WeatherData.fromJson(Map<String, dynamic> current) {
    return WeatherData(
      temperature: (current['temperature_2m'] as num).toDouble(),
      apparentTemperature: (current['apparent_temperature'] as num).toDouble(),
      humidity: (current['relative_humidity_2m'] as num).round(),
      windSpeedKmh: (current['wind_speed_10m'] as num).toDouble(),
      weatherCode: (current['weather_code'] as num).round(),
      fetchedAt: DateTime.tryParse(current['time'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
