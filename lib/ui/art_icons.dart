import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Every small illustration in the app (food, game items, gift, sponge),
/// drawn in the same soft-outline style as the pig. Drawn rather than emoji
/// so the art is identical on every device and in store screenshots.
enum ArtIcon { apple, carrot, corn, lettuce, watermelon, strawberry, cupcake, donut, pumpkin, cookie, star, bee, gift, sponge, acorn }

ArtIcon artIconForFood(String id) => ArtIcon.values.firstWhere((a) => a.name == id, orElse: () => ArtIcon.apple);

class ArtIconView extends StatelessWidget {
  const ArtIconView(this.icon, {super.key, this.size = 40});
  final ArtIcon icon;
  final double size;

  @override
  Widget build(BuildContext context) => CustomPaint(size: Size.square(size), painter: ArtIconPainter(icon));
}

class ArtIconPainter extends CustomPainter {
  const ArtIconPainter(this.icon);
  final ArtIcon icon;

  /// Paints [icon] centred in a [size] square at [origin] — reusable from
  /// other painters (the mini-game draws dozens per frame).
  static void paintAt(Canvas c, ArtIcon icon, Offset origin, double size) {
    c.save();
    c.translate(origin.dx, origin.dy);
    c.scale(size / 100, size / 100);
    _draw(c, icon);
    c.restore();
  }

  @override
  void paint(Canvas c, Size s) => paintAt(c, icon, Offset.zero, math.min(s.width, s.height));

  @override
  bool shouldRepaint(ArtIconPainter old) => old.icon != icon;
}

// --------------------------------------------------------------- drawing
// Everything below draws in a 100×100 box.
Paint _f(Color c) => Paint()..color = c;
Paint _s(Color c, [double w = 4]) => Paint()
  ..color = c
  ..style = PaintingStyle.stroke
  ..strokeWidth = w
  ..strokeJoin = StrokeJoin.round
  ..strokeCap = StrokeCap.round;
void _shine(Canvas c, Offset at, double rx, double ry) =>
    c.drawOval(Rect.fromCenter(center: at, width: rx * 2, height: ry * 2), _f(const Color(0x88FFFFFF)));

