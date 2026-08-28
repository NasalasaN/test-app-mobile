import 'package:intl/intl.dart';

String formatTimeFr(DateTime dt) => DateFormat('HH:mm', 'fr_FR').format(dt);

String formatDateLongFr(DateTime dt) =>
    DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(dt);

String formatCountdown(Duration duration) {
  final clamped = duration.isNegative ? Duration.zero : duration;
  final hours = clamped.inHours.toString().padLeft(2, '0');
  final minutes = (clamped.inMinutes % 60).toString().padLeft(2, '0');
  final seconds = (clamped.inSeconds % 60).toString().padLeft(2, '0');
  return '$hours:$minutes:$seconds';
}
