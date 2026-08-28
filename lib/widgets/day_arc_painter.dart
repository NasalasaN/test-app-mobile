import 'dart:math';

import 'package:flutter/material.dart';

import '../models/prayer_times_model.dart';
import '../theme/app_colors.dart';
import '../utils/prayer_time_utils.dart';

/// Position (0.0 à 1.0) le long de l'arc -> angle en radians. t=0 -> point
/// gauche (Fajr, 180°), t=0.5 -> sommet (270° dans la convention canvas où
/// l'angle croît dans le sens horaire), t=1 -> point droit (Isha, 360°).
double angleForFraction(double t) => pi * (1 + t);

/// Position cartésienne sur l'arc pour une fraction [t], centré sur
/// [center] avec un rayon [radius].
Offset positionForFraction(double t, Offset center, double radius) {
  final angle = angleForFraction(t);
  return center + Offset(radius * cos(angle), radius * sin(angle));
}

/// Dessine le tracé de l'arc du jour (Fajr -> Isha), les 6 repères de
/// prière et le marqueur soleil/lune représentant l'heure actuelle.
class DayArcPainter extends CustomPainter {
  DayArcPainter({
    required this.times,
    required this.now,
    required this.highlighted,
    required this.center,
    required this.radius,
  });

  final PrayerTimes times;
  final DateTime now;
  final PrayerName? highlighted;
  final Offset center;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final trackPaint = Paint()
      ..color = AppColors.teal.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi,
      pi,
      false,
      trackPaint,
    );

    for (final entry in times.orderedEntries) {
      final t = arcFraction(entry.value, times.fajr, times.isha);
      final position = positionForFraction(t, center, radius);
      final isHighlighted = entry.key == highlighted;

      if (isHighlighted) {
        final glowPaint = Paint()
          ..color = AppColors.gold.withValues(alpha: 0.25)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(position, 14, glowPaint);
      }

      final dotPaint = Paint()
        ..color = isHighlighted ? AppColors.goldLight : AppColors.gold
        ..style = PaintingStyle.fill;
      canvas.drawCircle(position, isHighlighted ? 8 : 5, dotPaint);
    }

    final tNow = arcFraction(now, times.fajr, times.isha);
    final markerPosition = positionForFraction(tNow, center, radius);
    final isDaytime = now.isAfter(times.sunrise) && now.isBefore(times.maghrib);

    final markerPaint = Paint()
      ..color = isDaytime ? AppColors.goldLight : AppColors.cream
      ..style = PaintingStyle.fill;
    canvas.drawCircle(markerPosition, 14, markerPaint);

    _drawIcon(
      canvas,
      isDaytime ? Icons.wb_sunny : Icons.nightlight_round,
      markerPosition,
      AppColors.nightBlue,
    );
  }

  void _drawIcon(Canvas canvas, IconData icon, Offset position, Color color) {
    final textPainter = TextPainter(textDirection: TextDirection.ltr)
      ..text = TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: 16,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: color,
        ),
      )
      ..layout();
    textPainter.paint(
      canvas,
      position - Offset(textPainter.width / 2, textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant DayArcPainter oldDelegate) {
    return oldDelegate.times != times ||
        oldDelegate.now != now ||
        oldDelegate.highlighted != highlighted ||
        oldDelegate.center != center ||
        oldDelegate.radius != radius;
  }
}
