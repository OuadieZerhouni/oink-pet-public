import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Bans the always-false test guard by reading the app's own source.
///
/// `flutter test` exports `FLUTTER_TEST` as a **runtime environment
/// variable**. `bool.fromEnvironment` reads compile-time `--dart-define`
/// values, so `bool.fromEnvironment('FLUTTER_TEST')` is *always false* — a
/// guard written that way compiles, reads perfectly, passes review, and does
/// nothing forever. The OuO repo ships three of them.
///
/// This is the template's exemplar of a **source-grep coverage guard**: a test
/// that asserts something about the codebase rather than about behaviour. Reach
/// for the pattern whenever the failure mode is silence — a missing case, an
/// unreachable branch, a guard that never fires — because behavioural tests
/// pass happily in all of those situations.
void main() {
  test('lib/ uses core/test_env.dart, never bool.fromEnvironment(FLUTTER_TEST)',
      () {
    final offenders = <String>[];
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      // Normalise separators before any path comparison. Dart reports
      // `lib\core\test_env.dart` on Windows, so a check written against the
      // POSIX form silently stops matching and the exemption below never
      // fires — which made this very test fail on itself, on Windows only.
      final path = entity.path.replaceAll(r'\', '/');
      final text = entity.readAsStringSync();
      // The doc comment in test_env.dart quotes the wrong form on purpose to
      // explain it; that file is the one place allowed to name it.
      if (path.endsWith('core/test_env.dart')) continue;
      for (final (i, line) in text.split('\n').indexed) {
        if (line.contains("fromEnvironment('FLUTTER_TEST')") ||
            line.contains('fromEnvironment("FLUTTER_TEST")')) {
          offenders.add('$path:${i + 1}');
        }
      }
    }
    expect(
      offenders,
      isEmpty,
      reason: 'These read a --dart-define that flutter test never sets, so the '
          'guard silently does nothing:\n${offenders.join('\n')}\n'
          'Use `isRunningUnderTest` from lib/core/test_env.dart instead.',
    );
  });
}
