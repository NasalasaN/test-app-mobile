import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/location_provider.dart';
import '../services/storage/storage_service.dart';
import '../theme/app_colors.dart';
import 'root_screen.dart';

/// Écran affiché une seule fois, au tout premier lancement, expliquant
/// pourquoi l'app va demander la localisation et les notifications avant
/// que ces demandes système n'apparaissent.
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              const Icon(Icons.mosque, size: 72, color: AppColors.goldLight),
              const SizedBox(height: 24),
              Text(
                'Bienvenue sur Miqat',
                style: theme.textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              _ExplanationTile(
                icon: Icons.location_on,
                title: 'Localisation',
                description:
                    'Utilisée pour calculer les horaires de prière, la Qibla et la météo de votre ville. '
                    'Vous pourrez toujours choisir une ville manuellement à la place.',
              ),
              const SizedBox(height: 20),
              _ExplanationTile(
                icon: Icons.notifications_active,
                title: 'Notifications',
                description:
                    'Pour vous alerter à l\'heure de chaque prière, même l\'app fermée. '
                    'Vous choisirez ensuite lesquelles activer dans les réglages.',
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _continue(context),
                  child: const Text('Commencer'),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _continue(BuildContext context) async {
    final storage = context.read<StorageService>();
    await storage.writeHasSeenOnboarding();
    if (!context.mounted) return;
    // Déclenche la géolocalisation maintenant que l'utilisateur comprend
    // pourquoi elle est demandée.
    unawaited(context.read<LocationProvider>().init());
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const RootScreen()),
    );
  }
}

class _ExplanationTile extends StatelessWidget {
  const _ExplanationTile({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.teal, size: 28),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.cream.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
