// ignore_for_file: prefer_initializing_formals, keeps public param names for callers.
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/surah_model.dart';
import '../storage/storage_service.dart';

/// Erreur levée par [QuranApi] avec un message prêt à afficher à l'utilisateur.
class QuranApiException implements Exception {
  const QuranApiException(this.messageFr);

  final String messageFr;

  @override
  String toString() => messageFr;
}

/// Récupération du texte du Coran (arabe, translittération phonétique,
/// traduction française) via l'API gratuite alquran.cloud, avec mise en
/// cache locale pour une lecture hors-ligne après le premier chargement.
class QuranApi {
  QuranApi({required StorageService storage, http.Client? client})
      : _storage = storage,
        _client = client ?? http.Client();

  final StorageService _storage;
  final http.Client _client;

  static const _baseUrl = 'https://api.alquran.cloud/v1';
  static const _editions = 'quran-uthmani,en.transliteration,fr.hamidullah';

  /// Liste des 114 sourates, dans l'ordre du Coran.
  Future<List<SurahMeta>> fetchSurahList() async {
    final cached = _storage.readCachedSurahListJson();
    if (cached != null) {
      try {
        final list = jsonDecode(cached) as List<dynamic>;
        return list
            .map((e) => SurahMeta.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {
        // Cache corrompu : on retente un chargement réseau ci-dessous.
      }
    }

    http.Response response;
    try {
      response = await _client
          .get(Uri.parse('$_baseUrl/surah'))
          .timeout(const Duration(seconds: 10));
    } catch (_) {
      throw const QuranApiException(
        'Impossible de récupérer la liste des sourates. Vérifiez votre connexion.',
      );
    }
    if (response.statusCode != 200) {
      throw const QuranApiException(
        'Impossible de récupérer la liste des sourates. Vérifiez votre connexion.',
      );
    }

    try {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final data = json['data'] as List<dynamic>;
      final surahs = data
          .map((e) => SurahMeta.fromJson(e as Map<String, dynamic>))
          .toList();
      await _storage.writeCachedSurahListJson(
        jsonEncode(surahs.map((s) => s.toJson()).toList()),
      );
      return surahs;
    } catch (_) {
      throw const QuranApiException('Réponse invalide du service du Coran.');
    }
  }

  /// Détail complet d'une sourate (métadonnées + versets arabe/phonétique/français).
  Future<SurahDetail> fetchSurahDetail(int number) async {
    final cached = _storage.readCachedSurahDetailJson(number);
    if (cached != null) {
      try {
        return _parseSurahDetail(jsonDecode(cached) as Map<String, dynamic>);
      } catch (_) {
        // Cache corrompu : on retente un chargement réseau ci-dessous.
      }
    }

    http.Response response;
    try {
      response = await _client
          .get(Uri.parse('$_baseUrl/surah/$number/editions/$_editions'))
          .timeout(const Duration(seconds: 15));
    } catch (_) {
      throw const QuranApiException(
        'Impossible de récupérer cette sourate. Vérifiez votre connexion.',
      );
    }
    if (response.statusCode != 200) {
      throw const QuranApiException(
        'Impossible de récupérer cette sourate. Vérifiez votre connexion.',
      );
    }

    try {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final detail = _parseSurahDetail(json);
      await _storage.writeCachedSurahDetailJson(number, response.body);
      return detail;
    } catch (_) {
      throw const QuranApiException('Réponse invalide du service du Coran.');
    }
  }

  SurahDetail _parseSurahDetail(Map<String, dynamic> json) {
    final data = json['data'] as List<dynamic>;
    final arabicEdition = data[0] as Map<String, dynamic>;
    final transliterationEdition = data[1] as Map<String, dynamic>;
    final frenchEdition = data[2] as Map<String, dynamic>;

    final meta = SurahMeta(
      number: arabicEdition['number'] as int,
      nameArabic: arabicEdition['name'] as String,
      englishName: arabicEdition['englishName'] as String,
      englishNameTranslation: arabicEdition['englishNameTranslation'] as String,
      numberOfAyahs: arabicEdition['numberOfAyahs'] as int,
      revelationType: arabicEdition['revelationType'] as String,
    );

    final arabicAyahs = arabicEdition['ayahs'] as List<dynamic>;
    final transliterationAyahs = transliterationEdition['ayahs'] as List<dynamic>;
    final frenchAyahs = frenchEdition['ayahs'] as List<dynamic>;

    final ayahs = <Ayah>[];
    for (var i = 0; i < arabicAyahs.length; i++) {
      final arabic = arabicAyahs[i] as Map<String, dynamic>;
      final transliteration = transliterationAyahs[i] as Map<String, dynamic>;
      final french = frenchAyahs[i] as Map<String, dynamic>;
      ayahs.add(Ayah(
        numberInSurah: arabic['numberInSurah'] as int,
        arabicText: arabic['text'] as String,
        transliterationText: transliteration['text'] as String,
        frenchText: french['text'] as String,
      ));
    }

    return SurahDetail(meta: meta, ayahs: ayahs);
  }
}
