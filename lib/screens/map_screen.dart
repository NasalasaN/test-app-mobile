import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../models/app_exception.dart';
import '../models/city_search_result_model.dart';
import '../models/point_of_interest_model.dart';
import '../providers/location_provider.dart';
import '../services/api/geocoding_api.dart';
import '../services/api/poi_api.dart';
import '../theme/app_colors.dart';

/// Carte des mosquées et restaurants halal/vegan à proximité, avec
/// recherche de ville pour recentrer la carte, filtres par catégorie et
/// recherche par nom parmi les lieux affichés. Données OpenStreetMap via
/// l'API Overpass (gratuite, sans clé).
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _api = PoiApi();
  final _geocodingApi = GeocodingApi();
  final _mapController = MapController();
  final _citySearchController = TextEditingController();

  Future<List<PointOfInterest>>? _future;
  double? _lastLat;
  double? _lastLon;

  // Recherche de ville pour recentrer la carte.
  double? _searchedLat;
  double? _searchedLon;
  List<CitySearchResult> _cityResults = [];
  Timer? _cityDebounce;

  // Filtre par nom parmi les lieux déjà chargés.
  String _poiFilterQuery = '';

  // Affichage ou non du panneau recherche/filtres, pour laisser plus de
  // place à la carte une fois les réglages faits.
  bool _panelOpen = true;

  final Set<PoiCategory> _visibleCategories = {
    PoiCategory.mosque,
    PoiCategory.halal,
    PoiCategory.vegan,
  };

  @override
  void dispose() {
    _cityDebounce?.cancel();
    _citySearchController.dispose();
    super.dispose();
  }

  void _ensureLoaded(double lat, double lon) {
    if (_future != null && _lastLat == lat && _lastLon == lon) return;
    _lastLat = lat;
    _lastLon = lon;
    _future = _api.fetchNearby(latitude: lat, longitude: lon);
  }

  void _onCityQueryChanged(String query) {
    _cityDebounce?.cancel();
    if (query.trim().length < 2) {
      setState(() => _cityResults = []);
      return;
    }
    _cityDebounce = Timer(const Duration(milliseconds: 400), () async {
      try {
        final results = await _geocodingApi.searchCities(query);
        if (mounted) setState(() => _cityResults = results);
      } catch (_) {
        if (mounted) setState(() => _cityResults = []);
      }
    });
  }

  void _selectCity(CitySearchResult result) {
    setState(() {
      _searchedLat = result.latitude;
      _searchedLon = result.longitude;
      _cityResults = [];
      _citySearchController.clear();
    });
    FocusScope.of(context).unfocus();
    _mapController.move(LatLng(result.latitude, result.longitude), 14);
  }

  Color _colorFor(PoiCategory category) {
    switch (category) {
      case PoiCategory.mosque:
        return AppColors.goldLight;
      case PoiCategory.halal:
        return AppColors.teal;
      case PoiCategory.vegan:
        return Colors.greenAccent;
    }
  }

  IconData _iconFor(PoiCategory category) {
    switch (category) {
      case PoiCategory.mosque:
        return Icons.mosque;
      case PoiCategory.halal:
        return Icons.restaurant;
      case PoiCategory.vegan:
        return Icons.eco;
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = context.watch<LocationProvider>().location;
    final lat = _searchedLat ?? location?.latitude;
    final lon = _searchedLon ?? location?.longitude;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Carte'),
        actions: [
          IconButton(
            icon: Icon(_panelOpen ? Icons.expand_less : Icons.tune),
            tooltip: _panelOpen
                ? 'Masquer la recherche et les filtres'
                : 'Afficher la recherche et les filtres',
            onPressed: () => setState(() => _panelOpen = !_panelOpen),
          ),
        ],
      ),
      body: lat == null || lon == null
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Choisissez une ville pour voir les lieux à proximité.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : _buildMap(context, lat, lon),
    );
  }

  Widget _buildMap(BuildContext context, double lat, double lon) {
    _ensureLoaded(lat, lon);
    final center = LatLng(lat, lon);

    return Column(
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: !_panelOpen
              ? const SizedBox(width: double.infinity)
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                      child: TextField(
                        controller: _citySearchController,
                        onChanged: _onCityQueryChanged,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search),
                          hintText: 'Rechercher une ville…',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    if (_cityResults.isNotEmpty)
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 180),
                        child: Card(
                          margin: const EdgeInsets.fromLTRB(12, 4, 12, 0),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: _cityResults.length,
                            itemBuilder: (context, index) {
                              final result = _cityResults[index];
                              return ListTile(
                                dense: true,
                                leading: const Icon(Icons.location_city),
                                title: Text(result.displayLabel),
                                onTap: () => _selectCity(result),
                              );
                            },
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                      child: TextField(
                        onChanged: (value) => setState(() => _poiFilterQuery = value),
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.filter_alt_outlined),
                          hintText: 'Filtrer les lieux affichés par nom…',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Wrap(
                        spacing: 8,
                        children: [
                          for (final category in PoiCategory.values)
                            FilterChip(
                              label: Text(category.labelFr),
                              avatar: Icon(
                                _iconFor(category),
                                size: 18,
                                color: _colorFor(category),
                              ),
                              selected: _visibleCategories.contains(category),
                              onSelected: (selected) => setState(() {
                                if (selected) {
                                  _visibleCategories.add(category);
                                } else {
                                  _visibleCategories.remove(category);
                                }
                              }),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
        Expanded(
          child: FutureBuilder<List<PointOfInterest>>(
            future: _future,
            builder: (context, snapshot) {
              final query = _poiFilterQuery.trim().toLowerCase();
              final pois = (snapshot.data ?? [])
                  .where((p) => _visibleCategories.contains(p.category))
                  .where((p) => query.isEmpty || p.name.toLowerCase().contains(query))
                  .toList();

              return Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(initialCenter: center, initialZoom: 14),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.miqat.miqat',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: center,
                            child: const Icon(Icons.my_location, color: AppColors.cream),
                          ),
                          for (final poi in pois)
                            Marker(
                              point: LatLng(poi.latitude, poi.longitude),
                              child: GestureDetector(
                                onTap: () => _showPoiDetails(context, poi),
                                child: Icon(
                                  _iconFor(poi.category),
                                  color: _colorFor(poi.category),
                                  size: 32,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  if (snapshot.connectionState != ConnectionState.done)
                    const Positioned(
                      top: 12,
                      right: 12,
                      child: CircularProgressIndicator(),
                    ),
                  if (snapshot.hasError)
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: 12,
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(friendlyErrorMessage(snapshot.error!)),
                              ),
                              TextButton(
                                onPressed: () => setState(() {
                                  _future = _api.fetchNearby(latitude: lat, longitude: lon);
                                }),
                                child: const Text('Réessayer'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  void _showPoiDetails(BuildContext context, PointOfInterest poi) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_iconFor(poi.category), color: _colorFor(poi.category)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(poi.name, style: Theme.of(context).textTheme.titleMedium),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(poi.category.labelFr),
            if (poi.address != null) ...[
              const SizedBox(height: 4),
              Text(poi.address!),
            ],
          ],
        ),
      ),
    );
  }
}
