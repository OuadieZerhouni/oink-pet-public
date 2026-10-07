import 'dart:math' as math;

import 'package:flutter/rendering.dart';

/// Wearables, drawn in the pig's design space so they scale with it.
/// Each function takes an anchor and the head radius, so the closet can draw
/// the same item alone as a thumbnail.

Paint _f(Color c) => Paint()..color = c;
Paint _s(Color c, double w) => Paint()
  ..color = c
  ..style = PaintingStyle.stroke
  ..strokeWidth = w
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.round;

const _ink = Color(0xFF3A2430);

void drawHat(Canvas c, String id, Offset crown, double r) {
  c.save();
  c.translate(crown.dx, crown.dy);
  final u = r / 90; // unit scale
  c.scale(u, u);
  switch (id) {
    case 'bow':
      _bow(c, const Offset(28, 14), const Color(0xFFFF5C8A), 1.0);
    case 'flowers':
      final colors = [const Color(0xFFFFD54F), const Color(0xFFFF8A80), const Color(0xFFB39DDB), const Color(0xFF80DEEA), const Color(0xFFFFAB91)];
      // leafy band
      c.drawArc(Rect.fromCenter(center: const Offset(0, 26), width: 150, height: 48), math.pi * 1.08, math.pi * 0.84, false, _s(const Color(0xFF66BB6A), 7));
      for (var i = 0; i < 5; i++) {
        final a = math.pi * (1.12 + i * 0.19);
        final p = Offset(math.cos(a) * 72, 26 + math.sin(a) * 23);
        _flower(c, p, colors[i], 11);
      }
    case 'party':
      final cone = Path()
        ..moveTo(-26, 14)
        ..lineTo(6, -62)
        ..lineTo(34, 10)
        ..close();
      c.drawPath(cone, _f(const Color(0xFF7C4DFF)));
      c.save();
      c.clipPath(cone);
      for (var i = 0; i < 5; i++) {
        c.drawLine(Offset(-40, -30 + i * 16.0), Offset(50, -50 + i * 16.0), _s(const Color(0xFFFFD54F), 5));
      }
      c.restore();
      c.drawPath(cone, _s(_ink.withValues(alpha: 0.35), 2));
      c.drawCircle(const Offset(6, -64), 9, _f(const Color(0xFFFF5C8A)));
    case 'beanie':
      final dome = Rect.fromCenter(center: const Offset(0, 20), width: 150, height: 120);
      c.drawArc(dome, math.pi, math.pi, true, _f(const Color(0xFF4FC3F7)));
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: const Offset(0, 18), width: 160, height: 26), const Radius.circular(13)), _f(const Color(0xFF0288D1)));
      for (var i = -3; i <= 3; i++) {
        c.drawLine(Offset(i * 20.0, 8), Offset(i * 20.0, 28), _s(const Color(0xFF01579B).withValues(alpha: 0.35), 3));
      }
      c.drawCircle(const Offset(0, -44), 15, _f(const Color(0xFFFFFFFF)));
      c.drawCircle(const Offset(0, -44), 15, _s(const Color(0xFFB3E5FC), 2));
    case 'chef':
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: const Offset(0, 8), width: 96, height: 30), const Radius.circular(6)), _f(const Color(0xFFFFFFFF)));
      for (final o in [const Offset(-30, -26), const Offset(0, -40), const Offset(30, -26)]) {
        c.drawCircle(o, 30, _f(const Color(0xFFFFFFFF)));
      }
      final outline = _s(const Color(0xFFCFD8DC), 2.5);
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: const Offset(0, 8), width: 96, height: 30), const Radius.circular(6)), outline);
      c.drawArc(Rect.fromCircle(center: const Offset(0, -40), radius: 30), math.pi * 1.05, math.pi * 0.9, false, outline);
    case 'cowboy':
      c.drawOval(Rect.fromCenter(center: const Offset(0, 10), width: 190, height: 34), _f(const Color(0xFFA1693D)));
      final crownPath = Path()
        ..moveTo(-46, 8)
        ..quadraticBezierTo(-52, -52, -12, -46)
        ..quadraticBezierTo(0, -34, 12, -46)
        ..quadraticBezierTo(52, -52, 46, 8)
        ..close();
      c.drawPath(crownPath, _f(const Color(0xFFB87A48)));
      c.drawRect(const Rect.fromLTWH(-46, -6, 92, 10), _f(const Color(0xFF6D4C41)));
      c.drawPath(crownPath, _s(const Color(0xFF7B4A28), 2));
    case 'frog':
      c.drawArc(Rect.fromCenter(center: const Offset(0, 22), width: 170, height: 130), math.pi, math.pi, true, _f(const Color(0xFF81C784)));
      for (final side in [-1.0, 1.0]) {
        final e = Offset(side * 44, -38);
        c.drawCircle(e, 22, _f(const Color(0xFF81C784)));
        c.drawCircle(e, 14, _f(const Color(0xFFFFFFFF)));
        c.drawCircle(e + const Offset(0, 2), 7, _f(_ink));
      }
      c.drawArc(Rect.fromCenter(center: const Offset(0, -6), width: 40, height: 18), 0.2, math.pi - 0.4, false, _s(const Color(0xFF2E7D32), 3));
    case 'crown':
      final path = Path()
        ..moveTo(-52, 14)
        ..lineTo(-58, -34)
        ..lineTo(-28, -10)
        ..lineTo(0, -48)
        ..lineTo(28, -10)
        ..lineTo(58, -34)
        ..lineTo(52, 14)
        ..close();
      c.drawPath(path, _f(const Color(0xFFFFCA28)));
      c.drawPath(path, _s(const Color(0xFFF9A825), 3));
      for (final j in [const Offset(-30, 2), const Offset(0, 0), const Offset(30, 2)]) {
        c.drawCircle(j, 6.5, _f(const Color(0xFFE91E63)));
      }
      for (final t in [const Offset(-58, -34), const Offset(0, -48), const Offset(58, -34)]) {
        c.drawCircle(t, 5.5, _f(const Color(0xFFFFF59D)));
      }
    case 'witch':
      c.drawOval(Rect.fromCenter(center: const Offset(0, 12), width: 180, height: 30), _f(const Color(0xFF4A3B6B)));
      final cone = Path()
        ..moveTo(-44, 10)
        ..quadraticBezierTo(-10, -50, 34, -92)
        ..quadraticBezierTo(16, -40, 44, 10)
        ..close();
      c.drawPath(cone, _f(const Color(0xFF5E4B8B)));
      c.drawRect(const Rect.fromLTWH(-44, -6, 88, 12), _f(const Color(0xFFFF9800)));
      _star(c, const Offset(4, -32), 9, const Color(0xFFFFEB3B));
    case 'santa':
      final cone = Path()
        ..moveTo(-58, 14)
        ..quadraticBezierTo(-20, -70, 52, -40)
        ..quadraticBezierTo(30, -10, 58, 14)
        ..close();
      c.drawPath(cone, _f(const Color(0xFFE53935)));
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: const Offset(0, 14), width: 132, height: 26), const Radius.circular(13)), _f(const Color(0xFFFFFFFF)));
      c.drawCircle(const Offset(58, -38), 14, _f(const Color(0xFFFFFFFF)));
    default:
      break;
  }
  c.restore();
}

