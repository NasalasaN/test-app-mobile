import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/surah_model.dart';
import '../services/api/quran_api.dart';
import '../services/storage/storage_service.dart';
import '../theme/app_colors.dart';
import 'quran_surah_detail_screen.dart';

/// Liste des 114 sourates du Coran, dans leur ordre canonique, avec
/// recherche par nom.
class QuranSurahListScreen extends StatefulWidget {
  const QuranSurahListScreen({super.key});

  @override
  State<QuranSurahListScreen> createState() => _QuranSurahListScreenState();
}

class _QuranSurahListScreenState extends State<QuranSurahListScreen> {
  late final QuranApi _api;
  late Future<List<SurahMeta>> _future;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _api = QuranApi(storage: context.read<StorageService>());
    _future = _api.fetchSurahList();
  }

  List<SurahMeta> _filter(List<SurahMeta> surahs) {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return surahs;
    return surahs.where((s) {
      return s.englishNameTranslation.toLowerCase().contains(query) ||
          s.englishName.toLowerCase().contains(query) ||
          s.number.toString() == query;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Le Coran'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              onChanged: (value) => setState(() => _query = value),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Rechercher une sourate…',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<SurahMeta>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  final message = snapshot.error is QuranApiException
                      ? (snapshot.error as QuranApiException).messageFr
                      : 'Erreur inattendue lors du chargement du Coran.';
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(message, textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          OutlinedButton(
                            onPressed: () => setState(() {
                              _future = _api.fetchSurahList();
                            }),
                            child: const Text('Réessayer'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final surahs = _filter(snapshot.data ?? []);
                if (surahs.isEmpty) {
                  return const Center(child: Text('Aucune sourate trouvée.'));
                }

                return ListView.separated(
                  itemCount: surahs.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final surah = surahs[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.surface,
                        foregroundColor: AppColors.goldLight,
                        child: Text('${surah.number}'),
                      ),
                      title: Text(surah.englishNameTranslation),
                      subtitle: Text(
                        '${surah.englishName} · ${surah.numberOfAyahs} versets',
                      ),
                      trailing: Text(
                        surah.nameArabic,
                        style: const TextStyle(fontSize: 18, color: AppColors.goldLight),
                      ),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => QuranSurahDetailScreen(surahMeta: surah),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
