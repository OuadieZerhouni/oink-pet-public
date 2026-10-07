import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../core/app_services.dart';
import '../../core/sfx.dart';
import '../../l10n/l10n.dart';
import '../../pet/catalog.dart';
import '../pig/pig_painter.dart';
import '../pig/pig_pose.dart';
import '../room_painter.dart';
import '../art_icons.dart';
import '../theme.dart';
import '../widgets.dart';
import 'apple_catch_logic.dart';

/// "Apple Catch": slide the pig to catch falling treats, dodge bees.
class AppleCatchScreen extends StatefulWidget {
  const AppleCatchScreen({super.key, this.seed});

  /// Deterministic spawns for tests.
  final int? seed;

  @override
  State<AppleCatchScreen> createState() => _AppleCatchScreenState();
}

enum _Phase { ready, playing, over }

class _AppleCatchScreenState extends State<AppleCatchScreen> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final Ticker _ticker = createTicker(_onTick);
  late AppleCatchGame _game;
  _Phase _phase = _Phase.ready;
  Duration _last = Duration.zero;
  final _repaint = ValueNotifier<int>(0);
  int _earned = 0;
  bool _newBest = false;
  int _prevBest = 0;
  double _flash = 0; // >0 happy flash, <0 ouch flash

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _game = AppleCatchGame(seed: widget.seed);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker.dispose();
    _repaint.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Pause while a call, Control Center or the app switcher covers the game.
    // (Web previews report focus loss as "inactive" with no reliable resume,
    // so the pause is device-only.)
    if (_phase != _Phase.playing || kIsWeb) return;
    if (state == AppLifecycleState.resumed) {
      _last = Duration.zero;
      if (!_ticker.isActive) _ticker.start();
    } else if (_ticker.isActive) {
      _ticker.stop();
    }
  }

  void _start() {
    final s = AppScope.of(context);
    _prevBest = s.pet.state.stats.bestScore;
    setState(() {
      _game = AppleCatchGame(seed: widget.seed);
      _phase = _Phase.playing;
      _earned = 0;
      _newBest = false;
      _last = Duration.zero;
    });
    s.sfx.play(Sfx.oink);
    _ticker.start();
  }

  void _onTick(Duration now) {
    final dt = _last == Duration.zero ? 1 / 60 : ((now - _last).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _last = now;
    final s = AppScope.of(context);
    for (final e in _game.step(dt)) {
      switch (e) {
        case CatchEvent.caught:
          s.sfx.play(Sfx.catch_, volume: 0.8);
          _flash = 0.25;
        case CatchEvent.caughtBig:
          s.sfx.play(Sfx.acorn);
          s.sfx.bump();
          _flash = 0.4;
        case CatchEvent.stung:
          s.sfx.play(Sfx.bonk);
          s.sfx.thump();
          _flash = -0.45;
      }
    }
    _flash = _flash > 0 ? math.max(0, _flash - dt) : math.min(0, _flash + dt);
    if (_game.isOver) _finish();
    _repaint.value++;
  }

  void _finish() {
    _ticker.stop();
    final s = AppScope.of(context);
    _earned = s.pet.finishGame(_game.score);
    _newBest = _game.score > _prevBest && _game.score > 0;
    s.sfx.play(_newBest ? Sfx.levelup : Sfx.squealHappy);
    if (_earned > 0) Future<void>.delayed(const Duration(milliseconds: 600), () => s.sfx.play(Sfx.acorn));
    setState(() => _phase = _Phase.over);
  }

  void _moveTo(double x, double width) {
    if (_phase != _Phase.playing || width <= 0) return;
    _game.pigX = (x / width).clamp(0.08, 0.92);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final s = AppScope.of(context);
    final st = s.pet.state;
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, box) {
          final size = Size(box.maxWidth, box.maxHeight);
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            // The pig follows the finger directly — no lag, no inertia.
            onPanDown: (d) => _moveTo(d.localPosition.dx, size.width),
            onPanUpdate: (d) => _moveTo(d.localPosition.dx, size.width),
            child: Stack(
              // Every layer is positioned: a non-positioned HUD would shrink
              // the whole stack to its own height once the cards are gone.
              children: [
                Positioned.fill(child: CustomPaint(painter: RoomPainter('meadow', floorY: 0.9))),
                Positioned.fill(
                  child: CustomPaint(
                    painter: _GamePainter(this, st.stage, st.equipped[Slot.hat], st.equipped[Slot.glasses], st.equipped[Slot.neck]),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: ValueListenableBuilder<int>(
                        valueListenable: _repaint,
                        builder: (context, _, _) => Row(
                          children: [
                            IconButton(
                              tooltip: l.close,
                              style: IconButton.styleFrom(backgroundColor: Colors.white),
                              onPressed: () {
                                if (_phase == _Phase.playing) {
                                  _ticker.stop();
                                  _finish();
                                } else {
                                  Navigator.pop(context);
                                }
                              },
                              icon: const Icon(Icons.close_rounded, color: AppColors.inkSoft),
                            ),
                            const SizedBox(width: 8),
                            for (var i = 0; i < AppleCatchGame.maxHearts; i++)
                              Padding(
                                padding: const EdgeInsets.only(right: 2),
                                child: Icon(
                                  Icons.favorite_rounded,
                                  size: 26,
                                  color: i < _game.hearts ? AppColors.pinkDeep : Colors.white70,
                                ),
                              ),
                            const Spacer(),
                            SoftCard(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              radius: 18,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const ArtIconView(ArtIcon.apple, size: 22),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${_game.score}',
                                    style: const TextStyle(
                                      fontFamily: 'Fredoka',
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  const Icon(Icons.timer_rounded, size: 18, color: AppColors.inkSoft),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${_game.timeLeft.ceil()}',
                                    style: const TextStyle(
                                      fontFamily: 'Fredoka',
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                if (_phase == _Phase.ready)
                  Positioned.fill(
                    child: _ReadyCard(name: st.name, best: st.stats.bestScore, onStart: _start),
                  ),
                if (_phase == _Phase.over)
                  Positioned.fill(
                    child: _ResultCard(
                      score: _game.score,
                      best: s.pet.state.stats.bestScore,
                      newBest: _newBest,
                      earned: _earned,
                      onAgain: () {
                        if (s.pet.state.needs.energy < 15) {
                          Navigator.pop(context);
                          return;
                        }
                        _start();
                      },
                      onBack: () => Navigator.pop(context),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _GamePainter extends CustomPainter {
  _GamePainter(this.s, this.stage, this.hat, this.glasses, this.neck) : super(repaint: s._repaint);
  final _AppleCatchScreenState s;
  final Stage stage;
  final String? hat, glasses, neck;
  static ArtIcon _icon(FallKind k) => switch (k) {
    FallKind.apple => ArtIcon.apple,
    FallKind.golden => ArtIcon.star,
    FallKind.acorn => ArtIcon.acorn,
    FallKind.bee => ArtIcon.bee,
  };

  @override
  void paint(Canvas canvas, Size size) {
    final g = s._game;
    final itemSize = (size.width * 0.11).clamp(34.0, 56.0);
    for (final it in g.items) {
      final p = Offset(it.x * size.width, it.y * size.height);
      canvas.save();
      canvas.translate(p.dx, p.dy);
      if (it.kind == FallKind.bee) canvas.rotate(math.sin(it.y * 40) * 0.2);
      ArtIconPainter.paintAt(canvas, _icon(it.kind), Offset(-itemSize / 2, -itemSize / 2), itemSize);
      canvas.restore();
    }
    // Pig
    final pigW = (size.width * 0.34).clamp(110.0, 170.0);
    final pigH = pigW * PigGeometry.designSize.height / PigGeometry.designSize.width;
    final rect = Rect.fromLTWH(g.pigX * size.width - pigW / 2, size.height * AppleCatchGame.pigLine - pigH * 0.62, pigW, pigH);
    canvas.save();
    canvas.translate(rect.left, rect.top);
    final f = s._flash;
    final pose = PigPose(
      eyes: f > 0 ? EyeMode.happy : (f < 0 ? EyeMode.squint : EyeMode.open),
      mouth: f < 0 ? MouthMode.frown : MouthMode.open,
      mouthOpen: f > 0 ? 1 : 0.5,
      blush: f > 0 ? 1 : 0.5,
      bounce: f > 0 ? -8 : 0,
      shake: f < 0 ? math.sin(f * 60) * 0.12 : 0,
    );
    PigPainter(pose: pose, geometry: PigGeometry.forStage(stage), hat: hat, glasses: glasses, neck: neck).paint(canvas, rect.size);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_GamePainter old) => true;
}

class _ReadyCard extends StatelessWidget {
  const _ReadyCard({required this.name, required this.best, required this.onStart});
  final String name;
  final int best;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: SoftCard(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          radius: 28,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [ArtIconView(ArtIcon.apple, size: 44), ArtIconView(ArtIcon.star, size: 44), ArtIconView(ArtIcon.bee, size: 44)],
              ),
              const SizedBox(height: 8),
              Text(l.gameTitle, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(l.gameHow(name), textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge),
              if (best > 0) ...[const SizedBox(height: 8), Text(l.gameBest(best), style: Theme.of(context).textTheme.bodySmall)],
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(onPressed: onStart, child: Text(l.gameStart)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.score,
    required this.best,
    required this.newBest,
    required this.earned,
    required this.onAgain,
    required this.onBack,
  });
  final int score, best, earned;
  final bool newBest;
  final VoidCallback onAgain, onBack;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Container(
      color: const Color(0x55000000),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(28),
      child: SoftCard(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        radius: 28,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(newBest ? l.gameNewBest : l.gameOver, style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
            const SizedBox(height: 10),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const ArtIconView(ArtIcon.apple, size: 44),
                const SizedBox(width: 8),
                Text('$score', style: const TextStyle(fontFamily: 'Fredoka', fontSize: 44, fontWeight: FontWeight.w600, color: AppColors.pinkDeep)),
              ],
            ),
            Text(l.gameBest(best), style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AcornIcon(size: 26),
                const SizedBox(width: 6),
                Text(
                  l.gameEarned(earned),
                  style: const TextStyle(fontFamily: 'Fredoka', fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.acorn),
                ),
              ],
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(onPressed: onAgain, child: Text(l.gameAgain)),
            ),
            TextButton(onPressed: onBack, child: Text(l.gameBack)),
          ],
        ),
      ),
    );
  }
}
