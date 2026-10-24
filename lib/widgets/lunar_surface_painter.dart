import 'dart:math';
import 'package:flutter/material.dart';
import '../models/landing_site.dart';

/// Custom painter that renders a stylised top-down polar projection
/// of the Lunar South Pole with dynamic glowing pins for each landing site.
class LunarSurfacePainter extends CustomPainter {
  final List<LandingSite> sites;
  final List<double> scores;
  final int? selectedIndex;
  final double animationValue; // 0-1 pulsing cycle

  LunarSurfacePainter({
    required this.sites,
    required this.scores,
    this.selectedIndex,
    this.animationValue = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 16;

    // ── Moon disc gradient ───────────────────────────────────────
    final discPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.25, -0.25),
        radius: 1.0,
        colors: const [
          Color(0xFF2A2F3A),
          Color(0xFF1C2028),
          Color(0xFF0F1319),
          Color(0xFF0B0E14),
        ],
        stops: const [0.0, 0.4, 0.75, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, discPaint);

    // ── Outer rim glow ───────────────────────────────────────────
    final rimGlow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4)
      ..color = const Color(0xFF00F2FE).withValues(alpha: 0.12);
    canvas.drawCircle(center, radius, rimGlow);

    final rimLine = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = const Color(0xFF00F2FE).withValues(alpha: 0.20);
    canvas.drawCircle(center, radius, rimLine);

    // ── Latitude grid circles (80°, 82.5°, 85°, 87.5°, 90°) ────
    final gridPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5
      ..color = const Color(0xFF00F2FE).withValues(alpha: 0.06);
    final gridLabelStyle = TextStyle(
      color: const Color(0xFF00F2FE).withValues(alpha: 0.18),
      fontSize: 7,
    );
    for (int i = 1; i <= 4; i++) {
      final r = radius * (i / 4);
      canvas.drawCircle(center, r, gridPaint);
      // Latitude label
      final lat = 90 - (10 * i / 4);
      final tp = TextPainter(
        text: TextSpan(text: '${lat.toStringAsFixed(1)}°S', style: gridLabelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(center.dx + r + 3, center.dy - 6));
    }

    // ── Longitude radials ────────────────────────────────────────
    final radialPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.4
      ..color = const Color(0xFF00F2FE).withValues(alpha: 0.05);
    for (int i = 0; i < 12; i++) {
      final a = i * pi / 6;
      canvas.drawLine(
        center,
        Offset(center.dx + cos(a) * radius, center.dy + sin(a) * radius),
        radialPaint,
      );
      // Longitude labels at edge
      final deg = (i * 30);
      final lx = center.dx + cos(a) * (radius + 10);
      final ly = center.dy + sin(a) * (radius + 10);
      final tp = TextPainter(
        text: TextSpan(
          text: '$deg°',
          style: TextStyle(
            color: const Color(0xFF00F2FE).withValues(alpha: 0.15),
            fontSize: 7,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(lx - tp.width / 2, ly - tp.height / 2));
    }

    // ── Decorative craters ───────────────────────────────────────
    final craterFillPaint = Paint()
      ..color = const Color(0xFF0B0E14).withValues(alpha: 0.3);
    final craterStrokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6
      ..color = const Color(0xFF00F2FE).withValues(alpha: 0.05);
    final rng = Random(42);
    for (int i = 0; i < 22; i++) {
      final cr = radius * (0.12 + rng.nextDouble() * 0.78);
      final ca = rng.nextDouble() * 2 * pi;
      final cx = center.dx + cos(ca) * cr;
      final cy = center.dy + sin(ca) * cr;
      final crRadius = 4.0 + rng.nextDouble() * 16;
      canvas.drawCircle(Offset(cx, cy), crRadius, craterFillPaint);
      canvas.drawCircle(Offset(cx, cy), crRadius, craterStrokePaint);
    }

    // ── Landing site pins ────────────────────────────────────────
    for (int i = 0; i < sites.length; i++) {
      final site = sites[i];
      final pos = _sitePosition(site, center, radius);
      final score = scores.length > i ? scores[i] : 50.0;
      final isSelected = i == selectedIndex;
      final color = _scoreColor(score);

      // Outer pulse ring (for selected)
      if (isSelected) {
        final ringPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = color.withValues(alpha: 0.3 * (1.0 - animationValue));
        canvas.drawCircle(
            pos, 18 + animationValue * 14, ringPaint);
      }

      // Glow
      final glowRadius = isSelected
          ? 20.0 + animationValue * 6
          : 12.0 + animationValue * 3;
      final glowPaint = Paint()
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10)
        ..color = color.withValues(alpha: isSelected ? 0.40 : 0.18);
      canvas.drawCircle(pos, glowRadius, glowPaint);

      // Pin ring
      final ringPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 2.0 : 1.5
        ..color = color.withValues(alpha: 0.8);
      canvas.drawCircle(pos, isSelected ? 9 : 6.5, ringPaint);

      // Pin dot
      canvas.drawCircle(
        pos,
        isSelected ? 5 : 3.5,
        Paint()..color = color,
      );

      // White core
      canvas.drawCircle(
        pos,
        isSelected ? 2 : 1.5,
        Paint()..color = Colors.white.withValues(alpha: 0.9),
      );

      // Label with background
      final label = _shortName(site.name);
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: isSelected ? 1.0 : 0.65),
            fontSize: isSelected ? 10 : 8,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final labelOffset = Offset(
        pos.dx - tp.width / 2,
        pos.dy + (isSelected ? 14 : 10),
      );

      // Label background
      final bgRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          labelOffset.dx - 3,
          labelOffset.dy - 1,
          tp.width + 6,
          tp.height + 2,
        ),
        const Radius.circular(3),
      );
      canvas.drawRRect(
        bgRect,
        Paint()..color = const Color(0xFF0B0E14).withValues(alpha: 0.7),
      );

      tp.paint(canvas, labelOffset);
    }

    // ── "SOUTH POLE" center label ────────────────────────────────
    final poleLabel = TextPainter(
      text: TextSpan(
        text: '⊕ SOUTH POLE',
        style: TextStyle(
          color: const Color(0xFF00F2FE).withValues(alpha: 0.25),
          fontSize: 8,
          fontWeight: FontWeight.w600,
          letterSpacing: 2,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    poleLabel.paint(
        canvas, Offset(center.dx - poleLabel.width / 2, center.dy - 5));
  }

  Offset _sitePosition(LandingSite site, Offset center, double radius) {
    // Map latitude (-80 .. -90) → radial distance (outer → center)
    final latNorm =
        ((site.coordinates.latitude.abs() - 80) / 10).clamp(0.0, 1.0);
    final r = radius * (1.0 - latNorm) * 0.82 + radius * 0.08;
    final angle = site.coordinates.longitude * pi / 180;
    return Offset(center.dx + cos(angle) * r, center.dy + sin(angle) * r);
  }

  Color _scoreColor(double score) {
    if (score >= 75) return const Color(0xFF00F2FE);
    if (score >= 50) return const Color(0xFF4ADE80);
    if (score >= 30) return const Color(0xFFFBBF24);
    return const Color(0xFFEF4444);
  }

  String _shortName(String name) {
    if (name.length <= 14) return name;
    return '${name.substring(0, 12)}…';
  }

  @override
  bool shouldRepaint(covariant LunarSurfacePainter oldDelegate) => true;
}
