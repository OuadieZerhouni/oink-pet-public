import 'package:flutter/foundation.dart';

import 'catalog.dart';
import 'needs.dart';

/// Lifetime counters, shown on the pet card and used for the review prompt.
@immutable
class PetStats {
  const PetStats({
    this.feeds = 0,
    this.baths = 0,
    this.games = 0,
    this.bestScore = 0,
    this.oinks = 0,
    this.bellyRubs = 0,
    this.naps = 0,
    this.foodCounts = const {},
  });

  final int feeds;
  final int baths;
  final int games;
  final int bestScore;
  final int oinks;
  final int bellyRubs;
  final int naps;
  final Map<String, int> foodCounts;

  /// Most-eaten food id (ties → first seen in the catalog), null before any meal.
  String? get favoriteFood {
    String? best;
    var n = 0;
    for (final f in Catalog.foods) {
      final c = foodCounts[f.id] ?? 0;
      if (c > n) {
        best = f.id;
        n = c;
      }
    }
    return best;
  }

  PetStats copyWith({
    int? feeds,
    int? baths,
    int? games,
    int? bestScore,
    int? oinks,
    int? bellyRubs,
    int? naps,
    Map<String, int>? foodCounts,
  }) => PetStats(
    feeds: feeds ?? this.feeds,
    baths: baths ?? this.baths,
    games: games ?? this.games,
    bestScore: bestScore ?? this.bestScore,
    oinks: oinks ?? this.oinks,
    bellyRubs: bellyRubs ?? this.bellyRubs,
    naps: naps ?? this.naps,
    foodCounts: foodCounts ?? this.foodCounts,
  );

  Map<String, dynamic> toJson() => {
    'feeds': feeds,
    'baths': baths,
    'games': games,
    'bestScore': bestScore,
    'oinks': oinks,
    'bellyRubs': bellyRubs,
    'naps': naps,
    'foodCounts': foodCounts,
  };

  factory PetStats.fromJson(Object? j) {
    if (j is! Map) return const PetStats();
    int i(String k) => (j[k] is num) ? (j[k] as num).toInt().clamp(0, 1 << 30) : 0;
    final fc = <String, int>{};
    final raw = j['foodCounts'];
    if (raw is Map) {
      raw.forEach((k, v) {
        if (k is String && v is num) fc[k] = v.toInt().clamp(0, 1 << 30);
      });
    }
    return PetStats(
      feeds: i('feeds'),
      baths: i('baths'),
      games: i('games'),
      bestScore: i('bestScore'),
      oinks: i('oinks'),
      bellyRubs: i('bellyRubs'),
      naps: i('naps'),
      foodCounts: fc,
    );
  }
}

/// Everything persisted about the pet. Immutable; [PetController] owns the
/// current value and is the only thing that produces new ones.
@immutable
class PetState {
  const PetState({
    required this.name,
    required this.adoptedAt,
    required this.lastUpdated,
    this.onboarded = false,
    this.needs = const Needs(),
    this.asleep = false,
    this.level = 1,
    this.xp = 0,
    this.acorns = 10,
    this.owned = const {},
    this.equipped = const {Slot.hat: 'bow', Slot.room: Catalog.defaultRoom},
    this.giftStreak = 0,
    this.lastGiftDay,
    this.petXpDay,
    this.petXpToday = 0,
    this.reviewAsked = false,
    this.stats = const PetStats(),
  });

  static const schema = 1;
  static const defaultName = 'Oinky';

  factory PetState.fresh(DateTime now) =>
      PetState(name: defaultName, adoptedAt: now, lastUpdated: now, owned: Catalog.starterOwned);

  final String name;
  final DateTime adoptedAt;
  final DateTime lastUpdated;
  final bool onboarded;
  final Needs needs;
  final bool asleep;
  final int level;

  /// XP earned toward the next level (resets on level-up).
  final int xp;
  final int acorns;
  final Set<String> owned;
  final Map<Slot, String> equipped;
  final int giftStreak;

  /// yyyy-mm-dd of the last claimed daily gift (local time).
  final String? lastGiftDay;

  /// Petting XP is capped per day so tapping cannot farm levels.
  final String? petXpDay;
  final int petXpToday;
  final bool reviewAsked;
  final PetStats stats;

  Stage get stage => stageForLevel(level);
  String get room => equipped[Slot.room] ?? Catalog.defaultRoom;

  /// Days since adoption, counting the adoption day as day 1.
  int ageDays(DateTime now) => now.difference(adoptedAt).inDays + 1;

