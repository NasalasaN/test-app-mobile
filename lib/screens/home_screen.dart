import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/load_status.dart';
import '../providers/location_provider.dart';
import '../providers/prayer_times_provider.dart';
import '../providers/settings_provider.dart';
import '../services/notifications/notification_service.dart';
import '../theme/app_colors.dart';
import '../utils/date_format_fr.dart';
import '../widgets/day_arc_widget.dart';
import '../widgets/location_header_widget.dart';
import '../widgets/next_prayer_countdown_widget.dart';
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
    final prayerTimes = context.watch<PrayerTimesProvider>();

    if (prayerTimes.status == LoadStatus.loaded && !_permissionsRequested) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _maybeRequestNotificationPermissions();
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Miqat'),
        actions: [
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
            _buildPrayerSection(context, prayerTimes),
            const SizedBox(height: 24),
            const WeatherCardWidget(),
          ],
        ),
      ),
    );
  }

  Widget _buildPrayerSection(
    BuildContext context,
    PrayerTimesProvider prayerTimes,
  ) {
    if (prayerTimes.status == LoadStatus.loading && prayerTimes.today == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (prayerTimes.today == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Text(
          prayerTimes.errorMessageFr ??
              'Choisissez une ville pour afficher les horaires de prière.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.cream.withValues(alpha: 0.8),
              ),
        ),
      );
    }

    final times = prayerTimes.today!;
    final next = prayerTimes.next;

    return Column(
      children: [
        if (prayerTimes.status == LoadStatus.error)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              prayerTimes.errorMessageFr ?? '',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.cream.withValues(alpha: 0.6),
                  ),
            ),
          ),
        Text(times.hijriDateLabel, style: Theme.of(context).textTheme.bodyMedium),
        Text(
          formatDateLongFr(DateTime.now()),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.cream.withValues(alpha: 0.7),
              ),
        ),
        const SizedBox(height: 16),
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
        const SizedBox(height: 24),
        PrayerListWidget(times: times, highlighted: next?.name),
      ],
    );
  }
}
