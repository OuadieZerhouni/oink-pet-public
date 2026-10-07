import 'package:flutter/foundation.dart';

import 'needs.dart';

/// A food the piglet can eat. Basic foods are free and unlimited; treats
/// unlock with level. Food is never sold — acorns are only for the closet.
@immutable
class Food {
  const Food(this.id, {this.minLevel = 1, this.tummy = 16, this.fun = 0, this.seasonal});

  final String id;
  final int minLevel;
  final double tummy;
  final double fun;

  /// Remote-config seasonal window id (see [Seasonal]); null = always.
  final String? seasonal;
}

enum Slot { hat, glasses, neck, room }

/// Something the piglet can wear, or a room it can live in.
@immutable
class Cosmetic {
  const Cosmetic(this.id, this.slot, {this.price = 0, this.minLevel = 1, this.seasonal});

  final String id;
  final Slot slot;

  /// Acorns. 0 = owned from the start.
  final int price;
  final int minLevel;
  final String? seasonal;

  bool get isFree => price == 0;
}

class Catalog {
  const Catalog._();

  static const foods = <Food>[
    Food('apple', tummy: 18),
    Food('carrot', tummy: 16),
    Food('corn', tummy: 20),
    Food('lettuce', minLevel: 2, tummy: 12, fun: 2),
    Food('watermelon', minLevel: 3, tummy: 22, fun: 6),
    Food('strawberry', minLevel: 4, tummy: 12, fun: 8),
    Food('cupcake', minLevel: 6, tummy: 14, fun: 12),
    Food('donut', minLevel: 8, tummy: 16, fun: 14),
    Food('pumpkin', tummy: 24, fun: 10, seasonal: 'halloween'),
    Food('cookie', tummy: 14, fun: 12, seasonal: 'winter'),
  ];

  static const cosmetics = <Cosmetic>[
    // Hats
    Cosmetic('bow', Slot.hat),
    Cosmetic('flowers', Slot.hat, price: 15),
    Cosmetic('party', Slot.hat, price: 20, minLevel: 2),
    Cosmetic('beanie', Slot.hat, price: 25, minLevel: 3),
    Cosmetic('chef', Slot.hat, price: 35, minLevel: 4),
    Cosmetic('cowboy', Slot.hat, price: 40, minLevel: 5),
    Cosmetic('frog', Slot.hat, price: 50, minLevel: 6),
    Cosmetic('crown', Slot.hat, price: 90, minLevel: 8),
    Cosmetic('witch', Slot.hat, price: 30, seasonal: 'halloween'),
    Cosmetic('santa', Slot.hat, price: 30, seasonal: 'winter'),
    // Glasses
    Cosmetic('round', Slot.glasses, price: 20),
    Cosmetic('hearts', Slot.glasses, price: 30, minLevel: 3),
    Cosmetic('stars', Slot.glasses, price: 40, minLevel: 6),
    // Neck
    Cosmetic('bandana', Slot.neck, price: 15),
    Cosmetic('bowtie', Slot.neck, price: 20, minLevel: 2),
    Cosmetic('scarf', Slot.neck, price: 30, minLevel: 4),
    Cosmetic('bell', Slot.neck, price: 35, minLevel: 5),
    // Rooms
    Cosmetic('barn', Slot.room),
    Cosmetic('meadow', Slot.room, price: 40, minLevel: 2),
    Cosmetic('bedroom', Slot.room, price: 60, minLevel: 4),
    Cosmetic('beach', Slot.room, price: 80, minLevel: 6),
    Cosmetic('snow', Slot.room, price: 100, minLevel: 9),
  ];

  static Cosmetic? cosmetic(String id) => cosmetics.where((c) => c.id == id).firstOrNull;
  static Food? food(String id) => foods.where((f) => f.id == id).firstOrNull;

  static Iterable<Cosmetic> inSlot(Slot s) => cosmetics.where((c) => c.slot == s);

  /// Ids that every new pet owns.
  static Set<String> get starterOwned => cosmetics.where((c) => c.isFree).map((c) => c.id).toSet();

  static const defaultRoom = 'barn';
}

/// Rewards and level math. Kept as plain functions so the balance is
/// readable in one screen and testable without a widget tree.
class Economy {
  const Economy._();

  /// XP needed to go from [level] to level+1.
  static int xpForNext(int level) => 20 + 12 * level;

  static const maxLevel = 50;

  /// Daily gift: base + 1 per streak day beyond the first, streak capped at 7.
  static int dailyGift(int streakDay, {int base = 5}) => base + (streakDay.clamp(1, 7) - 1);

  /// Acorns paid for a mini-game score.
  static int miniGamePayout(int score) => (score / 3).floor().clamp(0, 40);

  /// Small acorn bonus for caring for a need that was low — rewards attention
  /// without making neglect profitable.
  static int careBonus(double needBefore) => needBefore < Needs.low ? 2 : (needBefore < 50 ? 1 : 0);
}

/// Growth stage, purely visual.
enum Stage { piglet, little, big }

Stage stageForLevel(int level) => level >= 10 ? Stage.big : (level >= 5 ? Stage.little : Stage.piglet);
