import 'dart:math' as math;

import 'package:flutter/rendering.dart';

/// Paints a room behind the pig. Rooms are drawn, not bitmaps, so they stay
/// crisp on every iPhone and weigh nothing. [night] dims everything and adds
/// stars (the pig is asleep).
class RoomPainter extends CustomPainter {
  RoomPainter(this.room, {this.night = 0, this.floorY = 0.72});

  final String room;

  /// 0 = day, 1 = full night.
  final double night;

  /// Fraction of the height where the floor/ground line sits.
  final double floorY;

  @override
  void paint(Canvas c, Size s) {
    switch (room) {
      case 'meadow':
        _meadow(c, s);
      case 'bedroom':
        _bedroom(c, s);
      case 'beach':
        _beach(c, s);
      case 'snow':
        _snow(c, s);
      default:
        _barn(c, s);
    }
    if (night > 0.01) _night(c, s);
  }

  Paint _f(Color c) => Paint()..color = c;

  void _sky(Canvas c, Size s, List<Color> colors) {
    final r = Offset.zero & s;
    c.drawRect(r, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: colors).createShader(r));
  }

  void _cloud(Canvas c, Offset at, double w, {Color color = const Color(0xFFFFFFFF)}) {
    final p = _f(color.withValues(alpha: 0.92));
    c.drawCircle(at, w * 0.22, p);
    c.drawCircle(at + Offset(w * 0.22, -w * 0.08), w * 0.27, p);
    c.drawCircle(at + Offset(w * 0.46, 0), w * 0.2, p);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(at.dx - w * 0.1, at.dy - w * 0.02, w * 0.68, w * 0.22), Radius.circular(w * 0.11)), p);
  }

  void _barn(Canvas c, Size s) {
    final floor = s.height * floorY;
    // Wooden plank wall
    c.drawRect(Rect.fromLTWH(0, 0, s.width, floor), _f(const Color(0xFFF7D9B5)));
    final plank = Paint()
      ..color = const Color(0xFFE9C59A)
      ..strokeWidth = 2;
    for (var x = 0.0; x < s.width; x += s.width / 7) {
      c.drawLine(Offset(x, 0), Offset(x, floor), plank);
    }
    // Window with sky
    final win = Rect.fromCenter(center: Offset(s.width * 0.8, floor * 0.5), width: s.width * 0.26, height: s.width * 0.22);
    c.drawRRect(RRect.fromRectAndRadius(win.inflate(8), const Radius.circular(14)), _f(const Color(0xFFC98E5D)));
    c.drawRRect(RRect.fromRectAndRadius(win, const Radius.circular(10)), _f(const Color(0xFFBFE6FF)));
    _cloud(c, win.center + Offset(-win.width * 0.25, win.height * 0.05), win.width * 0.5);
    final bar = Paint()
      ..color = const Color(0xFFC98E5D)
      ..strokeWidth = 5;
    c.drawLine(win.topCenter, win.bottomCenter, bar);
    c.drawLine(win.centerLeft, win.centerRight, bar);
    // Floor + hay
    c.drawRect(Rect.fromLTWH(0, floor, s.width, s.height - floor), _f(const Color(0xFFE8B97A)));
    c.drawRect(Rect.fromLTWH(0, floor, s.width, 6), _f(const Color(0xFFD9A262)));
    final straw = Paint()
      ..color = const Color(0xFFF4D28A)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    final rnd = math.Random(7);
    for (var i = 0; i < 70; i++) {
      final x = rnd.nextDouble() * s.width, y = floor + 10 + rnd.nextDouble() * (s.height - floor - 10);
      final a = rnd.nextDouble() * math.pi;
      c.drawLine(Offset(x, y), Offset(x + math.cos(a) * 12, y + math.sin(a) * 4), straw);
    }
    // Hay bale left
    final bale = RRect.fromRectAndRadius(Rect.fromLTWH(s.width * 0.04, floor - s.width * 0.16, s.width * 0.24, s.width * 0.18), const Radius.circular(12));
    c.drawRRect(bale, _f(const Color(0xFFF2C766)));
    for (var i = 1; i < 4; i++) {
      final y = bale.top + bale.height * i / 4;
      c.drawLine(Offset(bale.left + 6, y), Offset(bale.right - 6, y), _f(const Color(0xFFDDAB45))..strokeWidth = 2);
    }
  }

  void _meadow(Canvas c, Size s) {
    _sky(c, s, const [Color(0xFF9EDBFF), Color(0xFFD9F2FF)]);
    c.drawCircle(Offset(s.width * 0.82, s.height * 0.12), s.width * 0.09, _f(const Color(0xFFFFE07A)));
    _cloud(c, Offset(s.width * 0.12, s.height * 0.14), s.width * 0.34);
    _cloud(c, Offset(s.width * 0.55, s.height * 0.24), s.width * 0.26);
    final floor = s.height * floorY;
    final hill = Path()
      ..moveTo(0, floor - 30)
      ..quadraticBezierTo(s.width * 0.3, floor - 80, s.width * 0.6, floor - 25)
      ..quadraticBezierTo(s.width * 0.82, floor - 2, s.width, floor - 40)
      ..lineTo(s.width, s.height)
      ..lineTo(0, s.height)
      ..close();
    c.drawPath(hill, _f(const Color(0xFF9BDB86)));
    c.drawRect(Rect.fromLTWH(0, floor, s.width, s.height - floor), _f(const Color(0xFF7DCB6A)));
    final rnd = math.Random(3);
    const petals = [Color(0xFFFFFFFF), Color(0xFFFFD54F), Color(0xFFFF8FB1), Color(0xFFB39DDB)];
    for (var i = 0; i < 26; i++) {
      final p = Offset(rnd.nextDouble() * s.width, floor + 8 + rnd.nextDouble() * (s.height - floor - 12));
      final col = petals[i % petals.length];
      for (var k = 0; k < 5; k++) {
        final a = k / 5 * 2 * math.pi;
        c.drawCircle(p + Offset(math.cos(a) * 4, math.sin(a) * 4), 3.2, _f(col));
      }
      c.drawCircle(p, 2.4, _f(const Color(0xFFFFC107)));
    }
  }

  void _bedroom(Canvas c, Size s) {
    final floor = s.height * floorY;
    c.drawRect(Rect.fromLTWH(0, 0, s.width, floor), _f(const Color(0xFFFFE3EC)));
    final dot = _f(const Color(0xFFFFCADB));
    for (var y = 20.0; y < floor; y += 46) {
      for (var x = (y ~/ 46).isEven ? 20.0 : 43.0; x < s.width; x += 46) {
        c.drawCircle(Offset(x, y), 5, dot);
      }
    }
    // Round window with moon
    final w = Offset(s.width * 0.18, floor * 0.48);
    c.drawCircle(w, s.width * 0.13, _f(const Color(0xFFE7B4C6)));
    c.drawCircle(w, s.width * 0.11, _f(const Color(0xFF8FB8F0)));
    c.drawCircle(w + Offset(s.width * 0.03, -s.width * 0.02), s.width * 0.04, _f(const Color(0xFFFFF3B0)));
    // Shelf with plush
    final shelfY = floor * 0.56;
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(s.width * 0.62, shelfY, s.width * 0.32, 10), const Radius.circular(5)), _f(const Color(0xFFD9A3B6)));
    c.drawCircle(Offset(s.width * 0.7, shelfY - 16), 16, _f(const Color(0xFFFFF0B3)));
    c.drawCircle(Offset(s.width * 0.84, shelfY - 13), 13, _f(const Color(0xFFB9E4C9)));
    // Floor + rug
    c.drawRect(Rect.fromLTWH(0, floor, s.width, s.height - floor), _f(const Color(0xFFE9C9B0)));
    c.drawOval(Rect.fromCenter(center: Offset(s.width / 2, floor + (s.height - floor) * 0.45), width: s.width * 0.8, height: (s.height - floor) * 0.6), _f(const Color(0xFFC9B8F2)));
    c.drawOval(Rect.fromCenter(center: Offset(s.width / 2, floor + (s.height - floor) * 0.45), width: s.width * 0.62, height: (s.height - floor) * 0.42), _f(const Color(0xFFDCCFFA)));
  }

  void _beach(Canvas c, Size s) {
    _sky(c, s, const [Color(0xFF7FD0FF), Color(0xFFCDEEFF)]);
    c.drawCircle(Offset(s.width * 0.18, s.height * 0.13), s.width * 0.1, _f(const Color(0xFFFFD25E)));
    _cloud(c, Offset(s.width * 0.55, s.height * 0.12), s.width * 0.3);
    final floor = s.height * floorY;
    final sea = Rect.fromLTWH(0, floor - s.height * 0.16, s.width, s.height * 0.16);
    c.drawRect(sea, _f(const Color(0xFF4FB8E6)));
    final wave = Paint()
      ..color = const Color(0xCCFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (var x = 10.0; x < s.width; x += 60) {
      c.drawArc(Rect.fromCenter(center: Offset(x, sea.top + sea.height * 0.5), width: 30, height: 12), math.pi, math.pi, false, wave);
    }
    c.drawRect(Rect.fromLTWH(0, floor - 8, s.width, s.height - floor + 8), _f(const Color(0xFFFFE2A8)));
    // Umbrella
    final pole = Offset(s.width * 0.86, floor + 20);
    c.drawLine(pole, pole - Offset(0, s.height * 0.3), _f(const Color(0xFF9C6B3F))..strokeWidth = 5);
    final top = pole - Offset(0, s.height * 0.3);
    final umb = Path()
      ..moveTo(top.dx - 70, top.dy + 18)
      ..quadraticBezierTo(top.dx, top.dy - 60, top.dx + 70, top.dy + 18)
      ..close();
    c.drawPath(umb, _f(const Color(0xFFFF6F91)));
    c.save();
    c.clipPath(umb);
    for (var i = -2; i < 3; i += 2) {
      c.drawRect(Rect.fromLTWH(top.dx + i * 14.0, top.dy - 60, 14, 90), _f(const Color(0xFFFFFFFF)));
    }
    c.restore();
    // Shells
    c.drawCircle(Offset(s.width * 0.14, floor + 40), 7, _f(const Color(0xFFFFB6A3)));
    c.drawCircle(Offset(s.width * 0.3, floor + 70), 5, _f(const Color(0xFFFFFFFF)));
  }

  void _snow(Canvas c, Size s) {
    _sky(c, s, const [Color(0xFFB9D7F2), Color(0xFFE7F2FB)]);
    final floor = s.height * floorY;
    for (final (x, h) in [(0.12, 0.26), (0.84, 0.3), (0.95, 0.2)]) {
      final base = Offset(s.width * x, floor + 4);
      final tri = Path()
        ..moveTo(base.dx - 34, base.dy)
        ..lineTo(base.dx, base.dy - s.height * h)
        ..lineTo(base.dx + 34, base.dy)
        ..close();
      c.drawPath(tri, _f(const Color(0xFF4F9D7A)));
      c.drawPath(
        Path()
          ..moveTo(base.dx - 14, base.dy - s.height * h * 0.62)
          ..lineTo(base.dx, base.dy - s.height * h)
          ..lineTo(base.dx + 14, base.dy - s.height * h * 0.62)
          ..close(),
        _f(const Color(0xFFFFFFFF)),
      );
    }
    final ground = Path()
      ..moveTo(0, floor - 10)
      ..quadraticBezierTo(s.width * 0.5, floor - 34, s.width, floor - 6)
      ..lineTo(s.width, s.height)
      ..lineTo(0, s.height)
      ..close();
    c.drawPath(ground, _f(const Color(0xFFFFFFFF)));
    final rnd = math.Random(11);
    for (var i = 0; i < 40; i++) {
      c.drawCircle(Offset(rnd.nextDouble() * s.width, rnd.nextDouble() * floor), 1.5 + rnd.nextDouble() * 2.5, _f(const Color(0xDDFFFFFF)));
    }
  }

  void _night(Canvas c, Size s) {
    c.drawRect(Offset.zero & s, _f(const Color(0xFF1C1640).withValues(alpha: 0.55 * night)));
    final rnd = math.Random(5);
    for (var i = 0; i < 28; i++) {
      final p = Offset(rnd.nextDouble() * s.width, rnd.nextDouble() * s.height * 0.55);
      c.drawCircle(p, 1 + rnd.nextDouble() * 1.8, _f(const Color(0xFFFFF6C8).withValues(alpha: 0.9 * night)));
    }
  }

  @override
  bool shouldRepaint(RoomPainter old) => old.room != room || old.night != night || old.floorY != floorY;
}
