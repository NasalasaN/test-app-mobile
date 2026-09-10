import 'package:flutter/material.dart';

import 'home_screen.dart';
import 'qibla_screen.dart';
import 'quran_surah_list_screen.dart';

/// Écran racine : barre d'onglets en bas entre les horaires de prière et
/// le Coran.
class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  int _index = 0;

  static const _screens = [HomeScreen(), QiblaScreen(), QuranSurahListScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (index) => setState(() => _index = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.access_time), label: 'Horaires'),
          NavigationDestination(icon: Icon(Icons.explore), label: 'Qibla'),
          NavigationDestination(icon: Icon(Icons.menu_book), label: 'Coran'),
        ],
      ),
    );
  }
}
