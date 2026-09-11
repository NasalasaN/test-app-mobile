import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/ambiance_model.dart';
import '../providers/settings_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/animated_background.dart';
import 'home_screen.dart';
import 'map_screen.dart';
import 'qibla_screen.dart';
import 'quran_surah_list_screen.dart';

/// Écran racine : barre d'onglets en bas entre les horaires de prière, la
/// Qibla et le Coran, avec un fond animé (ambiance) commun aux trois.
class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  int _index = 0;

  static const _screens = [
    HomeScreen(),
    QiblaScreen(),
    MapScreen(),
    QuranSurahListScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final ambiance =
        context.select<SettingsProvider, BackgroundAmbiance>((s) => s.ambiance);

    return Scaffold(
      backgroundColor: AppColors.nightBlue,
      body: Stack(
        children: [
          Positioned.fill(child: AnimatedBackground(ambiance: ambiance)),
          Positioned.fill(child: IndexedStack(index: _index, children: _screens)),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (index) => setState(() => _index = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.access_time), label: 'Horaires'),
          NavigationDestination(icon: Icon(Icons.explore), label: 'Qibla'),
          NavigationDestination(icon: Icon(Icons.map), label: 'Carte'),
          NavigationDestination(icon: Icon(Icons.menu_book), label: 'Coran'),
        ],
      ),
    );
  }
}
