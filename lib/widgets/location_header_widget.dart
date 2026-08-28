import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/location_model.dart';
import '../providers/load_status.dart';
import '../providers/location_provider.dart';
import '../screens/city_search_screen.dart';
import '../theme/app_colors.dart';

/// En-tête affichant la localisation courante, avec accès à la recherche
/// manuelle de ville et à un bouton pour réessayer la géolocalisation.
class LocationHeaderWidget extends StatelessWidget {
  const LocationHeaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final locationProvider = context.watch<LocationProvider>();
    final theme = Theme.of(context);

    Widget content;
    switch (locationProvider.status) {
      case LoadStatus.loading:
        content = Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Text(
              'Localisation en cours…',
              style: theme.textTheme.titleMedium,
            ),
          ],
        );
        break;
      case LoadStatus.error:
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              locationProvider.errorMessageFr ?? 'Localisation indisponible.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.cream.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton(
                  onPressed: () => _openCitySearch(context),
                  child: const Text('Choisir une ville'),
                ),
                if (!locationProvider.permissionPermanentlyDenied)
                  TextButton(
                    onPressed: () => locationProvider.retry(),
                    child: const Text('Réessayer la géolocalisation'),
                  ),
              ],
            ),
          ],
        );
        break;
      case LoadStatus.initial:
      case LoadStatus.loaded:
        final location = locationProvider.location;
        content = InkWell(
          onTap: () => _openCitySearch(context),
          child: Row(
            children: [
              const Icon(Icons.location_on, color: AppColors.goldLight, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  location != null
                      ? [location.cityName, location.country]
                          .whereType<String>()
                          .where((e) => e.isNotEmpty)
                          .join(', ')
                      : 'Choisir une ville',
                  style: theme.textTheme.titleMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.edit, color: AppColors.cream, size: 16),
            ],
          ),
        );
        break;
    }

    return content;
  }

  Future<void> _openCitySearch(BuildContext context) async {
    final result = await Navigator.of(context).push<Location>(
      MaterialPageRoute(builder: (_) => const CitySearchScreen()),
    );
    if (result != null && context.mounted) {
      context.read<LocationProvider>().setManualLocation(result);
    }
  }
}
