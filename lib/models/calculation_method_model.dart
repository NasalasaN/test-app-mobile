class CalculationMethod {
  final int id;
  final String label;

  const CalculationMethod(this.id, this.label);

  /// Méthodes de calcul courantes proposées dans le sélecteur.
  static const List<CalculationMethod> all = [
    CalculationMethod(21, 'Maroc (Ministère des Habous)'),
    CalculationMethod(12, 'France'),
    CalculationMethod(3, 'Ligue islamique mondiale'),
    CalculationMethod(5, 'Égypte'),
    CalculationMethod(4, 'Umm Al-Qura'),
    CalculationMethod(2, 'ISNA'),
    CalculationMethod(19, 'Algérie'),
    CalculationMethod(18, 'Tunisie'),
  ];

  static const int defaultMethodId = 21;

  static CalculationMethod byId(int id) =>
      all.firstWhere((m) => m.id == id, orElse: () => all.first);
}
