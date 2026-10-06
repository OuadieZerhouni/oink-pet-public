/// What the user is currently allowed to do, in one place.
///
/// Centralised for a reason OuO demonstrated twice: when the answer to "may
/// this happen?" is computed at each call site, two call sites eventually
/// disagree, and the disagreement is a bug you can only find by playing. A
/// gate is also the natural place to hang the *why*, which is what keeps a
/// later reader from "simplifying" a deliberate asymmetry.
///
/// ## Monetisation subsystems are interfaces, not imports
///
/// `features.ads` and `features.iap` in `app.yaml` decide whether the real
/// implementations are copied into the app at all. Everything else talks to
/// these interfaces, so an app with monetisation off has no ad SDK, no
/// purchase SDK, and no dead code — and turning either on later is additive
/// rather than a refactor.
library;

import 'debug_flags.dart';

/// Whether ads may be requested. Implemented for real only when
/// `features.ads` is on.
abstract class AdsGate {
  bool get enabled;

  /// Whether an ad may show *right now* — distinct from [enabled], because an
  /// ad landing during a first-run tour or mid-interaction is worse than no
  /// ad. Keep the quiet-period logic here, not at the call site.
  bool get mayShowNow;
}

/// Whether purchased entitlements are active. Implemented for real only when
/// `features.iap` is on.
abstract class IapGate {
  bool get isPro;
}

class NoopAdsGate implements AdsGate {
  const NoopAdsGate();

  @override
  bool get enabled => false;

  @override
  bool get mayShowNow => false;
}

class NoopIapGate implements IapGate {
  const NoopIapGate();

  /// False, not true. A no-op gate must not *grant* anything: an app built
  /// without purchases should behave like the free tier, or every paid path
  /// ships untested and the first real build regresses.
  @override
  bool get isPro => false;
}

/// The single answer to "what is unlocked".
class FeatureGates {
  const FeatureGates._();

  static AdsGate ads = const NoopAdsGate();
  static IapGate iap = const NoopIapGate();

  /// Swapped once at startup when the real implementations exist.
  static void install({AdsGate? adsGate, IapGate? iapGate}) {
    if (adsGate != null) ads = adsGate;
    if (iapGate != null) iap = iapGate;
  }

  /// Debug override is checked *first* so a local build can exercise paid
  /// paths without a store account.
  static bool get isPro => DebugFlags.proMode || iap.isPro;

  static bool get showAds => !DebugFlags.skipAds && !isPro && ads.enabled;

  /// Whether an ad may interrupt right now.
  static bool get mayInterruptWithAd => showAds && ads.mayShowNow;
}
