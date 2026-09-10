import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../models/point_of_interest_model.dart';
import '../providers/location_provider.dart';
import '../services/api/poi_api.dart';
import '../theme/app_colors.dart';

/// Carte des mosquées et restaurants halal/vegan à proximité, avec filtres
/// par catégorie. Données OpenStreetMap via l'API Overpass (gratuite, sans clé).
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _api = PoiApi();
  Future<List<PointOfInterest>>? _future;
  double? _lastLat;
  double? _lastLon;

  final Set<PoiCategory> _visibleCategories = {
    PoiCategory.mosque,
    PoiCategory.halal,
    PoiCategory.vegan,
  };

  void _ensureLoaded(double lat, double lon) {
    if (_future != null && _lastLat == lat && _lastLon == lon) return;
    _lastLat = lat;
    _lastLon = lon;
    _future = _api.fetchNearby(latitude: lat, longitude: lon);
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

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Carte'),
      ),
      body: location == null
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Choisissez une ville pour voir les lieux à proximité.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : _buildMap(context, location.latitude, location.longitude),
    );
  }

  Widget _buildMap(BuildContext context, double lat, double lon) {
    _ensureLoaded(lat, lon);
    final center = LatLng(lat, lon);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Wrap(
            spacing: 8,
            children: [
              for (final category in PoiCategory.values)
                FilterChip(
                  label: Text(category.labelFr),
                  avatar: Icon(_iconFor(category), size: 18, color: _colorFor(category)),
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
        Expanded(
          child: FutureBuilder<List<PointOfInterest>>(
            future: _future,
            builder: (context, snapshot) {
              final pois = (snapshot.data ?? [])
                  .where((p) => _visibleCategories.contains(p.category))
                  .toList();

              return Stack(
                children: [
                  FlutterMap(
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
                                child: Text(
                                  snapshot.error is PoiApiException
                                      ? (snapshot.error as PoiApiException).messageFr
                                      : 'Erreur inattendue.',
                                ),
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