void drawGlasses(Canvas c, String id, Offset eyeL, Offset eyeR, double r) {
  final u = r / 90;
  final lens = 20.0 * u;
  final frame = _s(_ink, 3.2 * u);
  final bridgeY = (eyeL.dy + eyeR.dy) / 2;
  switch (id) {
    case 'round':
      for (final e in [eyeL, eyeR]) {
        c.drawCircle(e, lens, _f(const Color(0x33B3E5FC)));
        c.drawCircle(e, lens, frame);
      }
      c.drawLine(Offset(eyeL.dx + lens, bridgeY), Offset(eyeR.dx - lens, bridgeY), frame);
    case 'hearts':
      for (final e in [eyeL, eyeR]) {
        final path = _heartPath(e + Offset(0, -2 * u), lens * 1.25);
        c.drawPath(path, _f(const Color(0xDDFF4F81)));
        c.drawPath(path, _s(const Color(0xFFC2185B), 2.4 * u));
      }
      c.drawLine(Offset(eyeL.dx + lens, bridgeY - 3 * u), Offset(eyeR.dx - lens, bridgeY - 3 * u), _s(const Color(0xFFC2185B), 3 * u));
    case 'stars':
      for (final e in [eyeL, eyeR]) {
        _star(c, e, lens * 1.3, const Color(0xDDFFD54F));
        _star(c, e, lens * 1.3, const Color(0xFFFFA000), stroke: 2.4 * u);
      }
      c.drawLine(Offset(eyeL.dx + lens, bridgeY), Offset(eyeR.dx - lens, bridgeY), _s(const Color(0xFFFFA000), 3 * u));
  }
}

