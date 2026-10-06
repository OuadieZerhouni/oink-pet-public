/// Every `--dart-define` seam the app has, in one place.
///
/// Two rules, both learned from OuO:
///
/// **One file.** OuO's flags are scattered across `app_constants.dart`, a face
/// widget, a painter, and two services, so "what can I turn on?" has no answer
/// short of grepping. Collected here, the list is the documentation.
///
/// **Every feature ships two seams: an inspector and an injector.** The
/// inspector shows what the app currently believes; the injector supplies input
/// the environment cannot. On OuO this pair is what made voice commands
/// testable at all — the iOS Simulator has no speech recognition whatsoever
/// (no Siri assets, so on-device fails with kAFAssistantErrorDomain 1101), and
/// without a way to inject a transcript the matcher, the dispatch, and every
/// reaction were unreachable outside a physical device.
///
/// Debug flags are compile-time constants, so the code they guard is
/// tree-shaken out of release builds. That is why they are safe to leave in.
library;

class DebugFlags {
  const DebugFlags._();

  /// Skip ad loading entirely. Ads are slow, networked, and irrelevant to
  /// almost every local iteration.
  static const bool skipAds = bool.fromEnvironment('DEBUG_SKIP_ADS');

  /// Behave as though the user owns everything purchasable, without a store
  /// round trip.
  static const bool proMode = bool.fromEnvironment('DEBUG_PRO_MODE');

  /// Wipe first-run state on every launch so onboarding replays.
  ///
  /// **Per-run only — never flip the default.** Shipping this on would wipe
  /// first-run state for every real user.
  ///
  /// And a lesson worth keeping: a reset flag must clear *every* one-shot
  /// flag, not just the ones owned by the service that implements it. OuO's
  /// reset missed two `SharedPreferences` keys owned by a screen, so onboarding
  /// replayed while the two coach marks it was meant to re-test stayed
  /// permanently spent — which made the surfaces that most needed verifying the
  /// only ones that could not be.
  static const bool resetFirstRun =
      bool.fromEnvironment('DEBUG_RESET_FIRST_RUN');

  /// The inspector: draw current internal state on screen.
  ///
  /// Prefer reading the device log for anything timer-driven. A screenshot of a
  /// seven-second window is trivially mistimed and reads as "broken feature";
  /// the same transition in a log is unambiguous and cost-free to re-read.
  static const bool showInspector = bool.fromEnvironment('DEBUG_INSPECTOR');

  /// The injector: hand the app an input the environment cannot produce.
  ///
  /// Empty means "use the real source". Rename per app to whatever input is
  /// actually unavailable in the simulator (a transcript, a purchase receipt, a
  /// sensor reading).
  static const String fakeInput = String.fromEnvironment('DEBUG_FAKE_INPUT');

  static bool get hasFakeInput => fakeInput.isNotEmpty;

  /// One line for the inspector overlay and for bug reports.
  static String get summary {
    final on = <String>[
      if (skipAds) 'skipAds',
      if (proMode) 'proMode',
      if (resetFirstRun) 'resetFirstRun',
      if (showInspector) 'inspector',
      if (hasFakeInput) 'fakeInput="$fakeInput"',
    ];
    return on.isEmpty ? 'no debug flags' : on.join(' · ');
  }
}
