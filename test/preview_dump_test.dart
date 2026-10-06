@Skip('Dev tool, not a test. Run: flutter test test/preview_dump_test.dart --run-skipped')
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oink_pet/ui/seed_sprout.dart';

/// Renders visual work to PNGs so it can be judged by looking.
///
/// **This is a dev tool wearing a test's clothes**, which is why it is skipped
/// by default. Tuning a hand-drawn shape is edit → regenerate → look → repeat,
/// and a build-and-run cycle per iteration is too slow to actually iterate.
/// The output directory resolution below lets you dump a "before" set, make a
/// change, and dump an "after" set beside it.
///
/// ```
/// flutter test test/preview_dump_test.dart --run-skipped
/// PREVIEW_DIR=/tmp/before flutter test test/preview_dump_test.dart --run-skipped
/// ```
///
/// ## The trap, which will cost you an afternoon otherwise
///
/// Inside the widget tester's fake-async zone, **only the first
/// `Picture.toImage` future ever completes** — a second one hangs the run with
/// no output and no error, which reads exactly like an infinite loop in your
/// own code. Two ways out, both used here:
///
///   * wrap the image work in `tester.runAsync`, which steps outside the fake
///     clock (needed for `RenderRepaintBoundary.toImage`), or
///   * use a plain `test` with `ensureInitialized()` and never enter the zone
///     at all (fine for painters, which need no widget tree).
///
/// A related hazard: a killed or timed-out test run leaves `flutter_tester`
/// processes holding locks at 0% CPU, and the *next* run blocks silently. If a
/// run produces no output at all, `pkill -f flutter_tester` before blaming the
/// code.
void main() {
  Directory outputDir() {
    const fromDefine = String.fromEnvironment('PREVIEW_DIR');
    final dir = fromDefine.isNotEmpty
        ? fromDefine
        : Platform.environment['PREVIEW_DIR'] ??
            '${Directory.systemTemp.path}/factory_preview';
    return Directory(dir)..createSync(recursive: true);
  }

  testWidgets('dump the sprout across its whole range', (tester) async {
    tester.view.physicalSize = const Size(1000, 420);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final key = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          home: ColoredBox(
            color: const Color(0xFFFFFFFF),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Sampled where the shape actually changes character, not on a
                // uniform grid: 0 is the seed alone, 0.35 is where leaves
                // begin, 1 is complete.
                for (final g in [0.0, 0.15, 0.35, 0.6, 1.0])
                  SeedSprout(
                    growth: g,
                    inkColor: const Color(0xFF2E5D3A),
                    size: 160,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // runAsync: outside the fake-async zone, so toImage resolves.
    await tester.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2.0);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('${outputDir().path}/sprout_range.png')
        ..writeAsBytesSync(bytes!.buffer.asUint8List());
      // ignore: avoid_print
      print('wrote ${file.path}');
    });
  });
}
