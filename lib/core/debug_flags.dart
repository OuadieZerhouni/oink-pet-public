/// Every `--dart-define` seam the app has, in one place.
///
/// Debug flags are compile-time constants, so the code they guard is
/// tree-shaken out of release builds. That is why they are safe to leave in.
library;

class DebugFlags {
  const DebugFlags._();

  /// Wipe the pet on every launch so onboarding replays.
  ///
  /// **Per-run only — never flip the default.** Shipping this on would wipe
  /// every real user's pig.
  static const bool resetFirstRun = bool.fromEnvironment('DEBUG_RESET_FIRST_RUN');

  /// The inspector: draw the pet's internal state (needs, xp) on screen.
  /// Prefer reading logs for anything timer-driven.
  static const bool showInspector = bool.fromEnvironment('DEBUG_INSPECTOR');

  /// The injector: a time-travel offset in hours applied to the app clock,
  /// so decay, sleep and the daily gift can be exercised without waiting.
  static const int clockOffsetHours = int.fromEnvironment('DEBUG_CLOCK_OFFSET_HOURS');

  static DateTime clock() => DateTime.now().add(const Duration(hours: clockOffsetHours));

  /// One line for the inspector overlay and for bug reports.
  static String get summary {
    final on = <String>[
      if (resetFirstRun) 'resetFirstRun',
      if (showInspector) 'inspector',
      if (clockOffsetHours != 0) 'clock+${clockOffsetHours}h',
    ];
    return on.isEmpty ? 'no debug flags' : on.join(' · ');
  }
}
