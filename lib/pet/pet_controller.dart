import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/remote_config.dart';
import 'catalog.dart';
import 'needs.dart';
import 'pet_state.dart';
import 'pet_store.dart';

/// Things the UI should celebrate once (level-up banner, good-morning chime).
sealed class PetEvent {
  const PetEvent();
}

class LevelUp extends PetEvent {
  const LevelUp(this.level, {required this.grew});
  final int level;

  /// The growth stage changed (piglet → little → big).
  final bool grew;
}

class WokeUp extends PetEvent {
  const WokeUp();
}

enum FeedResult { ate, full, locked, asleep }

enum BuyResult { bought, alreadyOwned, tooPoor, locked, unavailable }

/// Pet zones the UI reports touches on.
enum PetZone { snout, head, belly, ear, tail }

/// The single owner of the pet's state. Every mutation goes through here, is
/// applied to an immutable [PetState], notified, and saved (debounced).
///
/// Time: the controller never runs a background timer of its own. The UI calls
/// [sync] on resume and on a slow ticker; [sync] applies the real elapsed time
/// since `lastUpdated`, so the pet changes the same whether the app was open,
/// backgrounded, or killed for a week.
class PetController extends ChangeNotifier {
  PetController({
    required PetState initial,
    required this.store,
    required RemoteConfig Function() config,
    DateTime Function()? clock,
  }) : _state = initial,
       _config = config,
       clock = clock ?? DateTime.now;

  final PetStore store;
  final RemoteConfig Function() _config;
  final DateTime Function() clock;
  final _events = StreamController<PetEvent>.broadcast();
  Timer? _saveTimer;

  PetState _state;
  PetState get state => _state;
  Stream<PetEvent> get events => _events.stream;
  RemoteConfig get config => _config();

  static const _maxPetXpPerDay = 20;
  static const _petActionsPerXp = 5;
  int _petActionsSinceXp = 0;

  /// Applies elapsed real time. Returns true if anything visible changed.
  bool sync() {
    final now = clock();
    final hours = now.difference(_state.lastUpdated).inMilliseconds / 3.6e6;
    if (hours <= 0) {
      if (hours < 0) _set(_state.copyWith(lastUpdated: now), save: false);
      return false;
    }
    final rates = DecayRates.standard.scaled(drain: config.drainMultiplier, rest: config.restMultiplier);
    var needs = _state.needs.elapse(hours, asleep: _state.asleep, rates: rates);
    var asleep = _state.asleep;
    var woke = false;
    if (asleep && needs.energy >= Needs.max) {
      asleep = false;
      woke = true;
    }
    _set(_state.copyWith(needs: needs, asleep: asleep, lastUpdated: now));
    if (woke) _events.add(const WokeUp());
    return true;
  }

  // ------------------------------------------------------------------ care
  bool isUnlocked(Food f) => _state.level >= f.minLevel && config.seasonActive(f.seasonal, clock());

  FeedResult feed(Food food) {
    sync();
    if (_state.asleep) return FeedResult.asleep;
    if (!isUnlocked(food)) return FeedResult.locked;
    final before = _state.needs.tummy;
    if (before >= 96) return FeedResult.full;
    final counts = Map<String, int>.of(_state.stats.foodCounts)..update(food.id, (v) => v + 1, ifAbsent: () => 1);
    _set(
      _state.copyWith(
        needs: _state.needs.add(Need.tummy, food.tummy).add(Need.fun, food.fun),
        acorns: _state.acorns + Economy.careBonus(before),
        stats: _state.stats.copyWith(feeds: _state.stats.feeds + 1, foodCounts: counts),
      ),
    );
    _grantXp(before < 50 ? 4 : 2);
    return FeedResult.ate;
  }

  /// Sponge strokes raise Clean up to 95; the last bit needs a rinse.
  void scrub(double amount) {
    if (_state.asleep || amount <= 0) return;
    final c = _state.needs.clean;
    if (c >= 95) return;
    _set(_state.copyWith(needs: _state.needs.withNeed(Need.clean, (c + amount).clamp(0, 95))), save: false);
    _scheduleSave();
  }

  /// Finishes a bath. [startClean] is Clean when the bath began, so the reward
  /// reflects how dirty the pig was, not how long the sponge was waved.
  void rinse({required double startClean}) {
    if (_state.asleep) return;
    _set(
      _state.copyWith(
        needs: _state.needs.withNeed(Need.clean, 100).add(Need.fun, 4),
        acorns: _state.acorns + Economy.careBonus(startClean),
        stats: _state.stats.copyWith(baths: _state.stats.baths + 1),
      ),
    );
    _grantXp(startClean < 50 ? 6 : 3);
  }

  /// A touch on the pig. Fun rises a little; XP trickles in, capped per day.
  void pet(PetZone zone) {
    if (_state.asleep) return;
    final s = _state.stats;
    final fun = switch (zone) {
      PetZone.belly => 2.0,
      PetZone.head => 1.5,
      _ => 1.0,
    };
    _set(
      _state.copyWith(
        needs: _state.needs.add(Need.fun, fun),
        stats: s.copyWith(
          oinks: zone == PetZone.snout ? s.oinks + 1 : s.oinks,
          bellyRubs: zone == PetZone.belly ? s.bellyRubs + 1 : s.bellyRubs,
        ),
      ),
      save: false,
    );
    _scheduleSave();
    if (++_petActionsSinceXp >= _petActionsPerXp) {
      _petActionsSinceXp = 0;
      final today = dayKey(clock());
      final used = _state.petXpDay == today ? _state.petXpToday : 0;
      if (used < _maxPetXpPerDay) {
        _set(_state.copyWith(petXpDay: today, petXpToday: used + 1), save: false);
        _grantXp(1);
      }
    }
  }

