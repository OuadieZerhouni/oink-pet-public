import 'dart:math' as math;

import 'package:flutter/rendering.dart';

import 'accessories.dart';

enum ParticleKind { heart, sparkle, bubble, zzz, note, crumb, drop }

class Particle {
  Particle({
    required this.kind,
    required this.pos,
    required this.vel,
    required this.life,
    this.size = 10,
    this.spin = 0,
    this.color = const Color(0xFFFF6F98),
  }) : maxLife = life;

  final ParticleKind kind;
  Offset pos;
  Offset vel;
  double life;
  final double maxLife;
  final double size;
  double spin;
  final Color color;

  double get t => 1 - (life / maxLife).clamp(0.0, 1.0);
}

/// A tiny fixed-capacity particle system in pig design space. Capped so a
/// frantic rub can never pile up thousands of objects and drop frames.
class ParticleField {
  ParticleField({this.capacity = 90});
  final int capacity;
  final List<Particle> items = [];
  final _rng = math.Random();

  bool get isEmpty => items.isEmpty;

  void add(Particle p) {
    if (items.length >= capacity) items.removeAt(0);
    items.add(p);
  }

  void burst(ParticleKind kind, Offset at, {int count = 5, double speed = 60, Color? color, double size = 12}) {
    for (var i = 0; i < count; i++) {
      final a = -math.pi / 2 + (_rng.nextDouble() - 0.5) * 2.2;
      final v = speed * (0.6 + _rng.nextDouble() * 0.7);
      add(Particle(
        kind: kind,
        pos: at + Offset((_rng.nextDouble() - 0.5) * 30, (_rng.nextDouble() - 0.5) * 16),
        vel: Offset(math.cos(a) * v, math.sin(a) * v),
        life: 0.9 + _rng.nextDouble() * 0.6,
        size: size * (0.7 + _rng.nextDouble() * 0.6),
        spin: (_rng.nextDouble() - 0.5) * 3,
        color: color ?? _defaultColor(kind),
      ));
    }
  }

  Color _defaultColor(ParticleKind k) => switch (k) {
    ParticleKind.heart => const Color(0xFFFF5C8A),
    ParticleKind.sparkle => const Color(0xFFFFD54F),
    ParticleKind.bubble => const Color(0xFFB3E5FC),
    ParticleKind.zzz => const Color(0xFF8E7CC3),
    ParticleKind.note => const Color(0xFF7C4DFF),
    ParticleKind.crumb => const Color(0xFFE0A15A),
    ParticleKind.drop => const Color(0xFF64B5F6),
  };

  void step(double dt) {
    for (final p in items) {
      p.life -= dt;
      p.pos += p.vel * dt;
      final gravity = switch (p.kind) {
        ParticleKind.crumb || ParticleKind.drop => 420.0,
        ParticleKind.bubble => -30.0,
        _ => -10.0,
      };
      p.vel = Offset(p.vel.dx * (1 - 1.2 * dt), p.vel.dy + gravity * dt);
      p.spin += dt;
    }
    items.removeWhere((p) => p.life <= 0);
  }

  void paint(Canvas c) {
    for (final p in items) {
      final fade = p.t < 0.15 ? p.t / 0.15 : (1 - p.t).clamp(0.0, 1.0) / 0.85;
      final a = fade.clamp(0.0, 1.0);
      switch (p.kind) {
        case ParticleKind.heart:
          c.save();
          c.translate(p.pos.dx, p.pos.dy);
          c.rotate(math.sin(p.spin * 3) * 0.25);
          c.drawPath(heartPath(Offset.zero, p.size), Paint()..color = p.color.withValues(alpha: a));
          c.restore();
        case ParticleKind.sparkle:
          drawStar(c, p.pos, p.size * (0.6 + 0.4 * math.sin(p.spin * 8).abs()), p.color.withValues(alpha: a));
        case ParticleKind.bubble:
          final paint = Paint()
            ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.55 * a)
            ..style = PaintingStyle.fill;
          c.drawCircle(p.pos, p.size, paint);
          c.drawCircle(p.pos, p.size, Paint()
            ..color = p.color.withValues(alpha: 0.9 * a)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);
          c.drawCircle(p.pos + Offset(-p.size * 0.35, -p.size * 0.35), p.size * 0.22, Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: a));
        case ParticleKind.zzz:
          final tp = TextPainter(
            text: TextSpan(
              text: 'z',
              style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.w600, fontSize: p.size * 2, color: p.color.withValues(alpha: a)),
            ),
            textDirection: TextDirection.ltr,
          )..layout();
          tp.paint(c, p.pos - Offset(tp.width / 2, tp.height / 2));
        case ParticleKind.note:
          final paint = Paint()..color = p.color.withValues(alpha: a);
          c.drawOval(Rect.fromCenter(center: p.pos, width: p.size * 1.2, height: p.size * 0.9), paint);
          c.drawLine(p.pos + Offset(p.size * 0.55, 0), p.pos + Offset(p.size * 0.55, -p.size * 2), paint..strokeWidth = 2.5);
        case ParticleKind.crumb:
          c.drawCircle(p.pos, p.size * 0.35, Paint()..color = p.color.withValues(alpha: a));
        case ParticleKind.drop:
          final path = Path()
            ..moveTo(p.pos.dx, p.pos.dy - p.size)
            ..quadraticBezierTo(p.pos.dx + p.size * 0.7, p.pos.dy + p.size * 0.2, p.pos.dx, p.pos.dy + p.size * 0.5)
            ..quadraticBezierTo(p.pos.dx - p.size * 0.7, p.pos.dy + p.size * 0.2, p.pos.dx, p.pos.dy - p.size)
            ..close();
          c.drawPath(path, Paint()..color = p.color.withValues(alpha: 0.85 * a));
      }
    }
  }
}
