import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_exception.dart';
import '../models/prayer_times_model.dart';
import '../providers/location_provider.dart';
import '../providers/settings_provider.dart';
import '../services/api/prayer_times_api.dart';
import '../theme/app_colors.dart';
import '../utils/date_format_fr.dart';
import '../widgets/error_retry_view.dart';

const _daysAhead = 7;

/// Affiche les horaires de prière des prochains jours (en plus
/// d'aujourd'hui), pour planifier à l'avance.
class UpcomingDaysScreen extends StatefulWidget {
  const UpcomingDaysScreen({super.key});

  @override
  State<UpcomingDaysScreen> createState() => _UpcomingDaysScreenState();
}

class _UpcomingDaysScreenState extends State<UpcomingDaysScreen> {
  final _api = PrayerTimesApi();
  late Future<List<PrayerTimes>> _future;

  @override
  void initState() {
    super.initState();
    _future = _fetchUpcomingDays();
  }

  Future<List<PrayerTimes>> _fetchUpcomingDays() async {
    final location = context.read<LocationProvider>().location;
    final methodId = context.read<SettingsProvider>().calculationMethodId;
    if (location == null) return [];

    final results = <PrayerTimes>[];
    for (var i = 1; i <= _daysAhead; i++) {
      final date = DateTime.now().add(Duration(days: i));
      final times = await _api.fetchTimings(
        latitude: location.latitude,
        longitude: location.longitude,
        forDate: date,
        calculationMethodId: methodId,
      );
      results.add(times);
    }
    return results;
  }

  @override
  Widget build(BuildContext context) {
    final location = context.watch<LocationProvider>().location;

    return Scaffold(
      appBar: AppBar(title: const Text('Prochains jours')),
      body: location == null
          ? const Center(child: Text('Choisissez une ville pour voir les horaires.'))
          : FutureBuilder<List<PrayerTimes>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return ErrorRetryView(
                    message: friendlyErrorMessage(
                      snapshot.error!,
                      fallback: 'Erreur inattendue lors du chargement des horaires.',
                    ),
                    onRetry: () => setState(() {
                      _future = _fetchUpcomingDays();
                    }),
                  );
                }

                final days = snapshot.data ?? [];
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: days.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) => _DayCard(times: days[index]),
                );
              },
            ),
    );
  }
}

class _DayCard extends StatelessWidget {
  const _DayCard({required this.times});

  final PrayerTimes times;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(formatDateLongFr(times.date), style: theme.textTheme.titleMedium),
            Text(
              times.hijriDateLabel,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.cream.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                for (final entry in times.orderedEntries)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.key.labelFr,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.cream.withValues(alpha: 0.7),
                        ),
                      ),
                      Text(formatTimeFr(entry.value), style: theme.textTheme.titleMedium),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
