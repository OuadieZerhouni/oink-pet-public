import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oink_pet/pet/needs.dart';
import 'package:oink_pet/pet/pet_controller.dart';
import 'package:oink_pet/pet/pet_state.dart';
import 'package:oink_pet/pet/pet_store.dart';
import 'package:oink_pet/core/remote_config.dart';
import 'package:oink_pet/ui/pig/particles.dart';

void main() {
  test('particle field never holds more than its capacity', () {
    final f = ParticleField();
    for (var i = 0; i < 500; i++) {
      f.add(Particle(kind: ParticleKind.heart, pos: Offset.zero, vel: Offset.zero, life: 1));
    }
    expect(f.items.length, 90);
  });

  test('no real money: no purchase SDK, and only Closet buy() spends acorns', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    for (final pkg in ['in_app_purchase', 'purchases_flutter', 'google_mobile_ads']) {
      expect(pubspec.contains(pkg), isFalse, reason: '$pkg must not ship in v1');
    }
    final spenders = <String>[];
    for (final f in Directory('lib').listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'))) {
      final src = f.readAsStringSync();
      if (RegExp(r'acorns\s*-\s*\w|acorns\s*-=').hasMatch(src)) spenders.add(f.path);
    }
    expect(spenders, ['lib/pet/pet_controller.dart']);
    final ctl = File('lib/pet/pet_controller.dart').readAsStringSync();
    expect(RegExp(r'acorns\s*-\s*\w').allMatches(ctl).length, 1, reason: 'the single spend is BuyResult in buy()');
  });

  test('a finished game raises Fun and pays score ÷ 3 (capped at 40)', () {
    final now = DateTime(2026, 10, 7, 14);
    final pet = PetController(
      initial: PetState.fresh(now).copyWith(onboarded: true, needs: const Needs(fun: 30), acorns: 0),
      store: PetStore(),
      configSource: () => RemoteConfig.defaults,
      clock: () => now,
    );
    expect(pet.finishGame(30), 10);
    expect(pet.state.acorns, 10);
    expect(pet.state.needs.fun, 55);
    expect(pet.finishGame(300), 40);
  });
}
