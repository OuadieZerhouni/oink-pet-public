import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../pet/catalog.dart';
import '../../pet/needs.dart';
import '../../pet/pet_controller.dart';
import 'particles.dart';
import 'pig_painter.dart';
import 'pig_pose.dart';

/// One-shot reactions the pig can play.
enum Reaction { oink, happy, giggle, earFlop, tailSpin, munch, refuse, sparkle, surprised, grumble, levelUp, yawn }

/// How touches on the pig are interpreted.
enum PigMode { normal, bath, asleep }

/// Imperative handle so screens can trigger reactions without rebuilding.
class PigViewController {
  _PigViewState? _state;

  void react(Reaction r, {PetZone? side}) => _state?._react(r, side: side);
  void burst(ParticleKind kind, {int count = 6, Offset? at}) => _state?._burstAt(kind, count: count, at: at);

  /// Open the mouth in anticipation while food is dragged over the pig.
  set anticipating(bool v) => _state?._anticipating = v;

  /// Where the pig's mouth is, in the view's local coordinates.
  Offset? get mouthLocal => _state?._mouthLocal();
}

class PigView extends StatefulWidget {
  const PigView({
    super.key,
    required this.controller,
    required this.stage,
    required this.needs,
    this.mode = PigMode.normal,
    this.hat,
    this.glasses,
    this.neck,
    this.onZone,
    this.onRub,
    this.onScrub,
    this.animate = true,
  });

  final PigViewController controller;
  final Stage stage;
  final Needs needs;
  final PigMode mode;
  final String? hat;
  final String? glasses;
  final String? neck;

  /// A tap landed on a zone.
  final void Function(PetZone zone)? onZone;

  /// A back-and-forth rub was detected on a zone (fires once per stroke).
  final void Function(PetZone zone)? onRub;

  /// Bath mode: the sponge moved over the pig by [distance] design units.
  final void Function(double distance)? onScrub;

  /// False in tests that only need a still frame.
  final bool animate;

  @override
  State<PigView> createState() => _PigViewState();
}

class _ActiveReaction {
  _ActiveReaction(this.kind, this.duration, this.side);
  final Reaction kind;
  final double duration;
  final PetZone? side;
  double t = 0;
  double get progress => (t / duration).clamp(0.0, 1.0);
}

