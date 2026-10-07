import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oink_pet/core/app_services.dart';
import 'package:oink_pet/main.dart';
import 'package:oink_pet/core/settings.dart';
import 'package:oink_pet/core/sfx.dart';
import 'package:oink_pet/pet/catalog.dart';
import 'package:oink_pet/pet/needs.dart';
import 'package:oink_pet/pet/pet_controller.dart';
import 'package:oink_pet/ui/pig/pig_view.dart';
import 'package:oink_pet/ui/room_painter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

/// End-to-end flows through the real widget tree. The home screen runs
/// periodic timers and pulsing meters, so these tests pump explicit
/// durations instead of `pumpAndSettle`, and tear the tree down at the end so
/// no timer outlives its test.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  late AppServices svc;

  Future<void> boot(WidgetTester tester, {bool onboarded = true, Needs needs = const Needs(), int acorns = 10, int level = 1, bool asleep = false}) async {
    await phoneSize(tester);
    svc = makeServices(onboarded: onboarded, needs: needs, acorns: acorns, level: level, asleep: asleep);
    await tester.pumpWidget(OinkApp(servicesFuture: Future.value(svc)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
  }

  Future<void> settle(WidgetTester tester, [int ms = 800]) async {
    for (var i = 0; i < ms ~/ 100; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> teardown(WidgetTester tester) async {
    await settle(tester, 4000); // let speech bubbles and delayed reactions finish
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  }

  PetController pet(WidgetTester tester) => svc.pet;

  void expectNoException(WidgetTester tester) {
    final e = tester.takeException();
    if (e is FlutterError) fail(e.toStringDeep());
    expect(e, isNull);
  }

  testWidgets('onboarding → name → tips → home', (tester) async {
    await boot(tester, onboarded: false);
    expect(find.text("Somebody's in the basket!"), findsOneWidget);
    await tester.tap(find.text('Say hello'));
    await settle(tester);
    expect(find.text("What's your piglet's name?"), findsOneWidget);
    await tester.tap(find.text('Truffle'));
    await tester.pump();
    await tester.tap(find.text("That's my name!"));
    await settle(tester);
    expect(find.text('How to care for Truffle'), findsOneWidget);
    await tester.tap(find.text("Let's go!"));
    await settle(tester, 1200);
    expect(find.text('Truffle'), findsWidgets);
    expect(find.text('Feed'), findsOneWidget);
    expect(pet(tester).state.onboarded, isTrue);
    await teardown(tester);
  });

  testWidgets('tapping the snout oinks and counts', (tester) async {
    await boot(tester);
    final pig = find.byType(PigView);
    final box = tester.getRect(pig);
    // The snout sits a little above the vertical middle of the pig box.
    await tester.tapAt(Offset(box.center.dx, box.top + box.height * 0.62));
    await tester.pump(const Duration(milliseconds: 100));
    expect(pet(tester).state.stats.oinks, 1);
    await teardown(tester);
  });

  testWidgets('feeding: open tray, drag an apple onto the pig', (tester) async {
    await boot(tester, needs: const Needs(tummy: 30));
    await tester.tap(find.text('Feed'));
    await settle(tester, 500);
    expect(find.text('Apple'), findsOneWidget);
    final from = tester.getCenter(find.text('Apple'));
    final to = tester.getCenter(find.byType(PigView));
    final g = await tester.startGesture(from);
    for (var i = 1; i <= 12; i++) {
      await g.moveTo(Offset.lerp(from, to, i / 12)!);
      await tester.pump(const Duration(milliseconds: 16));
    }
    await g.up();
    await settle(tester, 300);
    expect(pet(tester).state.stats.feeds, 1);
    expect(pet(tester).state.needs.tummy, greaterThan(45));
    expect(find.text('Yum!'), findsOneWidget);
    await teardown(tester);
  });

  testWidgets('bath: scrub raises Clean, rinse finishes at 100', (tester) async {
    await boot(tester, needs: const Needs(clean: 20));
    await tester.tap(find.text('Bath'));
    await settle(tester, 500);
    expect(find.text('Rinse'), findsOneWidget);
    final box = tester.getRect(find.byType(PigView));
    for (var k = 0; k < 6; k++) {
      final g = await tester.startGesture(Offset(box.left + box.width * 0.3, box.top + box.height * 0.75));
      for (var i = 0; i < 10; i++) {
        await g.moveBy(const Offset(14, 0));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await g.up();
    }
    expect(pet(tester).state.needs.clean, greaterThan(40));
    await tester.tap(find.text('Rinse'));
    await settle(tester, 2500);
    expect(pet(tester).state.needs.clean, 100);
    expect(pet(tester).state.stats.baths, 1);
    expect(find.text('Feed'), findsOneWidget, reason: 'back to the dock');
    await teardown(tester);
  });

  testWidgets('sleep and wake', (tester) async {
    await boot(tester);
    await tester.tap(find.text('Sleep'));
    await settle(tester, 300);
    expect(pet(tester).state.asleep, isTrue);
    expect(find.text('Wake'), findsOneWidget);
    await tester.tap(find.text('Feed'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Shh… Oinky is sleeping'), findsOneWidget);
    await tester.tap(find.text('Wake'));
    await settle(tester, 300);
    expect(pet(tester).state.asleep, isFalse);
    await teardown(tester);
  });

  testWidgets('daily gift pays acorns once', (tester) async {
    await boot(tester, acorns: 0);
    final gift = find.byTooltip('Daily gift');
    expect(gift, findsOneWidget);
    await tester.tap(gift);
    await settle(tester, 600);
    expect(find.text('Daily gift!'), findsOneWidget);
    await tester.tap(find.text('Yay!'));
    await settle(tester, 600);
    expect(pet(tester).state.acorns, 5);
    expect(find.byTooltip('Daily gift'), findsNothing);
    await teardown(tester);
  });

  testWidgets('closet: buy and wear the flower crown', (tester) async {
    await boot(tester, acorns: 100);
    await tester.tap(find.text('Closet'));
    await settle(tester, 800);
    await tester.tap(find.text('Flower crown'));
    await settle(tester, 500);
    expect(find.text('Get the Flower crown?'), findsOneWidget);
    await tester.tap(find.textContaining('Get it'));
    await settle(tester, 500);
    final st = pet(tester).state;
    expect(st.owned, contains('flowers'));
    expect(st.acorns, 85);
    expect(find.text('Wearing'), findsOneWidget);
    await teardown(tester);
  });

  testWidgets('settings: start over returns to onboarding', (tester) async {
    await boot(tester);
    await tester.tap(find.byTooltip('Settings'));
    await settle(tester, 800);
    await tester.tap(find.text('Start over with a new piglet'));
    await settle(tester, 500);
    await tester.tap(find.text('Start over'));
    await settle(tester, 1500);
    expect(find.text("Somebody's in the basket!"), findsOneWidget);
    expect(pet(tester).state.onboarded, isFalse);
    await teardown(tester);
  });

  testWidgets('small phone + large text: home and closet lay out without overflow', (tester) async {
    tester.view.physicalSize = const Size(320 * 2, 568 * 2);
    tester.view.devicePixelRatio = 2;
    tester.platformDispatcher.textScaleFactorTestValue = 1.6;
    addTearDown(() {
      tester.view.reset();
      tester.platformDispatcher.clearTextScaleFactorTestValue();
    });
    final old = FlutterError.onError;
    FlutterError.onError = (d) {
      debugPrint('LAYOUT ERROR: ${d.toString()}');
      old?.call(d);
    };
    addTearDown(() => FlutterError.onError = old);
    svc = makeServices(needs: const Needs(tummy: 10, clean: 10, fun: 10, energy: 10));
    await tester.pumpWidget(OinkApp(servicesFuture: Future.value(svc)));
    await tester.pump();
    await settle(tester, 600);
    expectNoException(tester);
    await tester.tap(find.text('Feed'));
    await settle(tester, 500);
    expectNoException(tester);
    await tester.tap(find.byTooltip('Close'));
    await settle(tester, 500);
    await tester.tap(find.text('Closet'));
    await settle(tester, 800);
    expectNoException(tester);
    await teardown(tester);
  });

  testWidgets('home shows name, level, acorns and the four meters; Play opens Apple Catch', (tester) async {
    await boot(tester, acorns: 12);
    expect(find.text('Oinky'), findsWidgets);
    expect(find.text('12'), findsWidgets);
    for (final m in ['Tummy', 'Clean', 'Fun', 'Energy']) {
      expect(find.text(m), findsOneWidget);
    }
    for (final d in ['Feed', 'Bath', 'Play', 'Sleep', 'Closet']) {
      expect(find.text(d), findsOneWidget);
    }
    await tester.tap(find.text('Play'));
    await settle(tester, 800);
    expect(find.text('Apple Catch'), findsWidgets);
    await teardown(tester);
  });

  testWidgets('snout tap always says Oink!; a belly rub raises Fun', (tester) async {
    await boot(tester, needs: const Needs(fun: 40));
    final box = tester.getRect(find.byType(PigView));
    await tester.tapAt(Offset(box.center.dx, box.top + box.height * 0.62));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Oink!'), findsOneWidget);
    await settle(tester, 3000);
    final before = pet(tester).state.needs.fun;
    final g = await tester.startGesture(Offset(box.left + box.width * 0.35, box.top + box.height * 0.78));
    for (var k = 0; k < 4; k++) {
      for (var i = 0; i < 8; i++) {
        await g.moveBy(Offset(k.isEven ? 12 : -12, 0));
        await tester.pump(const Duration(milliseconds: 16));
      }
    }
    await g.up();
    expect(pet(tester).state.needs.fun, greaterThan(before));
    await teardown(tester);
  });

  testWidgets('a sleeping pig grumbles and stays asleep; tapping the moon wakes it', (tester) async {
    await boot(tester, asleep: true);
    await settle(tester, 3000);
    final box = tester.getRect(find.byType(PigView));
    await tester.tapAt(Offset(box.center.dx, box.top + box.height * 0.62));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Five more minutes…'), findsOneWidget);
    expect(pet(tester).state.asleep, isTrue);
    await settle(tester, 3000);
    final g = await tester.startGesture(Offset(box.left + box.width * 0.35, box.top + box.height * 0.78));
    for (var k = 0; k < 3; k++) {
      for (var i = 0; i < 6; i++) {
        await g.moveBy(Offset(k.isEven ? 12 : -12, 0));
        await tester.pump(const Duration(milliseconds: 16));
      }
    }
    await g.up();
    expect(find.text('Five more minutes…'), findsOneWidget, reason: 'a rub grumbles too');
    expect(pet(tester).state.asleep, isTrue);
    svc.sfx.log.clear();
    await tester.pump(const Duration(seconds: 21));
    expect(svc.sfx.log, contains(Sfx.snore));
    await tester.tap(find.byTooltip('Settings'));
    await settle(tester, 800);
    svc.sfx.log.clear();
    await tester.pump(const Duration(seconds: 41));
    expect(svc.sfx.log, isNot(contains(Sfx.snore)), reason: 'no snoring behind another screen');
    await tester.pageBack();
    await settle(tester, 3000);
    await tester.tap(find.byKey(const ValueKey('moon')));
    await settle(tester, 300);
    expect(pet(tester).state.asleep, isFalse);
    expect(find.byKey(const ValueKey('moon')), findsNothing);
    await teardown(tester);
  });

  testWidgets('feed tray: treats show a lock and level; a full pig refuses', (tester) async {
    await boot(tester, needs: const Needs(tummy: 100));
    await tester.tap(find.text('Feed'));
    await settle(tester, 500);
    expect(find.byIcon(Icons.lock_rounded), findsWidgets);
    expect(find.textContaining('Lv '), findsWidgets);
    final from = tester.getCenter(find.text('Apple'));
    final to = tester.getCenter(find.byType(PigView));
    final g = await tester.startGesture(from);
    for (var i = 1; i <= 12; i++) {
      await g.moveTo(Offset.lerp(from, to, i / 12)!);
      await tester.pump(const Duration(milliseconds: 16));
    }
    await g.up();
    await settle(tester, 300);
    expect(find.text("I'm full!"), findsOneWidget);
    expect(pet(tester).state.needs.tummy, 100);
    expect(pet(tester).state.stats.feeds, 0);
    await teardown(tester);
  });

  testWidgets('an equipped room becomes the home background', (tester) async {
    await boot(tester, acorns: 100, level: 2);
    RoomPainter painter() => tester.widgetList<CustomPaint>(find.byType(CustomPaint)).map((c) => c.painter).whereType<RoomPainter>().first;
    expect(painter().room, 'barn');
    final meadow = Catalog.cosmetic('meadow')!;
    expect(svc.pet.buy(meadow), BuyResult.bought);
    svc.pet.equip(meadow);
    await settle(tester, 300);
    expect(painter().room, 'meadow');
    await teardown(tester);
  });

  testWidgets('settings: toggles apply and persist; About opens', (tester) async {
    await boot(tester);
    await tester.tap(find.byTooltip('Settings'));
    await settle(tester, 800);
    await tester.tap(find.text('Sounds'));
    await tester.pump();
    await tester.tap(find.text('Vibration'));
    await settle(tester, 300);
    expect(svc.settings.value.sound, isFalse);
    expect(svc.settings.value.haptics, isFalse);
    final reloaded = SettingsService();
    await reloaded.load();
    expect(reloaded.value.sound, isFalse);
    expect(reloaded.value.haptics, isFalse);
    await tester.tap(find.text('About Oink'));
    await settle(tester, 500);
    expect(find.byType(AboutDialog), findsOneWidget);
    expect(find.text('No ads. No purchases. Just a piglet.'), findsWidgets);
    await tester.tap(find.text('Close'));
    await settle(tester, 500);
    await teardown(tester);
  });

  testWidgets('small phone + large text, asleep: the wake moon never covers the speech bubble', (tester) async {
    tester.view.physicalSize = const Size(320 * 2, 568 * 2);
    tester.view.devicePixelRatio = 2;
    tester.platformDispatcher.textScaleFactorTestValue = 1.6;
    addTearDown(() {
      tester.view.reset();
      tester.platformDispatcher.clearTextScaleFactorTestValue();
    });
    svc = makeServices(asleep: true);
    await tester.pumpWidget(OinkApp(servicesFuture: Future.value(svc)));
    await tester.pump();
    await settle(tester, 600);
    expectNoException(tester);
    final moon = tester.getRect(find.byKey(const ValueKey('moon')));
    final bubble = tester.getRect(find.textContaining('sleeping'));
    expect(moon.overlaps(bubble), isFalse, reason: 'moon $moon vs bubble $bubble');
    await teardown(tester);
  });
}
