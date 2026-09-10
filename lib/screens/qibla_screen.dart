import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_device_compass/flutter_device_compass.dart';
import 'package:provider/provider.dart';

import '../providers/location_provider.dart';
import '../theme/app_colors.dart';
import '../utils/qibla_utils.dart';

/// Boussole indiquant la direction de la Qibla (La Mecque) depuis la
/// position actuelle de l'utilisateur.
class QiblaScreen extends StatelessWidget {
  const QiblaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final locationProvider = context.watch<LocationProvider>();
    final location = locationProvider.location;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Qibla'),
      ),
      body: location == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  locationProvider.errorMessageFr ??
                      'Choisissez une ville pour trouver la direction de la Qibla.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : _QiblaCompass(
              latitude: location.latitude,
              longitude: location.longitude,
            ),
    );
  }
}

class _QiblaCompass extends StatelessWidget {
  const _QiblaCompass({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;

  @override
  Widget build(BuildContext context) {
    final bearing = qiblaBearing(latitude, longitude);
    final distanceKm = distanceToKaabaKm(latitude, longitude);

    return FutureBuilder<bool?>(
      future: FlutterCompass.hasSensors,
      builder: (context, sensorSnapshot) {
        if (sensorSnapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (sensorSnapshot.data == false) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                "Boussole non disponible sur cet appareil.",
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return StreamBuilder<CompassEvent>(
          stream: FlutterCompass.events,
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data?.heading == null) {
              return const Center(child: CircularProgressIndicator());
            }

            final heading = snapshot.data!.heading!;
            final angle = (bearing - heading) * pi / 180;
            final aligned = _angularDifference(bearing, heading) < 5;

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                SizedBox(
                  width: 260,
                  height: 260,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 260,
                        height: 260,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.goldLight, width: 2),
                        ),
                      ),
                      const Positioned(
                        top: 12,
                        child: Text('N', style: TextStyle(color: AppColors.cream)),
                      ),
                      Transform.rotate(
                        angle: angle,
                        child: Icon(
                          Icons.navigation,
                          size: 140,
                          color: aligned ? Colors.greenAccent : AppColors.gold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  aligned
                      ? 'Vous faites face à la Qibla'
                      : 'Tournez-vous jusqu\'à ce que la flèche pointe vers le haut',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Cap Qibla : ${bearing.toStringAsFixed(0)}° · '
                  'Distance à La Mecque : ${distanceKm.toStringAsFixed(0)} km',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const Spacer(),
              ],
            );
          },
        );
      },
    );
  }

  double _angularDifference(double a, double b) {
    final diff = (a - b).abs() % 360;
    return diff > 180 ? 360 - diff : diff;
  }
}
