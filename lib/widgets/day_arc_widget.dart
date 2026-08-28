import 'package:flutter/material.dart';

import '../models/prayer_times_model.dart';
import '../theme/app_colors.dart';
import '../utils/date_format_fr.dart';
import '../utils/prayer_time_utils.dart';
import 'day_arc_painter.dart';

/// Élément signature de l'app : l'arc représentant la trajectoire du jour
/// de Fajr à Isha, avec les 6 horaires positionnés dessus et un repère
/// soleil/lune qui se déplace en direct.
class DayArcWidget extends StatelessWidget {
  const DayArcWidget({
    super.key,
    required this.times,
    required this.now,
    this.highlighted,
  });

  final PrayerTimes times;
  final DateTime now;
  final PrayerName? highlighted;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        const bottomPadding = 44.0;
        const horizontalPadding = 24.0;
        final radius = (width - 2 * horizontalPadding) / 2;
        final height = radius + bottomPadding + 20;
        final center = Offset(width / 2, height - bottomPadding);

        final labels = <Widget>[];
        for (final entry in times.orderedEntries) {
          final t = arcFraction(entry.value, times.fajr, times.isha);
          final position = positionForFraction(t, center, radius);
          final isHighlighted = entry.key == highlighted;
          labels.add(
            Positioned(
              left: position.dx - 28,
              top: position.dy + 10,
              width: 56,
              child: Column(
                children: [
                  Text(
                    entry.key.labelFr,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isHighlighted
                              ? AppColors.goldLight
                              : AppColors.cream.withValues(alpha: 0.7),
                          fontWeight:
                              isHighlighted ? FontWeight.w700 : FontWeight.normal,
                        ),
                  ),
                  Text(
                    formatTimeFr(entry.value),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isHighlighted
                              ? AppColors.goldLight
                              : AppColors.cream.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
          );
        }

        return SizedBox(
          width: width,
          height: height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              CustomPaint(
                size: Size(width, height),
                painter: DayArcPainter(
                  times: times,
                  now: now,
                  highlighted: highlighted,
                  center: center,
                  radius: radius,
                ),
              ),
              ...labels,
            ],
          ),
        );
      },
    );
  }
}
