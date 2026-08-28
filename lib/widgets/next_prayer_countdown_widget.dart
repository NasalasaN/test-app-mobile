import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../models/prayer_times_model.dart';
import '../theme/app_colors.dart';
import '../utils/date_format_fr.dart';

/// Affiche le nom de la prochaine prière et le compte à rebours en direct.
class NextPrayerCountdownWidget extends StatelessWidget {
  const NextPrayerCountdownWidget({
    super.key,
    required this.prayerName,
    required this.remaining,
    required this.isEstimatedTomorrow,
  });

  final PrayerName prayerName;
  final Duration remaining;
  final bool isEstimatedTomorrow;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          'Prochaine prière',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.cream.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 4),
        Text(prayerName.labelFr, style: theme.textTheme.headlineMedium),
        const SizedBox(height: 4),
        Text(
          formatCountdown(remaining),
          style: theme.textTheme.headlineLarge?.copyWith(
            fontFeatures: const [ui.FontFeature.tabularFigures()],
          ),
        ),
        if (isEstimatedTomorrow)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '(estimation, en attente des horaires de demain)',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.cream.withValues(alpha: 0.5),
              ),
            ),
          ),
      ],
    );
  }
}
