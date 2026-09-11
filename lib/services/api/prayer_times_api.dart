import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/app_exception.dart';
import '../../models/prayer_times_model.dart';

/// Erreur levée par [PrayerTimesApi.fetchTimings] avec un message prêt à
/// afficher à l'utilisateur.
class PrayerTimesApiException implements AppException {
  const PrayerTimesApiException(this.messageFr);

  @override
  final String messageFr;

  @override
  String toString() => messageFr;
}

/// Récupération des horaires de prière du jour via l'API AlAdhan.
class PrayerTimesApi {
  PrayerTimesApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _baseUrl = 'https://api.aladhan.com/v1/timings';

  Future<PrayerTimes> fetchTimings({
    required double latitude,
    required double longitude,
    required DateTime forDate,
    required int calculationMethodId,
  }) async {
    final dateStr = '${_pad(forDate.day)}-${_pad(forDate.month)}-${forDate.year}';
    final uri = Uri.parse('$_baseUrl/$dateStr').replace(queryParameters: {
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      'method': calculationMethodId.toString(),
    });

    http.Response response;
    try {
      response = await _client.get(uri).timeout(const Duration(seconds: 10));
    } catch (_) {
      throw const PrayerTimesApiException(
        'Impossible de récupérer les horaires de prière. Vérifiez votre connexion.',
      );
    }

    if (response.statusCode != 200) {
      throw const PrayerTimesApiException(
        'Impossible de récupérer les horaires de prière. Vérifiez votre connexion.',
      );
    }

    try {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final data = json['data'] as Map<String, dynamic>;
      final timings = data['timings'] as Map<String, dynamic>;
      final dateInfo = data['date'] as Map<String, dynamic>;
      final hijri = dateInfo['hijri'] as Map<String, dynamic>;

      DateTime parseTime(String key) {
        final raw = (timings[key] as String).split(' ').first;
        final parts = raw.split(':');
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        return DateTime(forDate.year, forDate.month, forDate.day, hour, minute);
      }

      final hijriMonth = (hijri['month'] as Map<String, dynamic>)['en'];
      final hijriDateLabel = '${hijri['day']} $hijriMonth ${hijri['year']}';

      return PrayerTimes(
        date: DateTime(forDate.year, forDate.month, forDate.day),
        fajr: parseTime('Fajr'),
        sunrise: parseTime('Sunrise'),
        dhuhr: parseTime('Dhuhr'),
        asr: parseTime('Asr'),
        maghrib: parseTime('Maghrib'),
        isha: parseTime('Isha'),
        hijriDateLabel: hijriDateLabel,
        calculationMethodId: calculationMethodId,
      );
    } catch (_) {
      throw const PrayerTimesApiException(
        'Réponse invalide du service des horaires de prière.',
      );
    }
  }

  String _pad(int value) => value.toString().padLeft(2, '0');
}
