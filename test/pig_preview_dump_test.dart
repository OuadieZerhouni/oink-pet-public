// Dev tool, skipped by default: renders pig variants to build/preview/*.png so
// the art can be looked at without a device.
//
//   flutter test test/pig_preview_dump_test.dart --run-skipped
//
// Uses tester.runAsync: Picture.toImage hangs inside the widget tester's
// fake-async zone (see docs/TRAPS.md).
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oink_pet/pet/catalog.dart';
import 'package:oink_pet/ui/pig/pig_painter.dart';
import 'package:oink_pet/ui/pig/pig_pose.dart';

Future<void> _dump(String name, List<PigPainter> painters, {double cell = 300}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final w = cell * painters.length;
  canvas.drawRect(Rect.fromLTWH(0, 0, w, cell * 1.34), Paint()..color = const Color(0xFFFFF4E8));
  for (var i = 0; i < painters.length; i++) {
    canvas.save();
    canvas.translate(i * cell, 0);
    painters[i].paint(canvas, Size(cell, cell * 1.34));
    canvas.restore();
  }
  final img = await recorder.endRecording().toImage(w.round(), (cell * 1.34).round());
  final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
  Directory('build/preview').createSync(recursive: true);
  File('build/preview/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
}

void main() {
  testWidgets('dump pig previews', (tester) async {
    await tester.runAsync(() async {
      final g = PigGeometry.forStage(Stage.piglet);
      await _dump('pig_expressions', [
        PigPainter(pose: PigPose(), geometry: g),
        PigPainter(pose: PigPose(eyes: EyeMode.happy, blush: 0.9), geometry: g),
        PigPainter(pose: PigPose(mouth: MouthMode.oink, mouthOpen: 1, snoutSquish: 1, eyes: EyeMode.squint), geometry: g),
        PigPainter(pose: PigPose(eyes: EyeMode.sleepy, blush: 0.3), geometry: g),
        PigPainter(pose: PigPose(eyes: EyeMode.sad, mouth: MouthMode.frown, earLeft: 0.4, earRight: 0.4), geometry: g, clean: 15),
      ]);
      await _dump('pig_outfits', [
        PigPainter(pose: PigPose(), geometry: g, hat: 'bow'),
        PigPainter(pose: PigPose(), geometry: g, hat: 'flowers', neck: 'scarf'),
        PigPainter(pose: PigPose(eyes: EyeMode.happy), geometry: g, hat: 'party', glasses: 'round', neck: 'bowtie'),
        PigPainter(pose: PigPose(), geometry: g, hat: 'crown', glasses: 'hearts', neck: 'bell'),
        PigPainter(pose: PigPose(), geometry: g, hat: 'frog', glasses: 'stars', neck: 'bandana'),
      ]);
      await _dump('pig_hats2', [
        PigPainter(pose: PigPose(), geometry: g, hat: 'beanie'),
        PigPainter(pose: PigPose(), geometry: g, hat: 'chef'),
        PigPainter(pose: PigPose(), geometry: g, hat: 'cowboy'),
        PigPainter(pose: PigPose(), geometry: g, hat: 'witch'),
        PigPainter(pose: PigPose(), geometry: g, hat: 'santa'),
      ]);
      await _dump('pig_stages', [
        for (final s in Stage.values) PigPainter(pose: PigPose(), geometry: PigGeometry.forStage(s)),
      ]);
    });
  }, skip: true);
}
