/// État de chargement générique partagé par les providers, pour que
/// chaque section de l'UI (localisation, horaires, météo) gère son propre
/// chargement/erreur indépendamment.
enum LoadStatus { initial, loading, loaded, error }
