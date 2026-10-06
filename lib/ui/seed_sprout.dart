import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A hand-drawn seed that sprouts as [growth] rises from 0 to 1.
///
/// This exists in the template as the **pixel-diff subject**: one custom
/// painter whose visual change a test can measure. It is here because of a
/// class of bug that unit tests structurally cannot catch.
///
/// On OuO, a customization option was wired correctly end to end — the flag
/// reached the painter, the painter branched on it — and rendered as two
/// background-coloured shapes that were invisible on the shipping palette at
/// the size players actually saw. Every "does the flag arrive?" test passed.
/// Players reported the feature as broken. It cost two full render cycles
/// before anyone measured *pixels* instead of *state*.
///
/// So the template ships a painter plus `test/pixel_visibility_test.dart`,
/// which renders it at two `growth` values and asserts the frames genuinely
/// differ by more than a threshold. Any real app should point that test at its
/// own most-subtle visual option.
class SeedSprout extends StatelessWidget {
  const SeedSprout({
    super.key,
    required this.growth,
    required this.inkColor,
    this.size = 160,
  });

  /// 0 = dormant seed, 1 = fully sprouted.
  final double growth;
  final Color inkColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: SeedSproutPainter(
        growth: growth.clamp(0.0, 1.0),
        inkColor: inkColor,
      ),
    );
  }
}

class SeedSproutPainter extends CustomPainter {
  const SeedSproutPainter({required this.growth, required this.inkColor});

  final double growth;
  final Color inkColor;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final stroke = w * 0.045;

    final ink = Paint()
      ..color = inkColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    // The seed: always drawn, so "nothing happened" is never the same as
    // "nothing is there".
    final seedCentre = Offset(w * 0.5, h * 0.78);
    final seedR = w * 0.085;
    canvas.drawOval(
      Rect.fromCenter(
        center: seedCentre,
        width: seedR * 2.2,
        height: seedR * 2.6,
      ),
      Paint()
        ..color = inkColor
        ..style = PaintingStyle.fill
        ..isAntiAlias = true,
    );

    if (growth <= 0.01) return;

    // Stem: rises out of the seed. Eased so early growth is visible — a linear
    // ramp spends its first frames moving a few pixels, which is exactly the
    // "did anything change?" ambiguity the pixel test is meant to remove.
    final eased = Curves.easeOutCubic.transform(growth);
    final stemTop = Offset(
      w * 0.5 + math.sin(eased * math.pi) * w * 0.03,
      seedCentre.dy - seedR - (h * 0.52 * eased),
    );
    final stem = Path()
      ..moveTo(seedCentre.dx, seedCentre.dy - seedR)
      ..quadraticBezierTo(
        w * 0.5 - w * 0.05 * eased,
        (seedCentre.dy + stemTop.dy) / 2,
        stemTop.dx,
        stemTop.dy,
      );
    canvas.drawPath(stem, ink);

    // Leaves unfurl in the back half, so the two halves of the animation look
    // different in kind rather than only in degree.
    final leaf = ((growth - 0.35) / 0.65).clamp(0.0, 1.0);
    if (leaf <= 0) return;
    final leafLen = w * 0.24 * Curves.easeOut.transform(leaf);
    for (final dir in const [-1.0, 1.0]) {
      final base = Offset(stemTop.dx, stemTop.dy + h * 0.06);
      final tip = base + Offset(dir * leafLen, -leafLen * 0.55);
      canvas.drawPath(
        Path()
          ..moveTo(base.dx, base.dy)
          ..quadraticBezierTo(
            base.dx + dir * leafLen * 0.5,
            base.dy - leafLen * 0.75,
            tip.dx,
            tip.dy,
          )
          ..quadraticBezierTo(
            base.dx + dir * leafLen * 0.75,
            base.dy - leafLen * 0.1,
            base.dx,
            base.dy,
          ),
        Paint()
          ..color = inkColor
          ..style = PaintingStyle.fill
          ..isAntiAlias = true,
      );
    }
  }

  @override
  bool shouldRepaint(SeedSproutPainter old) =>
      old.growth != growth || old.inkColor != inkColor;
}
