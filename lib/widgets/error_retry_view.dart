import 'package:flutter/material.dart';

/// Message d'erreur centré avec un bouton de nouvelle tentative — motif
/// répété par tous les écrans qui chargent des données via une API.
class ErrorRetryView extends StatelessWidget {
  const ErrorRetryView({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: const Text('Réessayer')),
          ],
        ),
      ),
    );
  }
}
