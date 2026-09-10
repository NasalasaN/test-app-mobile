import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/surah_model.dart';
import '../services/api/quran_api.dart';
import '../services/storage/storage_service.dart';
import '../theme/app_colors.dart';

/// Affiche l'intégralité d'une sourate : chaque verset en arabe, en
/// translittération phonétique, puis en français.
class QuranSurahDetailScreen extends StatefulWidget {
  const QuranSurahDetailScreen({super.key, required this.surahMeta});

  final SurahMeta surahMeta;

  @override
  State<QuranSurahDetailScreen> createState() => _QuranSurahDetailScreenState();
}

class _QuranSurahDetailScreenState extends State<QuranSurahDetailScreen> {
  late final QuranApi _api;
  late Future<SurahDetail> _future;

  @override
  void initState() {
    super.initState();
    _api = QuranApi(storage: context.read<StorageService>());
    _future = _api.fetchSurahDetail(widget.surahMeta.number);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.surahMeta.number}. ${widget.surahMeta.englishNameTranslation}',
        ),
      ),
      body: FutureBuilder<SurahDetail>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            final message = snapshot.error is QuranApiException
                ? (snapshot.error as QuranApiException).messageFr
                : 'Erreur inattendue lors du chargement de la sourate.';
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
                        _future = _api.fetchSurahDetail(widget.surahMeta.number);
                      }),
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
            );
          }

          final detail = snapshot.data!;
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: detail.ayahs.length,
            separatorBuilder: (_, _) => const Divider(height: 32),
            itemBuilder: (context, index) => _AyahTile(
              ayah: detail.ayahs[index],
              surahNumber: widget.surahMeta.number,
              surahName: widget.surahMeta.englishNameTranslation,
            ),
          );
        },
      ),
    );
  }
}

class _AyahTile extends StatelessWidget {
  const _AyahTile({
    required this.ayah,
    required this.surahNumber,
    required this.surahName,
  });

  final Ayah ayah;
  final int surahNumber;
  final String surahName;

  void _share() {
    final text = 'Sourate $surahNumber. $surahName — verset ${ayah.numberInSurah}\n\n'
        '${ayah.arabicText}\n\n'
        '${ayah.transliterationText}\n\n'
        '${ayah.frenchText}\n\n'
        'via l\'app Miqat';
    SharePlus.instance.share(ShareParams(text: text));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 12,
              backgroundColor: AppColors.surface,
              foregroundColor: AppColors.goldLight,
              child: Text(
                '${ayah.numberInSurah}',
                style: const TextStyle(fontSize: 11),
              ),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.share, size: 20),
              tooltip: 'Partager ce verset',
              onPressed: _share,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          ayah.arabicText,
          textAlign: TextAlign.right,
          textDirection: TextDirection.rtl,
          style: GoogleFonts.amiri(
            fontSize: 24,
            height: 1.8,
            color: AppColors.cream,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          ayah.transliterationText,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontStyle: FontStyle.italic,
            color: AppColors.goldLight,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          ayah.frenchText,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.cream.withValues(alpha: 0.85),
          ),
        ),
      ],
    );
  }
}