class _PigViewState extends State<PigView> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final _rng = math.Random();
  final _pose = PigPose();
  final _particles = ParticleField();
  final _repaint = ValueNotifier<int>(0);
  Duration _last = Duration.zero;
  double _time = 0;
  double _nextBlink = 2.5;
  double _blinkT = -1;
  double _nextTwitch = 4;
  double _twitchT = -1;
  bool _twitchLeft = true;
  double _zzzT = 0;
  _ActiveReaction? _reaction;
  bool _anticipating = false;
  double _anticipation = 0;
  Offset _look = Offset.zero;
  Offset? _finger;
  Size _size = Size.zero;

  // rub detection
  PetZone? _rubZone;
  double _rubDir = 0;
  double _rubTravel = 0;
  Offset? _lastPan;

  PigGeometry get _geo => PigGeometry.forStage(widget.stage);

  @override
  void initState() {
    super.initState();
    widget.controller._state = this;
    _ticker = createTicker(_onTick);
    // Settle the pose once so a still (non-animated) frame already reflects
    // the pig's mood.
    _update(1 / 60);
    if (widget.animate) _ticker.start();
  }

  @override
  void didUpdateWidget(PigView old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller._state = null;
      widget.controller._state = this;
    }
  }

  @override
  void dispose() {
    if (widget.controller._state == this) widget.controller._state = null;
    _ticker.dispose();
    _repaint.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------- animation
  void _onTick(Duration now) {
    final dt = _last == Duration.zero ? 1 / 60 : ((now - _last).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _last = now;
    _time += dt;
    _update(dt);
    _repaint.value++;
  }

  void _update(double dt) {
    final asleep = widget.mode == PigMode.asleep;
    final needs = widget.needs;
    final p = _pose;

    // Baseline mood from needs.
    final sad = needs.wellbeing < 0.38;
    final tired = needs.energy < Needs.low;
    var eyes = asleep ? EyeMode.closed : (tired ? EyeMode.sleepy : (sad ? EyeMode.sad : EyeMode.open));
    var mouth = sad && !asleep ? MouthMode.frown : MouthMode.smile;
    var mouthOpen = 0.0;
    var snout = 0.0;
    var bounce = 0.0;
    var legKick = 0.0;
    var shake = 0.0;
    var tilt = math.sin(_time * 0.7) * 0.03;
    var earL = 0.05 * math.sin(_time * 1.3);
    var earR = 0.05 * math.sin(_time * 1.3 + 1.2);
    var tail = 0.25 * math.sin(_time * (asleep ? 1.2 : 3.2));
    var blush = asleep ? 0.3 : 0.45;
    if (sad) {
      earL += 0.35;
      earR += 0.35;
    }

    // Breathing.
    final breathPeriod = asleep ? 4.6 : 3.0;
    p.breath = 0.5 - 0.5 * math.cos(2 * math.pi * _time / breathPeriod);

    // Blinks (awake only).
    if (!asleep && eyes != EyeMode.sleepy) {
      _nextBlink -= dt;
      if (_nextBlink <= 0 && _blinkT < 0) {
        _blinkT = 0;
        _nextBlink = 2.2 + _rng.nextDouble() * 3.5;
      }
    }
    var blink = 0.0;
    if (_blinkT >= 0) {
      _blinkT += dt;
      const bd = 0.16;
      blink = _blinkT < bd ? math.sin(math.pi * _blinkT / bd) : 0;
      if (_blinkT >= bd) _blinkT = -1;
    }

    // Ear twitch.
    if (!asleep) {
      _nextTwitch -= dt;
      if (_nextTwitch <= 0 && _twitchT < 0) {
        _twitchT = 0;
        _twitchLeft = _rng.nextBool();
        _nextTwitch = 3 + _rng.nextDouble() * 5;
      }
    }
    if (_twitchT >= 0) {
      _twitchT += dt;
      final k = math.sin(math.pi * (_twitchT / 0.3).clamp(0.0, 1.0)) * 0.3;
      if (_twitchLeft) {
        earL += k;
      } else {
        earR += k;
      }
      if (_twitchT >= 0.3) _twitchT = -1;
    }

    // Anticipation while food hovers.
    _anticipation += ((_anticipating ? 1.0 : 0.0) - _anticipation) * (dt * 10).clamp(0.0, 1.0);
    if (_anticipation > 0.05 && !asleep) {
      mouth = MouthMode.open;
      mouthOpen = _anticipation;
      eyes = EyeMode.surprised;
      blush = 0.7;
    }

    // Reaction overrides.
    final r = _reaction;
    if (r != null) {
      r.t += dt;
      final k = r.progress;
      final env = math.sin(math.pi * k);
      switch (r.kind) {
        case Reaction.oink:
          mouth = MouthMode.oink;
          mouthOpen = env;
          snout = env;
          eyes = EyeMode.squint;
          bounce = -10 * env;
          earL -= 0.2 * env;
          earR -= 0.2 * env;
        case Reaction.happy:
          eyes = EyeMode.happy;
          blush = 0.95;
          bounce = -8 * math.sin(math.pi * k * 2).abs();
          earL -= 0.25 * env;
          earR -= 0.25 * env;
          tail += 0.6 * math.sin(_time * 18);
        case Reaction.giggle:
          eyes = EyeMode.squint;
          mouth = MouthMode.open;
          mouthOpen = 0.5 + 0.5 * math.sin(_time * 28).abs();
          legKick = math.sin(_time * 22).abs() * env;
          bounce = -4 * math.sin(_time * 24).abs();
          blush = 1;
          tail += 0.8 * math.sin(_time * 20);
        case Reaction.earFlop:
          final flop = 0.9 * env;
          if (r.side == PetZone.ear && _twitchLeft) {
            earL += flop;
          } else {
            earR += flop;
          }
          eyes = EyeMode.surprised;
        case Reaction.tailSpin:
          tail += 2 * math.pi * k * 2;
          eyes = EyeMode.surprised;
          mouth = MouthMode.oink;
          mouthOpen = env * 0.6;
          bounce = -6 * env;
        case Reaction.munch:
          mouth = MouthMode.munch;
          mouthOpen = 0.5 + 0.5 * math.sin(_time * 22);
          eyes = k > 0.6 ? EyeMode.happy : EyeMode.squint;
          blush = 0.8;
        case Reaction.refuse:
          shake = 0.16 * math.sin(k * math.pi * 6) * (1 - k);
          mouth = MouthMode.frown;
          eyes = EyeMode.squint;
        case Reaction.sparkle:
          eyes = EyeMode.happy;
          blush = 0.9;
          bounce = -12 * env;
        case Reaction.surprised:
          eyes = EyeMode.surprised;
          mouth = MouthMode.open;
          mouthOpen = env * 0.6;
        case Reaction.grumble:
          shake = 0.05 * math.sin(k * math.pi * 4);
          blush = 0.5;
        case Reaction.levelUp:
          eyes = EyeMode.happy;
          blush = 1;
          bounce = -26 * math.sin(math.pi * (k * 2).clamp(0.0, 1.0));
          earL -= 0.3 * env;
          earR -= 0.3 * env;
        case Reaction.yawn:
          mouth = MouthMode.open;
          mouthOpen = env;
          eyes = EyeMode.closed;
          tilt += 0.08 * env;
      }
      if (r.t >= r.duration) _reaction = null;
    }

    // Eyes follow the finger.
    final target = _finger == null
        ? Offset(0.35 * math.sin(_time * 0.4), 0.2 * math.sin(_time * 0.53))
        : _lookToward(_finger!);
    _look = Offset.lerp(_look, target, (dt * 8).clamp(0.0, 1.0))!;

    p
      ..blink = blink
      ..eyes = eyes
      ..mouth = mouth
      ..mouthOpen = mouthOpen
      ..snoutSquish = snout
      ..bounce = bounce
      ..legKick = legKick
      ..shake = shake
      ..headTilt = tilt
      ..earLeft = earL
      ..earRight = earR
      ..tail = tail
      ..blush = blush
      ..look = _look;

    // Zzz while asleep.
    if (asleep) {
      _zzzT -= dt;
      if (_zzzT <= 0) {
        _zzzT = 1.1;
        final g = _geo;
        _particles.add(Particle(
          kind: ParticleKind.zzz,
          pos: g.headC + Offset(g.headR * 0.7, -g.headR * 0.6),
          vel: Offset(18 + _rng.nextDouble() * 10, -38),
          life: 2.4,
          size: 9 + _rng.nextDouble() * 5,
        ));
      }
    }
    _particles.step(dt);
  }

  Offset _lookToward(Offset design) {
    final d = design - _geo.headC;
    final len = d.distance;
    if (len < 1) return Offset.zero;
    final n = d / len;
    return Offset(n.dx, n.dy) * (len / 120).clamp(0.0, 1.0);
  }

  void _react(Reaction r, {PetZone? side}) {
    const durations = {
      Reaction.oink: 0.45,
      Reaction.happy: 1.1,
      Reaction.giggle: 1.0,
      Reaction.earFlop: 0.6,
      Reaction.tailSpin: 0.8,
      Reaction.munch: 1.3,
      Reaction.refuse: 0.9,
      Reaction.sparkle: 1.0,
      Reaction.surprised: 0.6,
      Reaction.grumble: 0.6,
      Reaction.levelUp: 1.4,
      Reaction.yawn: 1.2,
    };
    _reaction = _ActiveReaction(r, durations[r]!, side);
    final g = _geo;
    switch (r) {
      case Reaction.happy:
        _particles.burst(ParticleKind.heart, g.headC - Offset(0, g.headR * 0.9), count: 4);
      case Reaction.giggle:
        _particles.burst(ParticleKind.heart, g.bodyC - Offset(0, g.bodyRy * 0.2), count: 3, size: 10);
      case Reaction.munch:
        _particles.burst(ParticleKind.crumb, g.mouthC, count: 7, speed: 70, size: 10);
      case Reaction.sparkle:
        _particles.burst(ParticleKind.sparkle, g.headC, count: 9, speed: 110, size: 13);
      case Reaction.levelUp:
        _particles.burst(ParticleKind.sparkle, g.headC - Offset(0, g.headR), count: 12, speed: 130, size: 14);
        _particles.burst(ParticleKind.heart, g.headC - Offset(0, g.headR), count: 5, speed: 90);
      default:
        break;
    }
  }

  void _burstAt(ParticleKind kind, {int count = 6, Offset? at}) {
    _particles.burst(kind, at ?? _geo.headC, count: count, speed: kind == ParticleKind.drop ? 30 : 60, size: kind == ParticleKind.bubble ? 9 : 12);
  }

  Offset? _mouthLocal() {
    if (_size == Size.zero) return null;
    final m = PigPainter.designToCanvas(_size);
    final mc = _geo.mouthC;
    final v = m.storage;
    return Offset(v[0] * mc.dx + v[12], v[5] * mc.dy + v[13]);
  }

  // ------------------------------------------------------------- gestures
  PetZone? _zoneAt(Offset design) {
    final g = _geo;
    bool inEllipse(Offset c, double rx, double ry) {
      final d = design - c;
      return (d.dx * d.dx) / (rx * rx) + (d.dy * d.dy) / (ry * ry) <= 1;
    }

    if (inEllipse(g.snoutC, g.snoutR.width * 1.25, g.snoutR.height * 1.4)) return PetZone.snout;
    if ((design - g.earHitL).distance < g.headR * 0.32 || (design - g.earHitR).distance < g.headR * 0.32) {
      _twitchLeft = (design - g.earHitL).distance < (design - g.earHitR).distance;
      return PetZone.ear;
    }
    if ((design - (g.tailBase + const Offset(12, -6))).distance < 26) return PetZone.tail;
    if (inEllipse(g.headC, g.headR * 1.06, g.headR * 0.98)) return PetZone.head;
    if (inEllipse(g.bodyC, g.bodyRx * 1.05, g.bodyRy * 1.1)) return PetZone.belly;
    return null;
  }

  Offset _toDesign(Offset local) => PigPainter.canvasToDesign(_size, local);

  void _onTapUp(TapUpDetails d) {
    final z = _zoneAt(_toDesign(d.localPosition));
    if (z != null) widget.onZone?.call(z);
  }

  void _onPanStart(DragStartDetails d) {
    _lastPan = _toDesign(d.localPosition);
    _finger = _lastPan;
    _rubZone = _zoneAt(_lastPan!);
    _rubDir = 0;
    _rubTravel = 0;
  }

  void _onPanUpdate(DragUpdateDetails d) {
    final pos = _toDesign(d.localPosition);
    final prev = _lastPan ?? pos;
    _lastPan = pos;
    _finger = pos;
    final delta = pos - prev;
    if (widget.mode == PigMode.bath) {
      final z = _zoneAt(pos);
      if (z != null && delta.distance > 0.5) {
        widget.onScrub?.call(delta.distance);
        if (_rng.nextDouble() < 0.35) {
          _particles.burst(ParticleKind.bubble, pos, count: 1, speed: 40, size: 9);
        }
      }
      return;
    }
    final z = _zoneAt(pos);
    if (z == null || (z != PetZone.belly && z != PetZone.head)) return;
    _rubZone = z;
    _rubTravel += delta.dx.abs();
    final dir = delta.dx.sign;
    if (dir != 0 && dir != _rubDir) {
      if (_rubDir != 0 && _rubTravel > 14) {
        widget.onRub?.call(_rubZone!);
        _rubTravel = 0;
      }
      _rubDir = dir;
    }
  }

  void _onPanEnd(DragEndDetails d) {
    _finger = null;
    _lastPan = null;
    _rubZone = null;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        _size = Size(box.maxWidth, box.maxHeight);
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: _onTapUp,
          onPanStart: _onPanStart,
          onPanUpdate: _onPanUpdate,
          onPanEnd: _onPanEnd,
          child: RepaintBoundary(
            child: CustomPaint(
              size: _size,
              painter: _PigLayer(this),
            ),
          ),
        );
      },
    );
  }
}

class _PigLayer extends CustomPainter {
  _PigLayer(this.s) : super(repaint: s._repaint);
  final _PigViewState s;

  @override
  void paint(Canvas canvas, Size size) {
    final w = s.widget;
    PigPainter(
      pose: s._pose,
      geometry: s._geo,
      clean: w.needs.clean,
      hat: w.hat,
      glasses: w.glasses,
      neck: w.neck,
    ).paint(canvas, size);
    if (!s._particles.isEmpty) {
      canvas.save();
      canvas.transform(PigPainter.designToCanvas(size).storage);
      s._particles.paint(canvas);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_PigLayer old) => true;
}
