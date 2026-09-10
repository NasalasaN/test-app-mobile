import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/ambiance_model.dart';
import '../models/calculation_method_model.dart';
import '../models/prayer_times_model.dart';
import '../providers/prayer_times_provider.dart';
import '../providers/settings_provider.dart';
import '../services/notifications/ringtone_picker_service.dart';

/// Réglages : méthode de calcul des horaires et préférences de
/// notification (prières à notifier, son).
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final notif = settings.notificationSettings;

    return Scaffold(
      appBar: AppBar(title: const Text('Réglages')),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Méthode de calcul',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          RadioGroup<int>(
            groupValue: settings.calculationMethodId,
            onChanged: (id) {
              if (id != null) settings.setCalculationMethodId(id);
            },
            child: Column(
              children: [
                for (final method in CalculationMethod.all)
                  RadioListTile<int>(
                    title: Text(method.label),
                    value: method.id,
                  ),
              ],
            ),
          ),
          const Divider(height: 32),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              'Notifications',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          SwitchListTile(
            title: const Text('Activer les notifications'),
            value: notif.globalEnabled,
            onChanged: (enabled) => _updateAndReschedule(
              context,
              () => settings.setGlobalEnabled(enabled),
            ),
          ),
          if (notif.globalEnabled) ...[
            for (final prayer in PrayerName.values)
              CheckboxListTile(
                title: Text(prayer.labelFr),
                value: notif.enabledPrayers[prayer] ?? false,
                onChanged: (enabled) => _updateAndReschedule(
                  context,
                  () => settings.setPrayerEnabled(prayer, enabled ?? false),
                ),
              ),
            const Divider(height: 32),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                'Son de notification',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: Icon(
                notif.customSoundUri == null
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
              ),
              title: const Text('Son système par défaut'),
              onTap: () => _updateAndReschedule(
                context,
                () => settings.clearCustomSound(),
              ),
            ),
            ListTile(
              leading: Icon(
                notif.customSoundUri != null
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
              ),
              title: Text(
                notif.customSoundUri == null
                    ? 'Choisir un son…'
                    : (notif.customSoundTitle ?? 'Son personnalisé'),
              ),
              subtitle: defaultTargetPlatform == TargetPlatform.iOS
                  ? const Text(
                      'Indisponible sur iOS — utilise le son système par défaut.',
                    )
                  : const Text(
                      'Sons prédéfinis du téléphone, ou importez votre propre fichier audio.',
                    ),
              trailing: const Icon(Icons.chevron_right),
              enabled: defaultTargetPlatform != TargetPlatform.iOS,
              onTap: () async {
                final picker = RingtonePickerService();
                final uri = await picker.pickNotificationSound(
                  currentUri: notif.customSoundUri,
                );
                if (uri == null) return;
                final title = await picker.getRingtoneTitle(uri);
                if (!context.mounted) return;
                await _updateAndReschedule(
                  context,
                  () => settings.setCustomSound(uri, title),
                );
              },
            ),
          ],
          const Divider(height: 32),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              'Ambiance',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          RadioGroup<BackgroundAmbiance>(
            groupValue: settings.ambiance,
            onChanged: (value) {
              if (value != null) settings.setAmbiance(value);
            },
            child: Column(
              children: [
                for (final ambiance in BackgroundAmbiance.values)
                  RadioListTile<BackgroundAmbiance>(
                    title: Text(ambiance.labelFr),
                    value: ambiance,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateAndReschedule(
    BuildContext context,
    Future<void> Function() update,
  ) async {
    final prayerTimesProvider = context.read<PrayerTimesProvider>();
    await update();
    if (!context.mounted) return;
    final settings = context.read<SettingsProvider>();
    await prayerTimesProvider
        .rescheduleNotificationsOnly(settings.notificationSettings);
  }
}
