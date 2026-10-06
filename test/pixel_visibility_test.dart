import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oink_pet/ui/seed_sprout.dart';

/// Asserts a visual change is actually *visible*, by comparing pixels.
///
/// The trap this exists for: state can reach a painter, the painter can branch
/// on it, every unit test can pass — and the feature can still render nothing
/// a person could see. On OuO an option drew two background-coloured shapes
/// that vanished on the shipping palette at the size players actually saw. It
/// was reported as broken twice before anyone measured pixels instead of state.
///
/// Point this at your app's most *subtle* visual option, not its most obvious
/// one. The obvious ones are not where this class of bug lives.
///
/// Plain `test`, not `testWidgets`: rendering a painter needs no widget tree,
/// and staying out of the tester's fake-async zone avoids the `toImage`
/// hang documented in `preview_dump_test.dart`.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ByteData> render(double growth, Size size) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    // Painted on an opaque ground, as it is in the app. Measuring on
    // transparency would flatter a change that is invisible in practice.
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFFFFFFFF),
    );
    SeedSproutPainter(growth: growth, inkColor: const Color(0xFF2E5D3A))
        .paint(canvas, size);
    final image = await recorder
        .endRecording()
        .toImage(size.width.round(), size.height.round());
    final data = await image.toByteData();
    return data!;
  }

  double differingFraction(ByteData a, ByteData b) {
    var differing = 0;
    final total = a.lengthInBytes ~/ 4;
    for (var i = 0; i < total; i++) {
      if (a.getUint32(i * 4) != b.getUint32(i * 4)) differing++;
    }
    return differing / total;
  }

  test('growth is visible at the size it is actually drawn', () async {
    // The real on-screen size, not a generous one. An option that only reads
    // at 4x is an option users report as broken.
    const size = Size(160, 160);
    final dormant = await render(0.0, size);
    final grown = await render(1.0, size);

    final fraction = differingFraction(dormant, grown);
    expect(
      fraction,
      greaterThan(0.01),
      reason: 'Only ${(fraction * 100).toStringAsFixed(2)}% of pixels changed '
          'between dormant and grown at ${size.width.toInt()}px. Under ~1% is '
          'what users call a broken feature.',
    );
  });

  test('early growth is already visible', () async {
    // The first moments matter most: if 15% growth is indistinguishable from
    // 0, the animation reads as a delay rather than as motion.
    const size = Size(160, 160);
    final dormant = await render(0.0, size);
    final early = await render(0.15, size);
    expect(differingFraction(dormant, early), greaterThan(0.002));
  });
}