  PetState copyWith({
    String? name,
    DateTime? lastUpdated,
    bool? onboarded,
    Needs? needs,
    bool? asleep,
    int? level,
    int? xp,
    int? acorns,
    Set<String>? owned,
    Map<Slot, String>? equipped,
    int? giftStreak,
    String? lastGiftDay,
    String? petXpDay,
    int? petXpToday,
    bool? reviewAsked,
    PetStats? stats,
  }) => PetState(
    name: name ?? this.name,
    adoptedAt: adoptedAt,
    lastUpdated: lastUpdated ?? this.lastUpdated,
    onboarded: onboarded ?? this.onboarded,
    needs: needs ?? this.needs,
    asleep: asleep ?? this.asleep,
    level: level ?? this.level,
    xp: xp ?? this.xp,
    acorns: acorns ?? this.acorns,
    owned: owned ?? this.owned,
    equipped: equipped ?? this.equipped,
    giftStreak: giftStreak ?? this.giftStreak,
    lastGiftDay: lastGiftDay ?? this.lastGiftDay,
    petXpDay: petXpDay ?? this.petXpDay,
    petXpToday: petXpToday ?? this.petXpToday,
    reviewAsked: reviewAsked ?? this.reviewAsked,
    stats: stats ?? this.stats,
  );

  /// Returns a copy with [slot] cleared (rooms cannot be cleared).
  PetState unequip(Slot slot) {
    if (slot == Slot.room) return this;
    final e = Map<Slot, String>.of(equipped)..remove(slot);
    return PetState(
      name: name,
      adoptedAt: adoptedAt,
      lastUpdated: lastUpdated,
      onboarded: onboarded,
      needs: needs,
      asleep: asleep,
      level: level,
      xp: xp,
      acorns: acorns,
      owned: owned,
      equipped: e,
      giftStreak: giftStreak,
      lastGiftDay: lastGiftDay,
      petXpDay: petXpDay,
      petXpToday: petXpToday,
      reviewAsked: reviewAsked,
      stats: stats,
    );
  }

  Map<String, dynamic> toJson() => {
    'schema': schema,
    'name': name,
    'adoptedAt': adoptedAt.toIso8601String(),
    'lastUpdated': lastUpdated.toIso8601String(),
    'onboarded': onboarded,
    'needs': needs.toJson(),
    'asleep': asleep,
    'level': level,
    'xp': xp,
    'acorns': acorns,
    'owned': owned.toList()..sort(),
    'equipped': {for (final e in equipped.entries) e.key.name: e.value},
    'giftStreak': giftStreak,
    'lastGiftDay': lastGiftDay,
    'petXpDay': petXpDay,
    'petXpToday': petXpToday,
    'reviewAsked': reviewAsked,
    'stats': stats.toJson(),
  };

  /// Tolerant decoder: every field falls back on its own, unknown cosmetic
  /// ids are dropped, and the starter items are always owned.
  factory PetState.fromJson(Map<String, dynamic> j, DateTime now) {
    DateTime date(Object? v, DateTime d) {
      final p = v is String ? DateTime.tryParse(v) : null;
      if (p == null) return d;
      // A clock that jumped backwards must not create negative elapsed time.
      return p.isAfter(now) ? now : p;
    }

    int i(Object? v, int d, int lo, int hi) => v is num && v.isFinite ? v.toInt().clamp(lo, hi) : d;

    final adopted = date(j['adoptedAt'], now);
    final owned = <String>{...Catalog.starterOwned};
    final rawOwned = j['owned'];
    if (rawOwned is List) {
      for (final id in rawOwned) {
        if (id is String && Catalog.cosmetic(id) != null) owned.add(id);
      }
    }
    final equipped = <Slot, String>{};
    final rawEq = j['equipped'];
    if (rawEq is Map) {
      for (final s in Slot.values) {
        final id = rawEq[s.name];
        final c = id is String ? Catalog.cosmetic(id) : null;
        if (c != null && c.slot == s && owned.contains(id)) equipped[s] = id as String;
      }
    }
    equipped.putIfAbsent(Slot.room, () => Catalog.defaultRoom);
    final rawName = j['name'];
    final name = rawName is String && rawName.trim().isNotEmpty ? rawName.trim() : defaultName;

    return PetState(
      name: name.length > 16 ? name.substring(0, 16) : name,
      adoptedAt: adopted,
      lastUpdated: date(j['lastUpdated'], now),
      onboarded: j['onboarded'] == true,
      needs: Needs.fromJson(j['needs']),
      asleep: j['asleep'] == true,
      level: i(j['level'], 1, 1, Economy.maxLevel),
      xp: i(j['xp'], 0, 0, 1 << 20),
      acorns: i(j['acorns'], 10, 0, 1 << 24),
      owned: owned,
      equipped: equipped,
      giftStreak: i(j['giftStreak'], 0, 0, 1 << 16),
      lastGiftDay: j['lastGiftDay'] is String ? j['lastGiftDay'] as String : null,
      petXpDay: j['petXpDay'] is String ? j['petXpDay'] as String : null,
      petXpToday: i(j['petXpToday'], 0, 0, 1000),
      reviewAsked: j['reviewAsked'] == true,
      stats: PetStats.fromJson(j['stats']),
    );
  }
}

/// Local calendar day key, yyyy-mm-dd.
String dayKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
