import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/prayer_times_model.dart';
import '../providers/prayer_times_provider.dart';
import 'day_arc_widget.dart';
import 'next_prayer_countdown_widget.dart';

/// Regroupe l'arc du jour et le compte à rebours, les deux seuls éléments
/// qui doivent se redessiner chaque seconde. Isolé dans son propre widget
/// pour que le reste de l'écran (météo, liste des horaires, en-tête) ne se
/// reconstruise pas inutilement à chaque tic du compte à rebours.
class LivePrayerProgressWidget extends StatelessWidget {
  const LivePrayerProgressWidget({super.key, required this.times});

  final PrayerTimes times;

  @override
  Widget build(BuildContext context) {
    final prayerTimes = context.watch<PrayerTimesProvider>();
    final next = prayerTimes.next;

    return Column(
      children: [
        DayArcWidget(
          times: times,
          now: DateTime.now(),
          highlighted: next?.name,
        ),
        const SizedBox(height: 16),
        if (next != null)
          NextPrayerCountdownWidget(
            prayerName: next.name,
            remaining: prayerTimes.remaining ?? Duration.zero,
            isEstimatedTomorrow: next.isEstimatedTomorrow,
          ),
      ],
    );
  }
}
