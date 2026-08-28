import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:workmanager/workmanager.dart';

import 'providers/location_provider.dart';
import 'providers/prayer_times_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/weather_provider.dart';
import 'screens/home_screen.dart';
import 'services/api/geocoding_api.dart';
import 'services/api/prayer_times_api.dart';
import 'services/api/weather_api.dart';
import 'services/location_service.dart';
import 'services/notifications/background_refresh.dart';
import 'services/notifications/notification_service.dart';
import 'services/storage/storage_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR', null);

  final storage = await StorageService.create();
  await NotificationService.instance.init();

  await Workmanager().initialize(backgroundRefreshDispatcher);
  await Workmanager().registerPeriodicTask(
    backgroundRefreshUniqueName,
    backgroundRefreshTaskName,
    frequency: const Duration(hours: 6),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    constraints: Constraints(networkType: NetworkType.connected),
  );

  runApp(MiqatApp(storage: storage));
}

class MiqatApp extends StatelessWidget {
  const MiqatApp({super.key, required this.storage});

  final StorageService storage;

  @override
  Widget build(BuildContext context) {
    final geocodingApi = GeocodingApi();
    final prayerTimesApi = PrayerTimesApi();
    final weatherApi = WeatherApi();
    final locationService = LocationService();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<LocationProvider>(
          create: (_) => LocationProvider(
            locationService: locationService,
            geocodingApi: geocodingApi,
            storage: storage,
          )..init(),
        ),
        ChangeNotifierProvider<SettingsProvider>(
          create: (_) => SettingsProvider(storage: storage)..load(),
        ),
        ChangeNotifierProxyProvider2<LocationProvider, SettingsProvider,
            PrayerTimesProvider>(
          create: (_) => PrayerTimesProvider(api: prayerTimesApi),
          update: (_, locationProvider, settingsProvider, provider) {
            final prayerTimesProvider =
                provider ?? PrayerTimesProvider(api: prayerTimesApi);
            final location = locationProvider.location;
            if (location != null) {
              prayerTimesProvider.syncWith(
                location,
                settingsProvider.calculationMethodId,
                settingsProvider.notificationSettings,
              );
            }
            return prayerTimesProvider;
          },
        ),
        ChangeNotifierProxyProvider<LocationProvider, WeatherProvider>(
          create: (_) => WeatherProvider(api: weatherApi),
          update: (_, locationProvider, provider) {
            final weatherProvider = provider ?? WeatherProvider(api: weatherApi);
            final location = locationProvider.location;
            if (location != null) {
              weatherProvider.syncWith(location);
            }
            return weatherProvider;
          },
        ),
      ],
      child: MaterialApp(
        title: 'Miqat',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: const HomeScreen(),
      ),
    );
  }
}
