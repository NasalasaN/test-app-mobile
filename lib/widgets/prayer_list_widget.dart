import 'package:flutter/material.dart';

import '../models/prayer_times_model.dart';
import '../theme/app_colors.dart';
import '../utils/date_format_fr.dart';

/// Liste des 6 horaires du jour, avec la prochaine prière mise en avant.
class PrayerListWidget extends StatelessWidget {
  const PrayerListWidget({
    super.key,
    required this.times,
    required this.highlighted,
  });

  final PrayerTimes times;
  final PrayerName? highlighted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            for (final entry in times.orderedEntries)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      entry.key.labelFr,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: entry.key == highlighted
                            ? AppColors.goldLight
                            : AppColors.cream,
                        fontWeight: entry.key == highlighted
                            ? FontWeight.w700
                            : FontWeight.normal,
                      ),
                    ),
                    Text(
                      formatTimeFr(entry.value),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: entry.key == highlighted
                            ? AppColors.goldLight
                            : AppColors.cream,
                        fontWeight: entry.key == highlighted
                            ? FontWeight.w700
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
