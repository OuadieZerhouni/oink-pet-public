import 'dart:math' as math;

import 'package:flutter/rendering.dart';

import '../../pet/catalog.dart';
import 'accessories.dart';
import 'pig_pose.dart';

/// The pig's palette. One place, so the icon, the closet thumbnails and the
/// store screenshots can never drift from the pig itself.
class PigColors {
  const PigColors._();
  static const body = Color(0xFFFFB8CB);
  static const bodyLight = Color(0xFFFFD3DF);
  static const bodyShade = Color(0xFFF59AB4);
  static const outline = Color(0xFFDB6F93);
  static const snout = Color(0xFFFF97B5);
  static const snoutShade = Color(0xFFF07FA2);
  static const nostril = Color(0xFFB4436C);
  static const innerEar = Color(0xFFFF8DB0);
  static const hoof = Color(0xFFE97F9F);
  static const blush = Color(0xFFFF6F98);
  static const eye = Color(0xFF3A2430);
  static const mud = Color(0xFF8A5A3C);
  static const mudLight = Color(0xFFA9714B);
}

/// Paints the pig from a [PigPose]. Pure: same inputs, same pixels.
class PigPainter extends CustomPainter {
  PigPainter({
    required this.pose,
    required this.geometry,
    this.clean = 100,
    this.hat,
    this.glasses,
    this.neck,
    super.repaint,
  });

  final PigPose pose;
  final PigGeometry geometry;

  /// 0…100; below 70 mud spots start to show.
  final double clean;
  final String? hat;
  final String? glasses;
  final String? neck;

  /// Maps a design-space point to the painted canvas (used by hit testing).
  static Matrix4 designToCanvas(Size size) {
    final s = math.min(size.width / PigGeometry.designSize.width, size.height / PigGeometry.designSize.height);
    final dx = (size.width - PigGeometry.designSize.width * s) / 2;
    final dy = size.height - PigGeometry.designSize.height * s;
    return Matrix4.identity()
      ..translateByDouble(dx, dy, 0, 1)
      ..scaleByDouble(s, s, 1, 1);
  }