void drawNeck(Canvas c, String id, Offset neck, double r) {
  c.save();
  c.translate(neck.dx, neck.dy);
  final u = r / 90;
  c.scale(u, u);
  switch (id) {
    case 'bandana':
      final tri = Path()
        ..moveTo(-52, -4)
        ..lineTo(52, -4)
        ..lineTo(0, 40)
        ..close();
      c.drawPath(tri, _f(const Color(0xFFE53935)));
      for (final d in [const Offset(-20, 6), const Offset(14, 4), const Offset(-2, 22), const Offset(26, 12), const Offset(-30, -1)]) {
        c.drawCircle(d, 3.2, _f(const Color(0xFFFFFFFF)));
      }
      c.drawPath(tri, _s(const Color(0xFFB71C1C), 2));
    case 'bowtie':
      _bow(c, const Offset(0, 6), const Color(0xFF3949AB), 1.05, dots: true);
    case 'scarf':
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: const Offset(0, 0), width: 124, height: 24), const Radius.circular(12)), _f(const Color(0xFFFFB74D)));
      c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(18, 2, 24, 50), const Radius.circular(8)), _f(const Color(0xFFFFA726)));
      for (var i = 0; i < 4; i++) {
        c.drawLine(Offset(-50 + i * 30.0, -10), Offset(-44 + i * 30.0, 10), _s(const Color(0xFFE65100).withValues(alpha: 0.5), 4));
      }
      for (var i = 0; i < 4; i++) {
        c.drawLine(Offset(21 + i * 6.0, 52), Offset(21 + i * 6.0, 60), _s(const Color(0xFFFFA726), 3));
      }
    case 'bell':
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: const Offset(0, -2), width: 118, height: 14), const Radius.circular(7)), _f(const Color(0xFFE53935)));
      c.drawCircle(const Offset(0, 16), 15, _f(const Color(0xFFFFCA28)));
      c.drawCircle(const Offset(0, 16), 15, _s(const Color(0xFFF9A825), 2.5));
      c.drawLine(const Offset(-13, 15), const Offset(13, 15), _s(const Color(0xFFF9A825), 2.5));
      c.drawCircle(const Offset(0, 22), 3.5, _f(_ink));
      c.drawCircle(const Offset(-5, 10), 3.5, _f(const Color(0xAAFFFFFF)));
  }
  c.restore();
}

// ---------------------------------------------------------------- helpers
void _bow(Canvas c, Offset at, Color color, double scale, {bool dots = false}) {
  c.save();
  c.translate(at.dx, at.dy);
  c.scale(scale, scale);
  for (final side in [-1.0, 1.0]) {
    final wing = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(side * 22, -24, side * 38, -14)
      ..quadraticBezierTo(side * 44, 0, side * 38, 14)
      ..quadraticBezierTo(side * 22, 24, 0, 0)
      ..close();
    c.drawPath(wing, _f(color));
    c.drawPath(wing, _s(Color.lerp(color, const Color(0xFF000000), 0.25)!, 2));
    if (dots) {
      c.drawCircle(Offset(side * 22, -6), 3, _f(const Color(0xFFFFFFFF)));
      c.drawCircle(Offset(side * 28, 7), 3, _f(const Color(0xFFFFFFFF)));
    }
  }
  c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: 14, height: 16), const Radius.circular(5)), _f(Color.lerp(color, const Color(0xFF000000), 0.12)!));
  c.restore();
}

void _flower(Canvas c, Offset at, Color color, double r) {
  for (var i = 0; i < 5; i++) {
    final a = i / 5 * 2 * math.pi;
    c.drawCircle(at + Offset(math.cos(a) * r * 0.62, math.sin(a) * r * 0.62), r * 0.55, _f(color));
  }
  c.drawCircle(at, r * 0.42, _f(const Color(0xFFFFF59D)));
}

void _star(Canvas c, Offset at, double r, Color color, {double stroke = 0}) {
  final p = Path();
  for (var i = 0; i < 10; i++) {
    final a = -math.pi / 2 + i * math.pi / 5;
    final rr = i.isEven ? r : r * 0.48;
    final pt = at + Offset(math.cos(a) * rr, math.sin(a) * rr);
    i == 0 ? p.moveTo(pt.dx, pt.dy) : p.lineTo(pt.dx, pt.dy);
  }
  p.close();
  c.drawPath(p, stroke > 0 ? _s(color, stroke) : _f(color));
}

Path _heartPath(Offset c, double r) {
  return Path()
    ..moveTo(c.dx, c.dy + r * 0.85)
    ..cubicTo(c.dx - r * 1.4, c.dy - r * 0.1, c.dx - r * 0.75, c.dy - r * 1.15, c.dx, c.dy - r * 0.45)
    ..cubicTo(c.dx + r * 0.75, c.dy - r * 1.15, c.dx + r * 1.4, c.dy - r * 0.1, c.dx, c.dy + r * 0.85)
    ..close();
}

/// Public so particles (hearts) can reuse the exact same shape.
Path heartPath(Offset center, double radius) => _heartPath(center, radius);
void drawStar(Canvas c, Offset at, double r, Color color) => _star(c, at, r, color);
