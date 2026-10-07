import 'package:flutter/gestures.dart';

import '../pet/catalog.dart';
import '../pet/needs.dart';
import '../pet/pet_state.dart';

/// Store-screenshot scenes: `--dart-define=DEBUG_MARKETING_SCENE=<id>` boots the
/// real app straight into one pose for `screenshots.py capture`, which can only
/// vary compile-time defines. A compile-time constant, so release builds drop it.
///
/// Ids: `home`, `love`, `bath`, `feed`, `closet`, `game`.
class MarketingScene {
  const MarketingScene._();

  static const String id = String.fromEnvironment('DEBUG_MARKETING_SCENE');
  static const bool active = id != '';

  /// The same piglet in every slide, so the set reads as one pet.
  static PetState seed(DateTime now) {
    final needs = switch (id) {
      'bath' => const Needs(tummy: 82, clean: 22, fun: 80, energy: 85),
      'feed' => const Needs(tummy: 35, clean: 90, fun: 80, energy: 85),
      _ => const Needs(tummy: 86, clean: 92, fun: 84, energy: 88),
    };
    return PetState.fresh(now).copyWith(
      onboarded: true,
      name: 'Oinky',
      level: 3,
      acorns: 128,
      needs: needs,
      lastGiftDay: dayKey(now),
      owned: {...Catalog.starterOwned, 'flowers', 'crown', 'hearts', 'round', 'bowtie'},
      equipped: id == 'closet'
          ? {Slot.hat: 'crown', Slot.glasses: 'hearts', Slot.room: Catalog.defaultRoom}
          : {Slot.hat: 'bow', Slot.room: Catalog.defaultRoom},
    );
  }
}

/// A synthesised finger, sent through the real gesture pipeline so scenes show
/// what the app actually does with a touch.
class ScenePointer {
  ScenePointer(this.pointer);

  final int pointer;
  Offset _last = Offset.zero;

  void down(Offset p) {
    _last = p;
    GestureBinding.instance.handlePointerEvent(PointerDownEvent(pointer: pointer, position: p));
  }

  void move(Offset p) {
    GestureBinding.instance.handlePointerEvent(PointerMoveEvent(pointer: pointer, position: p, delta: p - _last));
    _last = p;
  }

  void up() => GestureBinding.instance.handlePointerEvent(PointerUpEvent(pointer: pointer, position: _last));
}
