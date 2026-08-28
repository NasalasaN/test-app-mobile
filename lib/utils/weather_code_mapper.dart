import 'package:flutter/material.dart';

class WeatherInfo {
  final IconData icon;
  final String label;

  const WeatherInfo(this.icon, this.label);
}

/// Correspondance code météo WMO (renvoyé par Open-Meteo) -> icône + libellé fr.
WeatherInfo weatherInfoForCode(int code) {
  switch (code) {
    case 0:
      return const WeatherInfo(Icons.wb_sunny, 'Ciel dégagé');
    case 1:
      return const WeatherInfo(Icons.wb_sunny_outlined, 'Principalement clair');
    case 2:
      return const WeatherInfo(Icons.cloud_queue, 'Partiellement nuageux');
    case 3:
      return const WeatherInfo(Icons.cloud, 'Couvert');
    case 45:
    case 48:
      return const WeatherInfo(Icons.foggy, 'Brouillard');
    case 51:
    case 53:
    case 55:
      return const WeatherInfo(Icons.grain, 'Bruine');
    case 56:
    case 57:
      return const WeatherInfo(Icons.grain, 'Bruine verglaçante');
    case 61:
    case 63:
    case 65:
      return const WeatherInfo(Icons.water_drop, 'Pluie');
    case 66:
    case 67:
      return const WeatherInfo(Icons.water_drop, 'Pluie verglaçante');
    case 71:
    case 73:
    case 75:
      return const WeatherInfo(Icons.ac_unit, 'Neige');
    case 77:
      return const WeatherInfo(Icons.ac_unit, 'Grains de neige');
    case 80:
    case 81:
    case 82:
      return const WeatherInfo(Icons.water_drop, 'Averses de pluie');
    case 85:
    case 86:
      return const WeatherInfo(Icons.ac_unit, 'Averses de neige');
    case 95:
      return const WeatherInfo(Icons.thunderstorm, 'Orage');
    case 96:
    case 99:
      return const WeatherInfo(Icons.thunderstorm, 'Orage avec grêle');
    default:
      return const WeatherInfo(Icons.help_outline, 'Conditions inconnues');
  }
}