  static Offset canvasToDesign(Size size, Offset p) {
    final s = math.min(size.width / PigGeometry.designSize.width, size.height / PigGeometry.designSize.height);
    final dx = (size.width - PigGeometry.designSize.width * s) / 2;
    final dy = size.height - PigGeometry.designSize.height * s;
    return Offset((p.dx - dx) / s, (p.dy - dy) / s);
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.transform(designToCanvas(size).storage);
    final g = geometry;
    final p = pose;

    // Ground shadow (does not bounce, shrinks while hopping).
    final hop = (-p.bounce).clamp(0.0, 30.0) / 30.0;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(150, g.bodyCy + g.bodyRy - 2), width: g.bodyRx * (1.75 - 0.35 * hop), height: 18 * (1 - 0.3 * hop)),
      Paint()..color = const Color(0x22000000),
    );

    canvas.translate(0, p.bounce);

    _tail(canvas, g, p);
    _backLegs(canvas, g);
    _body(canvas, g, p);
    _frontHooves(canvas, g, p);

    // Head group: tilt + shake around the neck.
    final breathLift = -2.2 * p.breath;
    canvas.save();
    final pivot = g.headC + Offset(0, g.headR * 0.85);
    canvas.translate(pivot.dx, pivot.dy + breathLift);
    canvas.rotate(p.headTilt + p.shake);
    canvas.translate(-pivot.dx, -pivot.dy);
    _ears(canvas, g, p);
    _head(canvas, g);
    _mud(canvas, g, head: true);
    _cheeks(canvas, g, p);
    _eyes(canvas, g, p);
    _snout(canvas, g, p);
    _mouth(canvas, g, p);
    if (glasses != null) drawGlasses(canvas, glasses!, g.eyeL, g.eyeR, g.headR);
    if (hat != null) drawHat(canvas, hat!, g.crown, g.headR);
    if (neck != null) drawNeck(canvas, neck!, g.neck, g.headR);
    canvas.restore();

    canvas.restore();
  }

  // ------------------------------------------------------------------ parts
  Paint _fill(Color c) => Paint()..color = c;
  Paint get _stroke => Paint()
    ..color = PigColors.outline
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3
    ..strokeJoin = StrokeJoin.round
    ..strokeCap = StrokeCap.round;

  void _tail(Canvas c, PigGeometry g, PigPose p) {
    c.save();
    c.translate(g.tailBase.dx, g.tailBase.dy);
    c.rotate(-0.55 + p.tail);
    final path = Path()..moveTo(0, 0);
    // A small spiral curl.
    const turns = 1.35;
    for (var i = 1; i <= 40; i++) {
      final t = i / 40;
      final a = t * turns * 2 * math.pi;
      final r = 7 + 11 * (1 - t);
      path.lineTo(26 * t + r * math.cos(a) - r, -10 * t + r * math.sin(a));
    }
    c.drawPath(path, Paint()
      ..color = PigColors.outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7.5
      ..strokeCap = StrokeCap.round);
    c.drawPath(path, Paint()
      ..color = PigColors.body
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round);
    c.restore();
  }

  void _backLegs(Canvas c, PigGeometry g) {
    for (final side in [-1.0, 1.0]) {
      final center = Offset(150 + side * g.bodyRx * 0.78, g.bodyCy + g.bodyRy * 0.62);
      final r = Rect.fromCenter(center: center, width: g.bodyRx * 0.5, height: g.bodyRy * 0.62);
      c.drawOval(r, _fill(PigColors.bodyShade));
      c.drawOval(r, _stroke);
    }
  }

  void _body(Canvas c, PigGeometry g, PigPose p) {
    final squish = 1 + 0.025 * p.breath;
    final rect = Rect.fromCenter(center: g.bodyC, width: g.bodyRx * 2 / squish, height: g.bodyRy * 2 * squish);
    final shader = RadialGradient(
      center: const Alignment(-0.35, -0.5),
      radius: 1.0,
      colors: const [PigColors.bodyLight, PigColors.body, PigColors.bodyShade],
      stops: const [0.0, 0.55, 1.0],
    ).createShader(rect);
    c.drawOval(rect, Paint()..shader = shader);
    c.drawOval(rect, _stroke);
    // Belly patch
    final belly = Rect.fromCenter(center: g.bodyC + Offset(0, g.bodyRy * 0.22), width: g.bodyRx * 1.15, height: g.bodyRy * 1.05);
    c.drawOval(belly, _fill(PigColors.bodyLight.withValues(alpha: 0.85)));
    _mud(c, g, head: false);
  }

  void _frontHooves(Canvas c, PigGeometry g, PigPose p) {
    for (final side in [-1.0, 1.0]) {
      final kick = p.legKick * (side < 0 ? 1 : 0.6);
      final base = Offset(150 + side * g.bodyRx * 0.36, g.bodyCy + g.bodyRy * 0.86 - 10 * kick);
      final leg = RRect.fromRectAndRadius(Rect.fromCenter(center: base, width: g.bodyRx * 0.36, height: g.bodyRy * 0.42), const Radius.circular(16));
      c.drawRRect(leg, _fill(PigColors.body));
      c.drawRRect(leg, _stroke);
      // hoof tip
      final tip = Rect.fromCenter(center: base + Offset(0, g.bodyRy * 0.15), width: g.bodyRx * 0.3, height: g.bodyRy * 0.13);
      c.drawRRect(RRect.fromRectAndRadius(tip, const Radius.circular(8)), _fill(PigColors.hoof));
    }
  }

  void _ears(Canvas c, PigGeometry g, PigPose p) {
    for (final side in [-1.0, 1.0]) {
      final base = side < 0 ? g.earBaseL : g.earBaseR;
      final flop = side < 0 ? p.earLeft : p.earRight;
      c.save();
      c.translate(base.dx, base.dy);
      c.rotate(side * (0.38 + flop));
      final w = g.headR * 0.62, h = g.headR * 0.78;
      Path ear(double scale) {
        final ww = w * scale, hh = h * scale;
        return Path()
          ..moveTo(-ww / 2, 6)
          ..quadraticBezierTo(-ww * 0.45, -hh * 0.55, 0, -hh)
          ..quadraticBezierTo(ww * 0.45, -hh * 0.55, ww / 2, 6)
          ..close();
      }

      c.drawPath(ear(1), _fill(PigColors.body));
      c.drawPath(ear(1), _stroke);
      c.save();
      c.translate(0, -h * 0.08);
      c.drawPath(ear(0.62), _fill(PigColors.innerEar));
      c.restore();
      c.restore();
    }
  }

  void _head(Canvas c, PigGeometry g) {
    final rect = Rect.fromCircle(center: g.headC, radius: g.headR);
    final shader = RadialGradient(
      center: const Alignment(-0.3, -0.45),
      radius: 1.05,
      colors: const [PigColors.bodyLight, PigColors.body, PigColors.bodyShade],
      stops: const [0.0, 0.6, 1.0],
    ).createShader(rect);
    // Slightly squashed circle reads chubbier.
    final oval = Rect.fromCenter(center: g.headC, width: g.headR * 2.12, height: g.headR * 1.92);
    c.drawOval(oval, Paint()..shader = shader);
    c.drawOval(oval, _stroke);
  }

  void _cheeks(Canvas c, PigGeometry g, PigPose p) {
    if (p.blush <= 0.01) return;
    final paint = Paint()
      ..color = PigColors.blush.withValues(alpha: (0.55 * p.blush).clamp(0.0, 0.9))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    for (final side in [-1.0, 1.0]) {
      final center = g.headC + Offset(side * g.headR * 0.66, g.headR * 0.36);
      c.drawOval(Rect.fromCenter(center: center, width: g.headR * 0.38, height: g.headR * 0.22), paint);
    }
  }

  void _eyes(Canvas c, PigGeometry g, PigPose p) {
    final r = g.headR * 0.12;
    final ink = Paint()..color = PigColors.eye;
    final line = Paint()
      ..color = PigColors.eye
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.42
      ..strokeCap = StrokeCap.round;
    for (final side in [-1.0, 1.0]) {
      final e = side < 0 ? g.eyeL : g.eyeR;
      switch (p.eyes) {
        case EyeMode.happy:
          // ^ ^
          final path = Path()
            ..moveTo(e.dx - r, e.dy + r * 0.35)
            ..quadraticBezierTo(e.dx, e.dy - r * 1.2, e.dx + r, e.dy + r * 0.35);
          c.drawPath(path, line);
        case EyeMode.closed:
          final path = Path()
            ..moveTo(e.dx - r, e.dy - r * 0.1)
            ..quadraticBezierTo(e.dx, e.dy + r * 0.9, e.dx + r, e.dy - r * 0.1);
          c.drawPath(path, line);
        case EyeMode.sleepy:
          final path = Path()
            ..moveTo(e.dx - r, e.dy + r * 0.2)
            ..quadraticBezierTo(e.dx, e.dy + r * 0.85, e.dx + r, e.dy + r * 0.2);
          c.drawPath(path, line);
          // lashes
          for (final k in [-0.6, 0.0, 0.6]) {
            c.drawLine(Offset(e.dx + k * r, e.dy + r * 0.55), Offset(e.dx + k * r * 1.3, e.dy + r * 0.95), line..strokeWidth = r * 0.22);
          }
          line.strokeWidth = r * 0.42;
        case EyeMode.squint:
          // > <
          final s = side;
          final path = Path()
            ..moveTo(e.dx - r * 0.8 * s, e.dy - r * 0.7)
            ..lineTo(e.dx + r * 0.6 * s, e.dy)
            ..lineTo(e.dx - r * 0.8 * s, e.dy + r * 0.7);
          c.drawPath(path, line);
        case EyeMode.open:
        case EyeMode.surprised:
        case EyeMode.sad:
          final big = p.eyes == EyeMode.surprised ? 1.25 : 1.0;
          final openAmt = (1 - p.blink).clamp(0.08, 1.0);
          final rect = Rect.fromCenter(center: e, width: r * 1.8 * big, height: r * 2.2 * big * openAmt);
          c.drawOval(rect, ink);
          if (openAmt > 0.35) {
            final look = Offset(p.look.dx * r * 0.25, p.look.dy * r * 0.2);
            c.drawCircle(e + look + Offset(-r * 0.32, -r * 0.45 * openAmt), r * 0.38 * big, Paint()..color = const Color(0xFFFFFFFF));
            c.drawCircle(e + look + Offset(r * 0.35, r * 0.3 * openAmt), r * 0.16 * big, Paint()..color = const Color(0xCCFFFFFF));
          }
          if (p.eyes == EyeMode.sad) {
            // worried brow
            final brow = Path()
              ..moveTo(e.dx - r * 1.1 * side, e.dy - r * 2.35)
              ..quadraticBezierTo(e.dx - r * 0.1 * side, e.dy - r * 2.2, e.dx + r * 1.0 * side, e.dy - r * 1.6);
            c.drawPath(brow, line..strokeWidth = r * 0.3);
            line.strokeWidth = r * 0.42;
          }
      }
    }
  }

  void _snout(Canvas c, PigGeometry g, PigPose p) {
    final sq = p.snoutSquish.clamp(0.0, 1.0);
    final w = g.snoutR.width * 2 * (1 + 0.16 * sq);
    final h = g.snoutR.height * 2 * (1 - 0.18 * sq);
    final rect = Rect.fromCenter(center: g.snoutC, width: w, height: h);
    final shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: const [PigColors.snout, PigColors.snoutShade],
    ).createShader(rect);
    c.drawOval(rect, Paint()..shader = shader);
    c.drawOval(rect, _stroke..strokeWidth = 2.6);
    // shine
    c.drawOval(
      Rect.fromCenter(center: g.snoutC + Offset(-w * 0.18, -h * 0.26), width: w * 0.28, height: h * 0.16),
      Paint()..color = const Color(0x66FFFFFF),
    );
    for (final side in [-1.0, 1.0]) {
      final n = g.snoutC + Offset(side * w * 0.2, h * 0.04);
      c.drawOval(Rect.fromCenter(center: n, width: w * 0.12, height: h * 0.36 * (1 - 0.25 * sq)), _fill(PigColors.nostril));
    }
  }

  void _mouth(Canvas c, PigGeometry g, PigPose p) {
    final m = g.mouthC;
    final r = g.headR * 0.1;
    final line = Paint()
      ..color = PigColors.eye
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round;
    switch (p.mouth) {
      case MouthMode.smile:
        // little "w"
        final path = Path()
          ..moveTo(m.dx - r * 1.2, m.dy - r * 0.2)
          ..quadraticBezierTo(m.dx - r * 0.6, m.dy + r * 0.7, m.dx, m.dy - r * 0.05)
          ..quadraticBezierTo(m.dx + r * 0.6, m.dy + r * 0.7, m.dx + r * 1.2, m.dy - r * 0.2);
        c.drawPath(path, line);
      case MouthMode.frown:
        final path = Path()
          ..moveTo(m.dx - r * 0.9, m.dy + r * 0.45)
          ..quadraticBezierTo(m.dx, m.dy - r * 0.35, m.dx + r * 0.9, m.dy + r * 0.45);
        c.drawPath(path, line);
      case MouthMode.oink:
      case MouthMode.open:
      case MouthMode.munch:
        final open = p.mouth == MouthMode.munch ? 0.25 + 0.75 * p.mouthOpen : 0.45 + 0.55 * p.mouthOpen;
        final rect = Rect.fromCenter(center: m + Offset(0, r * 0.25), width: r * (p.mouth == MouthMode.oink ? 1.5 : 2.1), height: r * 1.7 * open);
        c.drawOval(rect, _fill(const Color(0xFF6B2340)));
        // tongue
        c.save();
        c.clipPath(Path()..addOval(rect));
        c.drawOval(Rect.fromCenter(center: rect.bottomCenter, width: rect.width * 0.8, height: rect.height * 0.8), _fill(const Color(0xFFFF7F9E)));
        c.restore();
    }
  }

  /// Deterministic mud splotches. Each appears once Clean drops below its
  /// threshold and fades in over the next 10 points.
  static const _mudSpots = <(bool head, double x, double y, double r, double threshold)>[
    (false, -0.45, -0.15, 0.20, 70),
    (false, 0.5, 0.15, 0.17, 60),
    (true, 0.5, -0.45, 0.17, 55),
    (false, -0.15, 0.45, 0.16, 48),
    (true, -0.62, 0.1, 0.14, 40),
    (false, 0.65, -0.35, 0.13, 32),
    (true, 0.15, -0.72, 0.12, 25),
    (false, -0.7, 0.4, 0.12, 18),
  ];

  void _mud(Canvas c, PigGeometry g, {required bool head}) {
    if (clean >= 70) return;
    for (final s in _mudSpots) {
      if (s.$1 != head) continue;
      final a = ((s.$5 - clean) / 10).clamp(0.0, 1.0);
      if (a <= 0) continue;
      final center = head
          ? g.headC + Offset(s.$2 * g.headR, s.$3 * g.headR)
          : g.bodyC + Offset(s.$2 * g.bodyRx, s.$3 * g.bodyRy);
      final r = s.$4 * (head ? g.headR : g.bodyRx);
      final path = Path();
      // Blobby splat: 7 bumps
      for (var i = 0; i <= 14; i++) {
        final ang = i / 14 * 2 * math.pi;
        final rr = r * (1 + 0.18 * math.sin(ang * 3 + s.$2 * 7));
        final pt = center + Offset(math.cos(ang) * rr, math.sin(ang) * rr * 0.82);
        i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
      }
      path.close();
      c.drawPath(path, _fill(PigColors.mud.withValues(alpha: 0.9 * a)));
      c.drawCircle(center + Offset(-r * 0.3, -r * 0.3), r * 0.25, _fill(PigColors.mudLight.withValues(alpha: 0.7 * a)));
    }
  }

  @override
  bool shouldRepaint(PigPainter old) => true;
}
