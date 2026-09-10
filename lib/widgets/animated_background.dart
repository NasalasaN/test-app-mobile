import 'dart:math';

import 'package:flutter/material.dart';

import '../models/ambiance_model.dart';
import '../theme/app_colors.dart';

/// Fond animé en arrière-plan de l'application (ciel étoilé ou nuages),
/// pour une ambiance plus vivante. En mode "automatique", bascule entre les
/// deux selon l'heure de la journée.
class AnimatedBackground extends StatelessWidget {
  const AnimatedBackground({super.key, required this.ambiance});

  final BackgroundAmbiance ambiance;

  @override
  Widget build(BuildContext context) {
    final resolved = _resolve(ambiance);
    switch (resolved) {
      case BackgroundAmbiance.stars:
        return const _StarsBackground();
      case BackgroundAmbiance.clouds:
        return const _CloudsBackground();
      case BackgroundAmbiance.auto:
      case BackgroundAmbiance.none:
        return const SizedBox.shrink();
    }
  }

  BackgroundAmbiance _resolve(BackgroundAmbiance ambiance) {
    if (ambiance != BackgroundAmbiance.auto) return ambiance;
    final hour = DateTime.now().hour;
    final isNight = hour >= 19 || hour < 6;
    return isNight ? BackgroundAmbiance.stars : BackgroundAmbiance.clouds;
  }
}

class _StarsBackground extends StatefulWidget {
  const _StarsBackground();

  @override
  State<_StarsBackground> createState() => _StarsBackgroundState();
}

class _StarsBackgroundState extends State<_StarsBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Star> _stars;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    final random = Random(42);
    _stars = List.generate(90, (_) {
      return _Star(
        dx: random.nextDouble(),
        dy: random.nextDouble(),
        radius: 0.8 + random.nextDouble() * 1.6,
        phase: random.nextDouble() * 2 * pi,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            size: Size.infinite,
            painter: _StarsPainter(stars: _stars, t: _controller.value),
          );
        },
      ),
    );
  }
}

class _Star {
  const _Star({
    required this.dx,
    required this.dy,
    required this.radius,
    required this.phase,
  });

  final double dx;
  final double dy;
  final double radius;
  final double phase;
}

class _StarsPainter extends CustomPainter {
  const _StarsPainter({required this.stars, required this.t});

  final List<_Star> stars;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.cream;
    for (final star in stars) {
      final twinkle = 0.35 + 0.65 * (0.5 + 0.5 * sin(2 * pi * t + star.phase));
      paint.color = AppColors.cream.withValues(alpha: twinkle);
      canvas.drawCircle(
        Offset(star.dx * size.width, star.dy * size.height),
        star.radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StarsPainter oldDelegate) => oldDelegate.t != t;
}

class _CloudsBackground extends StatefulWidget {
  const _CloudsBackground();

  @override
  State<_CloudsBackground> createState() => _CloudsBackgroundState();
}

class _CloudsBackgroundState extends State<_CloudsBackground>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<_Cloud> _clouds;

  @override
  void initState() {
    super.initState();
    final random = Random(7);
    _clouds = List.generate(5, (i) {
      return _Cloud(
        dy: 0.05 + random.nextDouble() * 0.45,
        scale: 0.7 + random.nextDouble() * 0.9,
        startOffset: random.nextDouble(),
      );
    });
    _controllers = List.generate(_clouds.length, (i) {
      return AnimationController(
        vsync: this,
        duration: Duration(seconds: 40 + i * 12),
      )..repeat();
    });
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          for (var i = 0; i < _clouds.length; i++)
            AnimatedBuilder(
              animation: _controllers[i],
              builder: (context, _) {
                final t = (_controllers[i].value + _clouds[i].startOffset) % 1.0;
                return CustomPaint(
                  size: Size.infinite,
                  painter: _CloudPainter(cloud: _clouds[i], t: t),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _Cloud {
  const _Cloud({required this.dy, required this.scale, required this.startOffset});

  final double dy;
  final double scale;
  final double startOffset;
}

class _CloudPainter extends CustomPainter {
  const _CloudPainter({required this.cloud, required this.t});

  final _Cloud cloud;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.cream.withValues(alpha: 0.10)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24);

    // Traverse de droite (hors écran) à gauche (hors écran).
    final dx = size.width * (1.2 - t * 1.4);
    final dy = cloud.dy * size.height;
    final baseRadius = 34.0 * cloud.scale;

    final puffs = [
      Offset(dx, dy),
      Offset(dx + baseRadius * 0.9, dy + baseRadius * 0.2),
      Offset(dx - baseRadius * 0.9, dy + baseRadius * 0.25),
      Offset(dx + baseRadius * 0.3, dy - baseRadius * 0.35),
    ];
    for (final puff in puffs) {
      canvas.drawCircle(puff, baseRadius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CloudPainter oldDelegate) => oldDelegate.t != t;
}
