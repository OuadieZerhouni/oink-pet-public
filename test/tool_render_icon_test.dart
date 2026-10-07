// Dev tool, skipped by default: renders the app icon master from the app's
// own pig painter, so the icon is literally the pet you adopt.
//
//   RENDER_ART=1 flutter test test/tool_render_icon_test.dart
//   .venv python tools/art/export_icons.py
//
// Writes tools/art/icon_1024.png (opaque). Uses tester.runAsync: Picture.toImage
// hangs inside the widget tester's fake-async zone (see docs/TRAPS.md).
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oink_pet/pet/catalog.dart';
import 'package:oink_pet/ui/pig/pig_painter.dart';
import 'package:oink_pet/ui/pig/pig_pose.dart';

void main() {
  final run = Platform.environment.containsKey('RENDER_ART');

  testWidgets('render icon master', (tester) async {
    await tester.runAsync(() async {
      const px = 1024.0;
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // Pastel sky: the complementary colour makes the pink pig pop at 60 px.
      canvas.drawRect(
        const Rect.fromLTWH(0, 0, px, px),
        Paint()
          ..shader = ui.Gradient.radial(const Offset(512, 430), 760, [
            const Color(0xFFE4F6FF),
            const Color(0xFFA9DDF7),
            const Color(0xFF86CBEF),
          ], [0, 0.6, 1]),
      );
      // Soft floor glow under the pig.
      canvas.drawOval(
        Rect.fromCenter(center: const Offset(512, 980), width: 900, height: 260),
        Paint()..color = const Color(0x55FFFFFF),
      );

      // Frame the head: design units → icon pixels, head centre slightly low
      // so the ears stay inside iOS's rounded mask.
      final g = PigGeometry.forStage(Stage.piglet);
      const k = 3.75;
      canvas.save();
      canvas.translate(512 - g.headC.dx * k, 590 - g.headC.dy * k);
      PigPainter(
        pose: PigPose(blush: 0.75),
        geometry: g,
        hat: 'bow',
      ).paint(canvas, Size(PigGeometry.designSize.width * k, PigGeometry.designSize.height * k));
      canvas.restore();

      final image = await recorder.endRecording().toImage(px.toInt(), px.toInt());
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      final out = File('tools/art/icon_1024.png')..createSync(recursive: true);
      out.writeAsBytesSync(png!.buffer.asUint8List());
      expect(out.lengthSync(), greaterThan(10000));
    });
  }, skip: !run);
}