void _draw(Canvas c, ArtIcon icon) {
  switch (icon) {
    case ArtIcon.apple:
      _apple(c, const Color(0xFFFF5A5F), const Color(0xFFC9303A));
    case ArtIcon.carrot:
      final body = Path()
        ..moveTo(30, 34)
        ..quadraticBezierTo(50, 26, 70, 36)
        ..quadraticBezierTo(62, 70, 46, 94)
        ..quadraticBezierTo(34, 66, 30, 34)
        ..close();
      for (final (dx, ang) in [(-10.0, -0.5), (0.0, 0.0), (10.0, 0.5)]) {
        c.save();
        c.translate(50 + dx, 32);
        c.rotate(ang);
        final leaf = Path()
          ..moveTo(0, 0)
          ..quadraticBezierTo(-8, -14, 0, -26)
          ..quadraticBezierTo(8, -14, 0, 0)
          ..close();
        c.drawPath(leaf, _f(const Color(0xFF6CC56A)));
        c.drawPath(leaf, _s(const Color(0xFF3E9442), 3));
        c.restore();
      }
      c.drawPath(body, _f(const Color(0xFFFF9A3C)));
      c.drawPath(body, _s(const Color(0xFFD9681A)));
      for (final y in [48.0, 60.0, 72.0]) {
        c.drawLine(Offset(40 + (y - 48) * 0.1, y), Offset(50, y + 2), _s(const Color(0xFFD9681A), 3));
      }
    case ArtIcon.corn:
      c.save();
      c.translate(50, 52);
      c.rotate(-0.35);
      final cob = RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: 34, height: 72), const Radius.circular(17));
      c.drawRRect(cob, _f(const Color(0xFFFFD34E)));
      for (var y = -28.0; y <= 28; y += 9) {
        for (var x = -10.0; x <= 10; x += 10) {
          c.drawCircle(Offset(x, y), 3.6, _f(const Color(0xFFF5B82E)));
        }
      }
      c.drawRRect(cob, _s(const Color(0xFFD99A1F)));
      for (final side in [-1.0, 1.0]) {
        final husk = Path()
          ..moveTo(side * 4, 40)
          ..quadraticBezierTo(side * 30, 20, side * 18, -20)
          ..quadraticBezierTo(side * 22, 14, side * 2, 30)
          ..close();
        c.drawPath(husk, _f(const Color(0xFF7CCB6B)));
        c.drawPath(husk, _s(const Color(0xFF479A45), 3));
      }
      c.restore();
    case ArtIcon.lettuce:
      for (var i = 0; i < 7; i++) {
        final a = -math.pi / 2 + (i - 3) * 0.42;
        final p = Offset(50 + math.cos(a) * 18, 58 + math.sin(a) * 18);
        c.drawCircle(p, 22, _f(i.isEven ? const Color(0xFF8BD67A) : const Color(0xFF6CC56A)));
      }
      c.drawCircle(const Offset(50, 64), 22, _f(const Color(0xFFB9EBA0)));
      c.drawLine(const Offset(50, 86), const Offset(50, 48), _s(const Color(0xFF479A45), 3));
    case ArtIcon.watermelon:
      final slice = Path()
        ..moveTo(10, 36)
        ..arcToPoint(const Offset(90, 36), radius: const Radius.circular(40), clockwise: false)
        ..close();
      c.drawPath(slice, _f(const Color(0xFF5EC46A)));
      final flesh = Path()
        ..moveTo(17, 38)
        ..arcToPoint(const Offset(83, 38), radius: const Radius.circular(33), clockwise: false)
        ..close();
      c.drawPath(flesh, _f(const Color(0xFFFF6B7D)));
      for (final p in [const Offset(36, 50), const Offset(50, 58), const Offset(64, 50), const Offset(44, 66), const Offset(58, 66)]) {
        c.drawOval(Rect.fromCenter(center: p, width: 5, height: 8), _f(const Color(0xFF3A2430)));
      }
      c.drawPath(slice, _s(const Color(0xFF2F8F43)));
    case ArtIcon.strawberry:
      final berry = Path()
        ..moveTo(50, 92)
        ..cubicTo(14, 66, 18, 30, 50, 34)
        ..cubicTo(82, 30, 86, 66, 50, 92)
        ..close();
      c.drawPath(berry, _f(const Color(0xFFFF4F6D)));
      c.drawPath(berry, _s(const Color(0xFFC92C4B)));
      for (final p in [const Offset(38, 50), const Offset(56, 48), const Offset(46, 62), const Offset(62, 64), const Offset(36, 70), const Offset(52, 78)]) {
        c.drawOval(Rect.fromCenter(center: p, width: 4, height: 6), _f(const Color(0xFFFFE8A3)));
      }
      for (var i = 0; i < 5; i++) {
        final a = -math.pi / 2 + (i - 2) * 0.6;
        final leaf = Path()
          ..moveTo(50, 36)
          ..lineTo(50 + math.cos(a - 0.25) * 10, 36 + math.sin(a - 0.25) * 10 - 4)
          ..lineTo(50 + math.cos(a) * 20, 36 + math.sin(a) * 12 - 6)
          ..close();
        c.drawPath(leaf, _f(const Color(0xFF5EC46A)));
      }
      _shine(c, const Offset(38, 46), 6, 4);
    case ArtIcon.cupcake:
      final cup = Path()
        ..moveTo(24, 54)
        ..lineTo(76, 54)
        ..lineTo(68, 92)
        ..lineTo(32, 92)
        ..close();
      c.drawPath(cup, _f(const Color(0xFF7CC6F2)));
      for (var x = 32.0; x <= 68; x += 9) {
        c.drawLine(Offset(x, 56), Offset(x + (50 - x) * 0.15, 90), _s(const Color(0xFF4E9ED0), 3));
      }
      c.drawPath(cup, _s(const Color(0xFF4E9ED0)));
      final frost = Path()
        ..moveTo(20, 56)
        ..quadraticBezierTo(18, 36, 36, 34)
        ..quadraticBezierTo(42, 16, 58, 24)
        ..quadraticBezierTo(80, 26, 80, 56)
        ..close();
      c.drawPath(frost, _f(const Color(0xFFFFB3CB)));
      c.drawPath(frost, _s(const Color(0xFFE57399)));
      c.drawCircle(const Offset(54, 16), 7, _f(const Color(0xFFFF4F6D)));
      for (final (p, col) in [(const Offset(36, 44), const Color(0xFFFFD54F)), (const Offset(60, 40), const Color(0xFF8BD67A)), (const Offset(48, 50), const Color(0xFFB39DDB))]) {
        c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: p, width: 7, height: 3), const Radius.circular(2)), _f(col));
      }
    case ArtIcon.donut:
      c.drawCircle(const Offset(50, 54), 38, _f(const Color(0xFFE6A15C)));
      final icing = Path()
        ..addOval(Rect.fromCircle(center: const Offset(50, 52), radius: 33))
        ..addOval(Rect.fromCircle(center: const Offset(50, 52), radius: 12))
        ..fillType = PathFillType.evenOdd;
      c.drawPath(icing, _f(const Color(0xFFFF8FB8)));
      c.drawCircle(const Offset(50, 54), 13, _f(const Color(0xFFFFF6EC)));
      c.drawCircle(const Offset(50, 54), 38, _s(const Color(0xFFB9763A)));
      c.drawCircle(const Offset(50, 54), 13, _s(const Color(0xFFB9763A), 3));
      final rnd = math.Random(4);
      const sprinkles = [Color(0xFFFFD54F), Color(0xFF7CC6F2), Color(0xFF8BD67A), Color(0xFFFFFFFF)];
      for (var i = 0; i < 12; i++) {
        final a = rnd.nextDouble() * 2 * math.pi;
        final r = 18 + rnd.nextDouble() * 12;
        final p = Offset(50 + math.cos(a) * r, 52 + math.sin(a) * r);
        c.save();
        c.translate(p.dx, p.dy);
        c.rotate(rnd.nextDouble() * math.pi);
        c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-4, -1.5, 8, 3), const Radius.circular(1.5)), _f(sprinkles[i % 4]));
        c.restore();
      }
    case ArtIcon.pumpkin:
      for (final (x, w) in [(30.0, 34.0), (70.0, 34.0), (50.0, 40.0)]) {
        c.drawOval(Rect.fromCenter(center: Offset(x, 60), width: w, height: 60), _f(const Color(0xFFFF9A3C)));
        c.drawOval(Rect.fromCenter(center: Offset(x, 60), width: w, height: 60), _s(const Color(0xFFD9681A), 3));
      }
      c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(46, 20, 9, 16), const Radius.circular(3)), _f(const Color(0xFF6D4C41)));
      _shine(c, const Offset(42, 44), 5, 8);
    case ArtIcon.cookie:
      c.drawCircle(const Offset(50, 52), 38, _f(const Color(0xFFE2B06E)));
      c.drawCircle(const Offset(50, 52), 38, _s(const Color(0xFFB9824A)));
      for (final p in [const Offset(36, 40), const Offset(60, 36), const Offset(66, 58), const Offset(42, 64), const Offset(54, 74), const Offset(30, 56)]) {
        c.drawCircle(p, 5, _f(const Color(0xFF6D4C41)));
      }
    case ArtIcon.star:
      final p = Path();
      for (var i = 0; i < 10; i++) {
        final a = -math.pi / 2 + i * math.pi / 5;
        final r = i.isEven ? 44.0 : 20.0;
        final pt = Offset(50 + math.cos(a) * r, 54 + math.sin(a) * r);
        i == 0 ? p.moveTo(pt.dx, pt.dy) : p.lineTo(pt.dx, pt.dy);
      }
      p.close();
      c.drawPath(p, _f(const Color(0xFFFFD54F)));
      c.drawPath(p, _s(const Color(0xFFF5A623)));
      _shine(c, const Offset(42, 44), 5, 3);
      // cute face
      c.drawCircle(const Offset(43, 56), 3, _f(const Color(0xFF6B3A1E)));
      c.drawCircle(const Offset(57, 56), 3, _f(const Color(0xFF6B3A1E)));
      c.drawArc(Rect.fromCenter(center: const Offset(50, 60), width: 8, height: 6), 0.2, math.pi - 0.4, false, _s(const Color(0xFF6B3A1E), 2));
    case ArtIcon.bee:
      for (final side in [-1.0, 1.0]) {
        c.drawOval(Rect.fromCenter(center: Offset(50 + side * 14, 32), width: 22, height: 28), _f(const Color(0xCCE3F4FF)));
        c.drawOval(Rect.fromCenter(center: Offset(50 + side * 14, 32), width: 22, height: 28), _s(const Color(0xFF9CC8E0), 2.5));
      }
      final body = Rect.fromCenter(center: const Offset(50, 58), width: 58, height: 44);
      c.drawOval(body, _f(const Color(0xFFFFD34E)));
      c.save();
      c.clipPath(Path()..addOval(body));
      for (final x in [38.0, 54.0, 70.0]) {
        c.drawRect(Rect.fromLTWH(x - 5, 30, 9, 60), _f(const Color(0xFF3A2430)));
      }
      c.restore();
      c.drawOval(body, _s(const Color(0xFF3A2430)));
      c.drawCircle(const Offset(30, 54), 4, _f(const Color(0xFF3A2430)));
      c.drawCircle(const Offset(31, 52.5), 1.4, _f(const Color(0xFFFFFFFF)));
      c.drawPath(
        Path()
          ..moveTo(78, 56)
          ..lineTo(90, 58)
          ..lineTo(78, 62)
          ..close(),
        _f(const Color(0xFF3A2430)),
      );
    case ArtIcon.gift:
      const box = Rect.fromLTWH(18, 44, 64, 46);
      c.drawRRect(RRect.fromRectAndRadius(box, const Radius.circular(8)), _f(const Color(0xFFFF7FA3)));
      c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(12, 32, 76, 18), const Radius.circular(6)), _f(const Color(0xFFFF9AB6)));
      c.drawRect(const Rect.fromLTWH(44, 32, 12, 58), _f(const Color(0xFFFFD54F)));
      c.drawRRect(RRect.fromRectAndRadius(box, const Radius.circular(8)), _s(const Color(0xFFE85A86)));
      c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(12, 32, 76, 18), const Radius.circular(6)), _s(const Color(0xFFE85A86)));
      for (final side in [-1.0, 1.0]) {
        final loop = Path()
          ..moveTo(50, 32)
          ..quadraticBezierTo(50 + side * 34, 4, 50 + side * 10, 30)
          ..close();
        c.drawPath(loop, _f(const Color(0xFFFFD54F)));
        c.drawPath(loop, _s(const Color(0xFFF5A623), 3));
      }
    case ArtIcon.sponge:
      c.save();
      c.translate(50, 54);
      c.rotate(-0.2);
      final rr = RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: 70, height: 46), const Radius.circular(12));
      c.drawRRect(rr, _f(const Color(0xFFFFE066)));
      c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-35, 8, 70, 15), const Radius.circular(8)), _f(const Color(0xFF7CCB6B)));
      for (final p in [const Offset(-20, -10), const Offset(4, -14), const Offset(18, -4), const Offset(-6, 0), const Offset(24, -15)]) {
        c.drawCircle(p, 3.5, _f(const Color(0xFFF0C24A)));
      }
      c.drawRRect(rr, _s(const Color(0xFFD9A62E)));
      c.restore();
      for (final (p, r) in [(const Offset(80, 22), 9.0), (const Offset(66, 12), 6.0), (const Offset(88, 38), 5.0)]) {
        c.drawCircle(p, r, _f(const Color(0xAAFFFFFF)));
        c.drawCircle(p, r, _s(const Color(0xFF8FD3F7), 2));
      }
    case ArtIcon.acorn:
      c.drawOval(const Rect.fromLTWH(22, 34, 56, 58), _f(const Color(0xFFC98A4B)));
      c.drawOval(const Rect.fromLTWH(22, 34, 56, 58), _s(const Color(0xFF8E5A2B)));
      _shine(c, const Offset(38, 54), 6, 10);
      c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(16, 24, 68, 22), const Radius.circular(11)), _f(const Color(0xFF7A4A24)));
      c.drawLine(const Offset(50, 24), const Offset(56, 8), _s(const Color(0xFF7A4A24), 6));
  }
}

void _apple(Canvas c, Color body, Color dark) {
  final path = Path()
    ..moveTo(50, 32)
    ..cubicTo(30, 18, 8, 34, 14, 60)
    ..cubicTo(20, 86, 40, 96, 50, 88)
    ..cubicTo(60, 96, 80, 86, 86, 60)
    ..cubicTo(92, 34, 70, 18, 50, 32)
    ..close();
  c.drawPath(path, _f(body));
  c.drawPath(path, _s(dark));
  c.drawLine(const Offset(50, 32), const Offset(54, 14), _s(const Color(0xFF6D4C41), 4.5));
  final leaf = Path()
    ..moveTo(55, 20)
    ..quadraticBezierTo(70, 8, 80, 18)
    ..quadraticBezierTo(68, 28, 55, 20)
    ..close();
  c.drawPath(leaf, _f(const Color(0xFF6CC56A)));
  c.drawPath(leaf, _s(const Color(0xFF3E9442), 2.5));
  _shine(c, const Offset(32, 48), 6, 10);
}
