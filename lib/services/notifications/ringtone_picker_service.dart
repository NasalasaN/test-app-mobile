import 'package:flutter/services.dart';

/// Accès au sélecteur de sonnerie natif d'Android (RingtoneManager), qui
/// permet à la fois de choisir un son prédéfini du système et d'importer un
/// fichier audio depuis l'appareil (bouton "Ajouter" du sélecteur système).
/// Non disponible sur iOS (limitation de la plateforme).
class RingtonePickerService {
  static const _channel = MethodChannel('miqat/ringtone_picker');

  /// Ouvre le sélecteur natif et retourne l'URI (`content://…`) du son
  /// choisi, ou `null` si l'utilisateur a annulé ou choisi le son système.
  Future<String?> pickNotificationSound({String? currentUri}) async {
    try {
      return await _channel.invokeMethod<String>(
        'pickNotificationSound',
        {'currentUri': currentUri},
      );
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  /// Retourne le nom lisible d'un son à partir de son URI, ou `null` si
  /// indisponible.
  Future<String?> getRingtoneTitle(String uri) async {
    try {
      return await _channel.invokeMethod<String>('getRingtoneTitle', {'uri': uri});
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }
}
