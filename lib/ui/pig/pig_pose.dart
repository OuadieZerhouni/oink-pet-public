import 'dart:math' as math;
import 'dart:ui';

import '../../pet/catalog.dart';

enum EyeMode { open, happy, closed, sleepy, surprised, sad, squint }

enum MouthMode { smile, oink, munch, frown, open }

/// Every animated parameter the painter reads. Plain data, rebuilt each frame
/// by [PigView]'s animation loop; the painter stays a pure function of it.
class PigPose {
  PigPose({
    this.breath = 0,
    this.blink = 0,
    this.eyes = EyeMode.open,
    this.mouth = MouthMode.smile,
    this.mouthOpen = 0,
    this.earLeft = 0,
    this.earRight = 0,
    this.tail = 0,
    this.snoutSquish = 0,
    this.headTilt = 0,
    this.bounce = 0,
    this.legKick = 0,
    this.look = Offset.zero,
    this.blush = 0.45,
    this.shake = 0,
  });

  /// 0…1 breathing phase value (already eased).
  double breath;

  /// 0 open … 1 fully closed (blink overlay on any open-eye mode).
  double blink;
  EyeMode eyes;
  MouthMode mouth;

  /// 0…1 how open the mouth is (oink / munch).
  double mouthOpen;

  /// Ear rotations in radians (positive = flop outward).
  double earLeft;
  double earRight;

  /// Tail wiggle in radians.
  double tail;

  /// 0…1 snout squash (on an oink or a boop).
  double snoutSquish;

  /// Head tilt in radians.
  double headTilt;

  /// Vertical hop in design units (negative = up).
  double bounce;

  /// 0…1 little front-leg kick (belly rub joy).
  double legKick;

  /// Pupil offset, −1…1 in each axis.
  Offset look;

  /// Cheek blush strength 0…1.
  double blush;

  /// Side-to-side head shake (refusing food), radians.
  double shake;
}

/// Geometry that depends only on the growth stage. Design space is 300×400
/// (the top ~90 units are headroom for ears and hats);
/// [PigPainter] scales it to fit.
class PigGeometry {
  const PigGeometry._(this.stage, this.headR, this.bodyRx, this.bodyRy, this.bodyCy);

  factory PigGeometry.forStage(Stage s) => switch (s) {
    Stage.piglet => const PigGeometry._(Stage.piglet, 90, 84, 66, 306),
    Stage.little => const PigGeometry._(Stage.little, 87, 96, 74, 304),
    Stage.big => const PigGeometry._(Stage.big, 84, 108, 82, 302),
  };

  static const designSize = Size(300, 400);

  final Stage stage;
  final double headR;
  final double bodyRx;
  final double bodyRy;
  final double bodyCy;

  Offset get headC => Offset(150, bodyCy - bodyRy - headR * 0.32);
  Offset get snoutC => headC + Offset(0, headR * 0.38);
  Size get snoutR => Size(headR * 0.42, headR * 0.29);
  Offset get eyeL => headC + Offset(-headR * 0.42, headR * 0.02);
  Offset get eyeR => headC + Offset(headR * 0.42, headR * 0.02);
  Offset get mouthC => snoutC + Offset(0, snoutR.height + headR * 0.13);
  Offset get earBaseL => headC + Offset(-headR * 0.58, -headR * 0.68);
  Offset get earBaseR => headC + Offset(headR * 0.58, -headR * 0.68);
  Offset get bodyC => Offset(150, bodyCy);
  Offset get tailBase => Offset(150 + bodyRx * 0.97, bodyCy - bodyRy * 0.12);

  /// Top of the head, where hats sit.
  Offset get crown => headC - Offset(0, headR * 0.84);

  /// Where a scarf / collar sits (between head and body).
  Offset get neck => Offset(150, headC.dy + headR * 0.86);

  Rect get bellyRect => Rect.fromCenter(center: bodyC + Offset(0, bodyRy * 0.25), width: bodyRx * 1.3, height: bodyRy * 1.2);

  /// Approximate ear hit circles.
  Offset get earHitL => earBaseL + Offset(-headR * 0.18, -headR * 0.28);
  Offset get earHitR => earBaseR + Offset(headR * 0.18, -headR * 0.28);

  static double ease(double t) => 0.5 - 0.5 * math.cos(math.pi * t.clamp(0.0, 1.0));
}
