import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/load_status.dart';
import '../providers/weather_provider.dart';
import '../theme/app_colors.dart';
import '../utils/weather_code_mapper.dart';

/// Carte météo : température, ressenti, humidité, vent, icône/description.
/// Gère son propre état de chargement/erreur, indépendamment du reste.
class WeatherCardWidget extends StatelessWidget {
  const WeatherCardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final weather = context.watch<WeatherProvider>();
    final theme = Theme.of(context);

    Widget content;
    switch (weather.status) {
      case LoadStatus.initial:
      case LoadStatus.loading:
        content = const Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
        break;
      case LoadStatus.error:
        content = Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            weather.errorMessageFr ?? 'Météo indisponible.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.cream.withValues(alpha: 0.7),
            ),
          ),
        );
        break;
      case LoadStatus.loaded:
        final data = weather.data!;
        final info = weatherInfoForCode(data.weatherCode);
        content = Row(
          children: [
            Icon(info.icon, size: 40, color: AppColors.goldLight),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${data.temperature.round()}°C — ${info.label}',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Ressenti ${data.apparentTemperature.round()}°C · '
                    'Humidité ${data.humidity}% · '
                    'Vent ${data.windSpeedKmh.round()} km/h',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.cream.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
        break;
    }

    return Card(
      child: Padding(padding: const EdgeInsets.all(16), child: content),
    );
  }
}
