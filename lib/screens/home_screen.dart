import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/prayer_times_model.dart';
import '../providers/load_status.dart';
import '../providers/location_provider.dart';
import '../providers/prayer_times_provider.dart';
import '../providers/settings_provider.dart';
import '../services/notifications/notification_service.dart';
import '../theme/app_colors.dart';
import '../utils/date_format_fr.dart';
import '../widgets/live_prayer_progress_widget.dart';
import '../widgets/location_header_widget.dart';
import '../widgets/prayer_list_widget.dart';
import '../widgets/weather_card_widget.dart';
import 'settings_screen.dart';
import 'upcoming_days_screen.dart';

/// Écran principal : localisation, arc du jour + prochaine prière +
/// compte à rebours, liste des horaires, météo, accès aux réglages.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  bool _permissionsRequested = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final settings = context.read<SettingsProvider>();
      context
          .read<PrayerTimesProvider>()
          .rescheduleNotificationsOnly(settings.notificationSettings);
    }
  }

  Future<void> _maybeRequestNotificationPermissions() async {
    if (_permissionsRequested) return;
    _permissionsRequested = true;
    await NotificationService.instance.requestPermissions();
    if (!mounted) return;
    final settings = context.read<SettingsProvider>();
    await context
        .read<PrayerTimesProvider>()
        .rescheduleNotificationsOnly(settings.notificationSettings);
  }

  @override
  Widget build(BuildContext context) {
    // `select` plutôt que `watch` : cet écran ne doit se reconstruire que
    // lorsque le statut ou les horaires changent réellement, pas à chaque
    // tic du compte à rebours (1x/seconde) — ce dernier n'est écouté que
    // par LivePrayerProgressWidget, plus bas dans l'arbre.
    final status = context.select<PrayerTimesProvider, LoadStatus>((p) => p.status);
    final today = context.select<PrayerTimesProvider, PrayerTimes?>((p) => p.today);
    final errorMessageFr =
        context.select<PrayerTimesProvider, String?>((p) => p.errorMessageFr);
    final nextName =
        context.select<PrayerTimesProvider, PrayerName?>((p) => p.next?.name);

    if (status == LoadStatus.loaded && !_permissionsRequested) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _maybeRequestNotificationPermissions();
      });
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Miqat'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Partager les horaires',
            onPressed: today == null ? null : () => _shareTodaysTimes(context, today),
          ),
          IconButton(
            icon: const Icon(Icons.calendar_month),
            tooltip: 'Prochains jours',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const UpcomingDaysScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          final location = context.read<LocationProvider>().location;
          final settings = context.read<SettingsProvider>();
          if (location != null) {
            await context.read<PrayerTimesProvider>().syncWith(
                  location,
                  settings.calculationMethodId,
                  settings.notificationSettings,
                );
          }
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const LocationHeaderWidget(),
            const SizedBox(height: 24),
            _buildPrayerSection(
              context,
              status: status,
              today: today,
              errorMessageFr: errorMessageFr,
              nextName: nextName,
            ),
            const SizedBox(height: 24),
            const WeatherCardWidget(),
          ],
        ),
      ),
    );
  }

  void _shareTodaysTimes(BuildContext context, PrayerTimes times) {
    final location = context.read<LocationProvider>().location;
    final cityLabel = location != null
        ? [location.cityName, location.country]
            .whereType<String>()
            .where((e) => e.isNotEmpty)
            .join(', ')
        : null;

    final buffer = StringBuffer()
      ..writeln('Horaires de prière${cityLabel != null ? ' — $cityLabel' : ''}')
      ..writeln(formatDateLongFr(DateTime.now()))
      ..writeln(times.hijriDateLabel)
      ..writeln();
    for (final entry in times.orderedEntries) {
      buffer.writeln('${entry.key.labelFr} : ${formatTimeFr(entry.value)}');
    }
    buffer.writeln('\nvia l\'app Miqat');

    SharePlus.instance.share(ShareParams(text: buffer.toString()));
  }

  Widget _buildPrayerSection(
    BuildContext context, {
    required LoadStatus status,
    required PrayerTimes? today,
    required String? errorMessageFr,
    required PrayerName? nextName,
  }) {
    if (status == LoadStatus.loading && today == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (today == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Text(
          errorMessageFr ?? 'Choisissez une ville pour afficher les horaires de prière.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.cream.withValues(alpha: 0.8),
              ),
        ),
      );
    }

    return Column(
      children: [
        if (status == LoadStatus.error)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              errorMessageFr ?? '',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.cream.withValues(alpha: 0.6),
                  ),
            ),
          ),
        Text(today.hijriDateLabel, style: Theme.of(context).textTheme.bodyMedium),
        Text(
          formatDateLongFr(DateTime.now()),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.cream.withValues(alpha: 0.7),
              ),
        ),
        const SizedBox(height: 16),
        LivePrayerProgressWidget(times: today),
        const SizedBox(height: 24),
        PrayerListWidget(times: today, highlighted: nextName),
      ],
    );
  }
}