  /// Mini-game result. Returns the acorns paid.
  int finishGame(int score) {
    sync();
    final pay = Economy.miniGamePayout(score);
    final s = _state.stats;
    _set(
      _state.copyWith(
        acorns: _state.acorns + pay,
        needs: _state.needs.add(Need.fun, 25).add(Need.energy, -8).add(Need.tummy, -4),
        stats: s.copyWith(games: s.games + 1, bestScore: score > s.bestScore ? score : s.bestScore),
      ),
    );
    _grantXp(5 + (score ~/ 10).clamp(0, 10));
    return pay;
  }

  void sleep() {
    sync();
    if (_state.asleep) return;
    _set(_state.copyWith(asleep: true, stats: _state.stats.copyWith(naps: _state.stats.naps + 1)));
  }

  void wake() {
    sync();
    if (!_state.asleep) return;
    _set(_state.copyWith(asleep: false));
  }

  // ----------------------------------------------------------------- gifts
  bool get giftAvailable => config.dailyGiftEnabled && _state.onboarded && _state.lastGiftDay != dayKey(clock());

  /// Streak continues if the last gift was yesterday, else restarts at 1.
  int get nextGiftStreak {
    final now = clock();
    final yesterday = dayKey(DateTime(now.year, now.month, now.day - 1));
    return _state.lastGiftDay == yesterday ? _state.giftStreak + 1 : 1;
  }

  int get nextGiftAmount => Economy.dailyGift(nextGiftStreak, base: config.dailyGiftBase);

  /// Claims today's gift; returns the amount (0 if none was available).
  int claimGift() {
    if (!giftAvailable) return 0;
    final streak = nextGiftStreak;
    final amount = Economy.dailyGift(streak, base: config.dailyGiftBase);
    _set(_state.copyWith(acorns: _state.acorns + amount, giftStreak: streak, lastGiftDay: dayKey(clock())));
    return amount;
  }

  // ---------------------------------------------------------------- closet
  bool isAvailable(Cosmetic c) => config.seasonActive(c.seasonal, clock()) || _state.owned.contains(c.id);
  bool isLevelLocked(Cosmetic c) => _state.level < c.minLevel;
  int priceOf(Cosmetic c) => config.price(c.price);

  BuyResult buy(Cosmetic c) {
    if (_state.owned.contains(c.id)) return BuyResult.alreadyOwned;
    if (!isAvailable(c)) return BuyResult.unavailable;
    if (isLevelLocked(c)) return BuyResult.locked;
    final price = priceOf(c);
    if (_state.acorns < price) return BuyResult.tooPoor;
    _set(_state.copyWith(acorns: _state.acorns - price, owned: {..._state.owned, c.id}));
    equip(c);
    return BuyResult.bought;
  }

  void equip(Cosmetic c) {
    if (!_state.owned.contains(c.id)) return;
    _set(_state.copyWith(equipped: {..._state.equipped, c.slot: c.id}));
  }

  void unequip(Slot slot) => _set(_state.unequip(slot));

  bool isEquipped(Cosmetic c) => _state.equipped[c.slot] == c.id;

  // ----------------------------------------------------------------- misc
  void rename(String name) {
    final n = name.trim();
    if (n.isEmpty) return;
    _set(_state.copyWith(name: n.length > 16 ? n.substring(0, 16) : n));
  }

  void completeOnboarding(String name) {
    final n = name.trim();
    _set(_state.copyWith(name: n.isEmpty ? PetState.defaultName : (n.length > 16 ? n.substring(0, 16) : n), onboarded: true));
  }

  /// Whether to ask for an App Store review now (asked at most once).
  bool get shouldAskReview {
    final c = config;
    return c.reviewPromptEnabled &&
        !_state.reviewAsked &&
        _state.level >= c.reviewMinLevel &&
        _state.ageDays(clock()) >= c.reviewMinDays;
  }

  void markReviewAsked() => _set(_state.copyWith(reviewAsked: true));

  /// Starts over with a brand-new piglet.
  Future<void> reset() async {
    _saveTimer?.cancel();
    await store.clear();
    _petActionsSinceXp = 0;
    _set(PetState.fresh(clock()), save: false);
  }

  /// Persist now (call on app pause).
  Future<void> flush() async {
    _saveTimer?.cancel();
    _saveTimer = null;
    await store.save(_state);
  }

  // -------------------------------------------------------------- internals
  void _grantXp(int amount) {
    var level = _state.level;
    var xp = _state.xp + amount;
    final before = stageForLevel(level);
    var leveled = false;
    while (level < Economy.maxLevel && xp >= Economy.xpForNext(level)) {
      xp -= Economy.xpForNext(level);
      level++;
      leveled = true;
    }
    if (level >= Economy.maxLevel) xp = xp.clamp(0, Economy.xpForNext(level) - 1);
    _set(_state.copyWith(level: level, xp: xp));
    if (leveled) _events.add(LevelUp(level, grew: stageForLevel(level) != before));
  }

  void _set(PetState s, {bool save = true}) {
    _state = s;
    notifyListeners();
    if (save) _scheduleSave();
  }

  void _scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 600), () {
      _saveTimer = null;
      store.save(_state);
    });
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _events.close();
    super.dispose();
  }
}
