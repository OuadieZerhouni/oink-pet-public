import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

/// Whether this code is running under `flutter test`.
///
/// **This is the only correct way to ask, and there is a wrong way that looks
/// identical.** `flutter test` exports `FLUTTER_TEST` as a *runtime
/// environment variable*, so:
///
/// ```dart
/// const bad = bool.fromEnvironment('FLUTTER_TEST');   // ALWAYS false
/// ```
///
/// `bool.fromEnvironment` reads compile-time `--dart-define` values, which
/// `flutter test` never sets. A guard written that way compiles, reads
/// plausibly, passes review — and does nothing, forever. The OuO repo ships
/// three of them today, which is why this helper exists and why
/// `test/no_wrong_test_guard_test.dart` greps `lib/` to keep it the only form.
///
/// Guarded with [kIsWeb] first because `Platform` throws on web.
bool get isRunningUnderTest =>
    !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');

/// Whether a subsystem should skip work that only makes sense on a device.
///
/// Use this — not [isRunningUnderTest] directly — at the call site, so the
/// *reason* is legible: platform channels, analytics side effects, and
/// multi-second timers that would otherwise leak into a widget test.
///
/// The cost of a seam is real and worth stating: a subsystem that never starts
/// under test needs an explicit compensator in the tests that care about it,
/// or the behaviour is simply untested rather than tested-as-disabled. Prefer
/// stubbing at the boundary over short-circuiting deep inside.
bool get skipDeviceOnlyWork => isRunningUnderTest;
