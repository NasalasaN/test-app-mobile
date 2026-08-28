import 'dart:async';

import 'package:flutter/material.dart';

import '../models/city_search_result_model.dart';
import '../models/location_model.dart';
import '../services/api/geocoding_api.dart';
import '../theme/app_colors.dart';

/// Recherche manuelle de ville (repli si la géolocalisation est refusée, ou
/// pour changer de ville). Retourne la [Location] choisie via
/// `Navigator.pop`.
class CitySearchScreen extends StatefulWidget {
  const CitySearchScreen({super.key});

  @override
  State<CitySearchScreen> createState() => _CitySearchScreenState();
}

class _CitySearchScreenState extends State<CitySearchScreen> {
  final _api = GeocodingApi();
  final _controller = TextEditingController();
  Timer? _debounce;

  List<CitySearchResult> _results = [];
  bool _loading = false;
  String? _errorMessageFr;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(query));
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
        _errorMessageFr = null;
        _loading = false;
      });
      return;
    }

    setState(() {
      _loading = true;
      _errorMessageFr = null;
    });

    try {
      final results = await _api.searchCities(query);
      if (!mounted) return;
      setState(() {
        _results = results;
        _loading = false;
      });
    } on GeocodingApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessageFr = e.messageFr;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choisir une ville')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _controller,
              autofocus: true,
              onChanged: _onQueryChanged,
              decoration: const InputDecoration(
                hintText: 'Nom de la ville…',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 16),
            if (_loading) const LinearProgressIndicator(),
            if (_errorMessageFr != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  _errorMessageFr!,
                  style: TextStyle(color: AppColors.cream.withValues(alpha: 0.8)),
                ),
              ),
            if (!_loading &&
                _errorMessageFr == null &&
                _results.isEmpty &&
                _controller.text.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Aucune ville trouvée.',
                  style: TextStyle(color: AppColors.cream.withValues(alpha: 0.7)),
                ),
              ),
            Expanded(
              child: ListView.builder(
                itemCount: _results.length,
                itemBuilder: (context, index) {
                  final result = _results[index];
                  return ListTile(
                    leading: const Icon(Icons.location_city, color: AppColors.gold),
                    title: Text(result.displayLabel),
                    onTap: () {
                      Navigator.of(context).pop(
                        Location(
                          latitude: result.latitude,
                          longitude: result.longitude,
                          cityName: result.name,
                          country: result.country,
                          isManuallySelected: true,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
