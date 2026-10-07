import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oink_pet/pet/catalog.dart';
import 'package:oink_pet/ui/pig/pig_painter.dart';
import 'package:oink_pet/ui/pig/pig_pose.dart';

/// Asserts visual state is actually *visible*, by comparing pixels at the size
/// the pig renders on a phone — not just that state reached the painter.
///
/// Targets the subtle cues: the first mud splotch (the only signal that the
/// pig needs a bath before the meter turns red), a hat, and the blush.
///
/// Plain `test`, not `testWidgets`: rendering a painter needs no widget tree,
/// and staying out of the tester's fake-async zone avoids the `toImage` hang.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const size = Size(260, 347); // ≈ the pig box on a 375-pt-wide iPhone

  Future<ByteData> render(PigPainter p) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFFF7D9B5));
    p.paint(canvas, size);
    final img = await recorder.endRecording().toImage(size.width.round(), size.height.round());
    return (await img.toByteData())!;
  }

  /// Fraction of pixels whose colour differs noticeably.
  double diff(ByteData a, ByteData b) {
    var changed = 0;
    final n = a.lengthInBytes ~/ 4;
    for (var i = 0; i < n; i++) {
      var d = 0;
      for (var k = 0; k < 3; k++) {
        d += (a.getUint8(i * 4 + k) - b.getUint8(i * 4 + k)).abs();
      }
      if (d > 40) changed++;
    }
    return changed / n;
  }

  PigPainter pig({double clean = 100, String? hat, double blush = 0.45}) =>
      PigPainter(pose: PigPose(blush: blush), geometry: PigGeometry.forStage(Stage.piglet), clean: clean, hat: hat);

  test('the first mud splotch is visible as soon as Clean drops to 60', () async {
    final clean = await render(pig());
    final muddy = await render(pig(clean: 60));
    expect(diff(clean, muddy), greaterThan(0.004), reason: 'one splotch ≈ ≥0.4% of the pig box');
  });

  test('a fully muddy pig looks very different', () async {
    final clean = await render(pig());
    final muddy = await render(pig(clean: 5));
    expect(diff(clean, muddy), greaterThan(0.02));
  });

  test('a hat changes the silhouette', () async {
    final bare = await render(pig());
    final hatted = await render(pig(hat: 'crown'));
    expect(diff(bare, hatted), greaterThan(0.01));
  });

  test('blush is visible', () async {
    final pale = await render(pig(blush: 0));
    final rosy = await render(pig(blush: 1));
    expect(diff(pale, rosy), greaterThan(0.002));
  });
}
