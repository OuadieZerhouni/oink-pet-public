import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:oink_pet/core/remote_config.dart';
import 'package:oink_pet/pet/catalog.dart';
import 'package:oink_pet/pet/needs.dart';
import 'package:oink_pet/pet/pet_controller.dart';
import 'package:oink_pet/pet/pet_state.dart';
import 'package:oink_pet/pet/pet_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeClock {
  FakeClock(this.now);
  DateTime now;
  DateTime call() => now;
  void advance(Duration d) => now = now.add(d);
}

PetController makePet({FakeClock? clock, RemoteConfig cfg = RemoteConfig.defaults, PetState? initial}) {
  final c = clock ?? FakeClock(DateTime(2026, 10, 7, 12));
  return PetController(
    initial: initial ?? PetState.fresh(c.now).copyWith(onboarded: true),
    store: PetStore(),
    config: () => cfg,
    clock: c.call,
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('Needs', () {
    test('drain per hour, floor at 5, never below an existing low value', () {
      const n = Needs(tummy: 50, clean: 50, fun: 50, energy: 50);
      final after = n.elapse(2, asleep: false);
      expect(after.tummy, closeTo(38, 1e-9));
      expect(after.clean, closeTo(44, 1e-9));
      expect(after.fun, closeTo(40, 1e-9));
      expect(after.energy, closeTo(42, 1e-9));
      final week = n.elapse(24 * 7, asleep: false);
      for (final need in Need.values) {
        expect(week[need], Needs.floor);
      }
      const veryLow = Needs(tummy: 2, clean: 2, fun: 2, energy: 2);
      expect(veryLow.elapse(10, asleep: false).tummy, 2, reason: 'decay never lowers a value already under the floor');
    });

    test('sleep refills energy and caps at 100', () {
      const n = Needs(energy: 40);
      expect(n.elapse(2, asleep: true).energy, closeTo(70, 1e-9));
      expect(n.elapse(20, asleep: true).energy, 100);
    });

    test('negative or NaN elapsed time is a no-op', () {
      const n = Needs();
      expect(n.elapse(-3, asleep: false), n);
      expect(n.elapse(double.nan, asleep: false), n);
    });

    test('mostUrgent and wellbeing', () {
      expect(const Needs().mostUrgent, isNull);
      expect(const Needs(clean: 10, fun: 20).mostUrgent, Need.clean);
      expect(const Needs(tummy: 100, clean: 100, fun: 100, energy: 100).wellbeing, 1);
      expect(const Needs(tummy: 100, clean: 100, fun: 100, energy: 5).wellbeing, lessThan(0.8));
    });

    test('json is tolerant of junk', () {
      expect(Needs.fromJson({'tummy': 'x', 'clean': 999, 'fun': double.nan, 'energy': -4}),
          const Needs(tummy: 80, clean: 100, fun: 75, energy: 0));
      expect(Needs.fromJson(null), const Needs());
    });
  });

  group('Economy', () {
    test('xp curve, payouts and gift', () {
      expect(Economy.xpForNext(1), 32);
      expect(Economy.miniGamePayout(0), 0);
      expect(Economy.miniGamePayout(30), 10);
      expect(Economy.miniGamePayout(9999), 40);
      expect(Economy.dailyGift(1), 5);
      expect(Economy.dailyGift(7), 11);
      expect(Economy.dailyGift(30), 11, reason: 'streak capped at 7');
      expect(stageForLevel(1), Stage.piglet);
      expect(stageForLevel(5), Stage.little);
      expect(stageForLevel(10), Stage.big);
    });

    test('catalog ids are unique and every slot has a free starter (except glasses/neck)', () {
      final ids = Catalog.cosmetics.map((c) => c.id).toList();
      expect(ids.toSet().length, ids.length);
      final foodIds = Catalog.foods.map((f) => f.id).toList();
      expect(foodIds.toSet().length, foodIds.length);
      expect(Catalog.starterOwned, containsAll(['bow', 'barn']));
    });
  });

  group('PetController', () {
    test('time passing drains needs; sleeping pet wakes when rested', () {
      final clock = FakeClock(DateTime(2026, 10, 7, 12));
      final pet = makePet(clock: clock);
      final start = pet.state.needs.tummy;
      clock.advance(const Duration(hours: 3));
      expect(pet.sync(), isTrue);
      expect(pet.state.needs.tummy, closeTo(start - 18, 1e-6));

      pet.sleep();
      expect(pet.state.asleep, isTrue);
      final events = <PetEvent>[];
      pet.events.listen(events.add);
      clock.advance(const Duration(hours: 10));
      pet.sync();
      expect(pet.state.asleep, isFalse);
      expect(pet.state.needs.energy, 100);
      return Future<void>.delayed(Duration.zero, () => expect(events.whereType<WokeUp>(), hasLength(1)));
    });

    test('clock going backwards never decays', () {
      final clock = FakeClock(DateTime(2026, 10, 7, 12));
      final pet = makePet(clock: clock);
      final before = pet.state.needs;
      clock.advance(const Duration(hours: -5));
      expect(pet.sync(), isFalse);
      expect(pet.state.needs, before);
    });

    test('feeding: eats, refuses when full, locked treats, asleep', () {
      final pet = makePet(initial: PetState.fresh(DateTime(2026, 10, 7, 12)).copyWith(onboarded: true, needs: const Needs(tummy: 20)));
      final apple = Catalog.food('apple')!;
      final acornsBefore = pet.state.acorns;
      expect(pet.feed(apple), FeedResult.ate);
      expect(pet.state.needs.tummy, 38);
      expect(pet.state.acorns, acornsBefore + 2, reason: 'care bonus for a hungry pig');
      expect(pet.state.stats.feeds, 1);
      expect(pet.state.stats.favoriteFood, 'apple');
      expect(pet.feed(Catalog.food('donut')!), FeedResult.locked);
      for (var i = 0; i < 6; i++) {
        pet.feed(apple);
      }
      expect(pet.feed(apple), FeedResult.full);
      pet.sleep();
      expect(pet.feed(apple), FeedResult.asleep);
    });

    test('bath: scrub caps at 95, rinse finishes at 100 and pays by start dirtiness', () {
      final pet = makePet(initial: PetState.fresh(DateTime(2026, 10, 7, 12)).copyWith(onboarded: true, needs: const Needs(clean: 10)));
      for (var i = 0; i < 100; i++) {
        pet.scrub(3);
      }
      expect(pet.state.needs.clean, 95);
      final a = pet.state.acorns;
      pet.rinse(startClean: 10);
      expect(pet.state.needs.clean, 100);
      expect(pet.state.acorns, a + 2);
      expect(pet.state.stats.baths, 1);
    });

    test('petting xp is capped per day', () {
      final pet = makePet();
      for (var i = 0; i < 1000; i++) {
        pet.pet(PetZone.belly);
      }
      expect(pet.state.petXpToday, 20);
      expect(pet.state.stats.bellyRubs, 1000);
    });

    test('level up emits events and growth', () async {
      final pet = makePet();
      final events = <PetEvent>[];
      pet.events.listen(events.add);
      for (var i = 0; i < 40; i++) {
        pet.finishGame(100);
      }
      await Future<void>.delayed(Duration.zero);
      expect(pet.state.level, greaterThanOrEqualTo(5));
      expect(events.whereType<LevelUp>(), isNotEmpty);
      expect(events.whereType<LevelUp>().any((e) => e.grew), isTrue);
    });

    test('daily gift: once a day, streak continues on consecutive days and resets after a gap', () {
      final clock = FakeClock(DateTime(2026, 10, 7, 9));
      final pet = makePet(clock: clock);
      expect(pet.giftAvailable, isTrue);
      expect(pet.claimGift(), 5);
      expect(pet.giftAvailable, isFalse);
      expect(pet.claimGift(), 0);
      clock.advance(const Duration(days: 1));
      expect(pet.claimGift(), 6);
      clock.advance(const Duration(days: 1));
      expect(pet.claimGift(), 7);
      clock.advance(const Duration(days: 3));
      expect(pet.claimGift(), 5, reason: 'streak restarts');
    });

    test('no gift before onboarding finishes', () {
      final pet = makePet(initial: PetState.fresh(DateTime(2026, 10, 7)));
      expect(pet.giftAvailable, isFalse);
    });

    test('closet purchases', () {
      final clock = FakeClock(DateTime(2026, 7, 7, 12));
      final pet = makePet(clock: clock, initial: PetState.fresh(clock.now).copyWith(onboarded: true, acorns: 100));
      final flowers = Catalog.cosmetic('flowers')!;
      expect(pet.buy(flowers), BuyResult.bought);
      expect(pet.state.acorns, 85);
      expect(pet.isEquipped(flowers), isTrue);
      expect(pet.buy(flowers), BuyResult.alreadyOwned);
      expect(pet.buy(Catalog.cosmetic('crown')!), BuyResult.locked);
      expect(pet.buy(Catalog.cosmetic('witch')!), BuyResult.unavailable, reason: 'witch hat is October-only');
      pet.unequip(Slot.hat);
      expect(pet.state.equipped[Slot.hat], isNull);
      pet.unequip(Slot.room);
      expect(pet.state.room, 'barn', reason: 'rooms cannot be unequipped');

      clock.now = DateTime(2026, 10, 20);
      expect(pet.buy(Catalog.cosmetic('witch')!), BuyResult.bought);
      final poor = makePet(initial: PetState.fresh(clock.now).copyWith(onboarded: true, acorns: 3));
      expect(poor.buy(flowers), BuyResult.tooPoor);
    });

    test('remote price multiplier applies', () {
      const cfg = RemoteConfig(priceMultiplier: 2);
      final pet = makePet(cfg: cfg);
      expect(pet.priceOf(Catalog.cosmetic('flowers')!), 30);
      expect(pet.priceOf(Catalog.cosmetic('bow')!), 0);
    });

    test('rename trims and caps', () {
      final pet = makePet();
      pet.rename('   ');
      expect(pet.state.name, PetState.defaultName);
      pet.rename('  Sir Oinksalot the Third  ');
      expect(pet.state.name, 'Sir Oinksalot th');
    });

    test('review prompt waits for days and level', () {
      final clock = FakeClock(DateTime(2026, 10, 7));
      final pet = makePet(clock: clock, initial: PetState.fresh(clock.now).copyWith(onboarded: true, level: 3));
      expect(pet.shouldAskReview, isFalse);
      clock.advance(const Duration(days: 3));
      expect(pet.shouldAskReview, isTrue);
      pet.markReviewAsked();
      expect(pet.shouldAskReview, isFalse);
    });
  });

  group('Persistence', () {
    test('round trip through the store', () async {
      final now = DateTime(2026, 10, 7, 12);
      final store = PetStore();
      final s = PetState.fresh(now).copyWith(
        name: 'Truffle',
        onboarded: true,
        acorns: 77,
        level: 4,
        xp: 12,
        owned: {...Catalog.starterOwned, 'scarf'},
        equipped: {Slot.hat: 'bow', Slot.neck: 'scarf', Slot.room: 'barn'},
        stats: const PetStats(feeds: 3, foodCounts: {'corn': 3}),
      );
      await store.save(s);
      final back = (await store.load(now))!;
      expect(back.name, 'Truffle');
      expect(back.acorns, 77);
      expect(back.level, 4);
      expect(back.xp, 12);
      expect(back.equipped[Slot.neck], 'scarf');
      expect(back.stats.favoriteFood, 'corn');
      expect(jsonEncode(back.toJson()), jsonEncode(s.toJson()));
    });

    test('corrupt blob → null (fresh pig), junk fields fall back', () async {
      SharedPreferences.setMockInitialValues({'pet_v1': '{not json'});
      expect(await PetStore().load(DateTime(2026)), isNull);
      final now = DateTime(2026, 10, 7);
      final s = PetState.fromJson({
        'name': 42,
        'level': -3,
        'acorns': 'lots',
        'owned': ['bow', 'not_a_real_item', 7],
        'equipped': {'hat': 'crown', 'room': 'nope'},
        'lastUpdated': '2099-01-01T00:00:00.000',
      }, now);
      expect(s.name, PetState.defaultName);
      expect(s.level, 1);
      expect(s.acorns, 10);
      expect(s.owned, isNot(contains('not_a_real_item')));
      expect(s.equipped[Slot.hat], isNull, reason: 'crown is not owned');
      expect(s.room, 'barn');
      expect(s.lastUpdated, now, reason: 'a future timestamp is clamped to now');
    });
  });
}
