import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oink_pet/core/app_services.dart';
import 'package:oink_pet/core/remote_config.dart';
import 'package:oink_pet/core/settings.dart';
import 'package:oink_pet/core/sfx.dart';
import 'package:oink_pet/l10n/app_localizations.dart';
import 'package:oink_pet/pet/needs.dart';
import 'package:oink_pet/pet/pet_controller.dart';
import 'package:oink_pet/pet/pet_state.dart';
import 'package:oink_pet/pet/pet_store.dart';
import 'package:oink_pet/ui/theme.dart';

class TestClock {
  TestClock(this.now);
  DateTime now;
  DateTime call() => now;
}

/// Services wired for widget tests: in-memory prefs (set up by the caller),
/// a controllable clock, and a silent sound player that still logs.
AppServices makeServices({
  bool onboarded = true,
  Needs needs = const Needs(),
  int acorns = 10,
  int level = 1,
  bool asleep = false,
  TestClock? clock,
  RemoteConfig config = RemoteConfig.defaults,
}) {
  final c = clock ?? TestClock(DateTime(2026, 10, 7, 14));
  final remote = RemoteConfigService()..value = config;
  final pet = PetController(
    initial: PetState.fresh(c.now).copyWith(onboarded: onboarded, needs: needs, acorns: acorns, level: level, asleep: asleep),
    store: PetStore(),
    configSource: () => remote.value,
    clock: c.call,
  );
  return AppServices(settings: SettingsService(), remote: remote, pet: pet, sfx: SfxPlayer());
}

Widget wrap(AppServices s, Widget child) => AppScope(
  services: s,
  child: MaterialApp(
    theme: buildTheme(),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  ),
);

/// iPhone 15-ish logical size.
Future<void> phoneSize(WidgetTester tester) async {
  tester.view.physicalSize = const Size(393 * 3, 852 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}
