/// Métadonnées d'une sourate (liste des 114 sourates).
class SurahMeta {
  final int number;
  final String nameArabic;
  final String englishName;
  final String englishNameTranslation;
  final int numberOfAyahs;
  final String revelationType;

  const SurahMeta({
    required this.number,
    required this.nameArabic,
    required this.englishName,
    required this.englishNameTranslation,
    required this.numberOfAyahs,
    required this.revelationType,
  });

  factory SurahMeta.fromJson(Map<String, dynamic> json) => SurahMeta(
        number: json['number'] as int,
        nameArabic: json['name'] as String,
        englishName: json['englishName'] as String,
        englishNameTranslation: json['englishNameTranslation'] as String,
        numberOfAyahs: json['numberOfAyahs'] as int,
        revelationType: json['revelationType'] as String,
      );

  Map<String, dynamic> toJson() => {
        'number': number,
        'name': nameArabic,
        'englishName': englishName,
        'englishNameTranslation': englishNameTranslation,
        'numberOfAyahs': numberOfAyahs,
        'revelationType': revelationType,
      };
}

/// Un verset avec ses trois représentations : arabe, phonétique (translittération), français.
class Ayah {
  final int numberInSurah;
  final String arabicText;
  final String transliterationText;
  final String frenchText;

  const Ayah({
    required this.numberInSurah,
    required this.arabicText,
    required this.transliterationText,
    required this.frenchText,
  });
}

/// Détail complet d'une sourate : ses métadonnées et tous ses versets.
class SurahDetail {
  final SurahMeta meta;
  final List<Ayah> ayahs;

  const SurahDetail({required this.meta, required this.ayahs});
}
