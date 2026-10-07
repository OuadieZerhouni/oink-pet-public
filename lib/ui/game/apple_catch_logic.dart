import 'dart:math' as math;

/// What can fall. Points are added to the score; bees cost a heart.
enum FallKind {
  apple(1),
  golden(3),
  acorn(2),
  bee(0);

  const FallKind(this.points);
  final int points;
}

enum CatchEvent { caught, caughtBig, stung }

class FallingItem {
  FallingItem(this.kind, this.x, this.speed);
  final FallKind kind;

  /// 0…1 across the screen.
  double x;

  /// 0…1 down the screen (centre of the item).
  double y = -0.05;

  /// Screen heights per second.
  final double speed;
}

/// Pure game rules, in normalised screen units, so they can be tested
/// without a widget tree or a real clock.
class AppleCatchGame {
  AppleCatchGame({int? seed, this.duration = 45}) : _rng = math.Random(seed);

  static const maxHearts = 3;

  /// Vertical line (fraction of screen height) where the pig's mouth sits.
  static const pigLine = 0.82;

  /// Horizontal catch half-width, in screen fractions.
  static const catchHalfWidth = 0.11;

  final double duration;
  final math.Random _rng;
  final List<FallingItem> items = [];
  double pigX = 0.5;
  double elapsed = 0;
  int score = 0;
  int hearts = maxHearts;
  double _spawnIn = 0.6;

  double get timeLeft => math.max(0, duration - elapsed);
  bool get isOver => hearts <= 0 || elapsed >= duration;

  /// 0 at the start, 1 at the end: drives spawn rate and fall speed.
  double get difficulty => (elapsed / duration).clamp(0.0, 1.0);

  /// Advances the game by [dt] seconds and returns what happened this step.
  List<CatchEvent> step(double dt) {
    if (isOver) return const [];
    elapsed += dt;
    final events = <CatchEvent>[];
    _spawnIn -= dt;
    if (_spawnIn <= 0) {
      _spawn();
      _spawnIn = 0.85 - 0.45 * difficulty + _rng.nextDouble() * 0.25;
    }
    for (final it in items) {
      it.y += it.speed * dt;
    }
    items.removeWhere((it) {
      // Catch window: the item crosses the pig's mouth line near the pig.
      if (it.y >= pigLine - 0.06 && it.y <= pigLine + 0.03 && (it.x - pigX).abs() <= catchHalfWidth) {
        if (it.kind == FallKind.bee) {
          hearts = math.max(0, hearts - 1);
          events.add(CatchEvent.stung);
        } else {
          score += it.kind.points;
          events.add(it.kind == FallKind.apple ? CatchEvent.caught : CatchEvent.caughtBig);
        }
        return true;
      }
      return it.y > 1.08;
    });
    return events;
  }

  void _spawn() {
    final r = _rng.nextDouble();
    final beeChance = 0.12 + 0.16 * difficulty;
    final kind = r < beeChance
        ? FallKind.bee
        : (r < beeChance + 0.08 ? FallKind.golden : (r < beeChance + 0.22 ? FallKind.acorn : FallKind.apple));
    final speed = 0.32 + 0.3 * difficulty + _rng.nextDouble() * 0.08;
    items.add(FallingItem(kind, 0.08 + _rng.nextDouble() * 0.84, speed));
  }
}
