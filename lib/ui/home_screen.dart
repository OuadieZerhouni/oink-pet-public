import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/app_services.dart';
import '../core/debug_flags.dart';
import '../core/marketing_scene.dart';
import '../core/sfx.dart';
import '../core/test_env.dart';
import '../l10n/app_localizations.dart';
import '../l10n/l10n.dart';
import '../pet/catalog.dart';
import '../pet/needs.dart';
import '../pet/pet_controller.dart';
import '../pet/pet_state.dart';
import 'art_icons.dart';
import 'closet_screen.dart';
import 'game/apple_catch_screen.dart';
import 'names.dart';
import 'pig/particles.dart';
import 'pig/pig_pose.dart';
import 'pig/pig_view.dart';
import 'room_painter.dart';
import 'settings_screen.dart';
import 'stats_sheet.dart';
import 'theme.dart';
import 'widgets.dart';

enum _Mode { normal, feed, bath }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final _pig = PigViewController();
  final _rng = math.Random();
  _Mode _mode = _Mode.normal;
  String? _bubble;
  Timer? _bubbleTimer;
  Timer? _tick;
  StreamSubscription<PetEvent>? _events;
  DateTime _lastSpoke = DateTime.fromMillisecondsSinceEpoch(0);
  double _bathStartClean = 100;
  Offset? _sponge;
  final _pigKey = GlobalKey();
  bool _rinsing = false;
  bool _dialogOpen = false;
  late AppServices _s;
  bool _started = false;

  PetController get _pet => _s.pet;
  SfxPlayer get _sfx => _s.sfx;
  PetState get _state => _pet.state;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _s = AppScope.of(context);
    _events = _pet.events.listen(_onEvent);
    _tick = Timer.periodic(const Duration(seconds: 20), (_) => _onTick());
    WidgetsBinding.instance.addPostFrameCallback((_) => _onFirstFrame());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _bubbleTimer?.cancel();
    _tick?.cancel();
    _events?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _pet.sync();
      _s.remote.refresh();
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _pet.flush();
    }
  }

  // --------------------------------------------------------------- lifecycle
  Future<void> _onFirstFrame() async {
    if (!mounted) return;
    if (MarketingScene.active) return _runScene();
    final l = context.l10n;
    if (_state.asleep) {
      _say(l.sleepingHint(_state.name), long: true);
    } else {
      _say(l.sayHi(_state.name));
      _sfx.play(Sfx.oink, pitch: _pitch);
    }
    await _maybeShowUpdateOrAnnouncement();
  }

  void _onTick() {
    if (!mounted) return;
    _pet.sync();
    if (_state.asleep) {
      final life = WidgetsBinding.instance.lifecycleState;
      final visible = (ModalRoute.of(context)?.isCurrent ?? true) && (life == null || life == AppLifecycleState.resumed);
      if (visible) _sfx.play(Sfx.snore, volume: 0.45, pitch: _pitch);
      return;
    }
    if (_mode != _Mode.normal) return;
    if (DateTime.now().difference(_lastSpoke) < const Duration(seconds: 25)) return;
    final l = context.l10n;
    final urgent = _state.needs.mostUrgent;
    if (urgent != null) {
      _say(_needLine(l, urgent));
      if (urgent == Need.tummy || urgent == Need.fun) _sfx.play(Sfx.snort);
    } else if (_isNight) {
      _say(l.sayNight);
    } else if (_rng.nextDouble() < 0.35) {
      _say(_rng.nextBool() ? l.sayLove : l.sayOink);
      _pig.react(Reaction.happy);
    }
  }

  bool get _isNight {
    final h = _pet.clock().hour;
    return h >= 22 || h < 7;
  }

  String _needLine(AppLocalizations l, Need n) => switch (n) {
    Need.tummy => l.sayHungry,
    Need.clean => l.sayDirty,
    Need.fun => l.sayBored,
    Need.energy => l.saySleepy,
  };

  double get _pitch => switch (_state.stage) {
    Stage.piglet => 1.12 + _rng.nextDouble() * 0.1,
    Stage.little => 1.0 + _rng.nextDouble() * 0.1,
    Stage.big => 0.88 + _rng.nextDouble() * 0.1,
  };

  void _say(String text, {bool long = false, bool chatter = true}) {
    _bubbleTimer?.cancel();
    setState(() => _bubble = text);
    if (chatter) _lastSpoke = DateTime.now();
    _bubbleTimer = Timer(Duration(milliseconds: long ? 3600 : 2400), () {
      if (mounted) setState(() => _bubble = null);
    });
  }

  Future<void> _onEvent(PetEvent e) async {
    if (!mounted) return;
    final l = context.l10n;
    switch (e) {
      case WokeUp():
        _sfx.play(Sfx.wake);
        _pig.react(Reaction.happy);
        _say(l.sayMorning);
      case LevelUp(:final level, :final grew):
        // Let the triggering animation (munch, sparkle…) play first.
        await Future<void>.delayed(const Duration(milliseconds: 900));
        if (!mounted) return;
        _sfx.play(Sfx.levelup);
        _pig.react(Reaction.levelUp);
        await _showLevelUp(level, grew);
        await _maybeAskReview();
    }
  }

  // ------------------------------------------------------------------ pig
  void _onZone(PetZone zone) {
    final l = context.l10n;
    if (_state.asleep) {
      _pig.react(Reaction.grumble);
      _sfx.play(Sfx.snort, volume: 0.5, minGap: const Duration(milliseconds: 600));
      _say(l.sayGrumble);
      return;
    }
    if (_mode == _Mode.bath) return;
    _pet.pet(zone);
    _sfx.bump();
    switch (zone) {
      case PetZone.snout:
        _pig.react(Reaction.oink);
        _sfx.play(Sfx.oink, pitch: _pitch);
        _say(l.sayOink, chatter: false);
      case PetZone.head:
        _pig.react(Reaction.happy);
        _sfx.play(_rng.nextDouble() < 0.3 ? Sfx.squealHappy : Sfx.snort, pitch: _pitch);
        if (_rng.nextDouble() < 0.3) _say(l.sayLove);
      case PetZone.belly:
        _pig.react(Reaction.giggle);
        _sfx.play(Sfx.giggle, pitch: _pitch);
        if (_rng.nextDouble() < 0.4) _say(l.sayGiggle);
      case PetZone.ear:
        _pig.react(Reaction.earFlop, side: zone);
        _sfx.play(Sfx.snort, pitch: _pitch);
      case PetZone.tail:
        _pig.react(Reaction.tailSpin);
        _sfx.play(Sfx.oink, pitch: _pitch * 1.15);
        _say(l.sayOinkQ);
    }
  }

  void _onRub(PetZone zone) {
    if (_state.asleep) {
      if (_bubble == null) {
        _pig.react(Reaction.grumble);
        _sfx.play(Sfx.snort, volume: 0.5, minGap: const Duration(milliseconds: 600));
        _say(context.l10n.sayGrumble);
      }
      return;
    }
    if (_mode != _Mode.normal) return;
    _pet.pet(zone);
    _sfx.tick();
    if (zone == PetZone.belly) {
      _pig.react(Reaction.giggle);
      _sfx.play(Sfx.giggle, pitch: _pitch, minGap: const Duration(milliseconds: 900));
    } else {
      _pig.react(Reaction.happy);
      _sfx.play(Sfx.squealHappy, pitch: _pitch, minGap: const Duration(milliseconds: 1400));
    }
  }

  // ----------------------------------------------------------------- feed
  void _onFood(Food f) {
    final l = context.l10n;
    _pig.anticipating = false;
    switch (_pet.feed(f)) {
      case FeedResult.ate:
        _sfx.play(Sfx.munch);
        _sfx.bump();
        _pig.react(Reaction.munch);
        Future<void>.delayed(const Duration(milliseconds: 1000), () {
          if (!mounted) return;
          _sfx.play(Sfx.gulp);
          _pig.react(Reaction.happy);
        });
        _say(l.sayYum);
      case FeedResult.full:
        _pig.react(Reaction.refuse);
        _sfx.play(Sfx.snort);
        _say(l.sayFull);
      case FeedResult.locked:
        _pig.react(Reaction.surprised);
        _say(l.sayLocked);
      case FeedResult.asleep:
        break;
    }
  }

  // ----------------------------------------------------------------- bath
  void _startBath() {
    _bathStartClean = _state.needs.clean;
    setState(() => _mode = _Mode.bath);
    _sfx.play(Sfx.bubbles);
    _say(context.l10n.bathHint);
  }

  void _onScrub(double distance) {
    _pet.scrub(distance * 0.16);
    _sfx.play(Sfx.scrub, volume: 0.6, minGap: const Duration(milliseconds: 420));
    _sfx.play(Sfx.bubbles, volume: 0.35, minGap: const Duration(milliseconds: 1100));
  }

  Future<void> _rinse() async {
    if (_rinsing) return;
    setState(() => _rinsing = true);
    _sfx.play(Sfx.shower);
    for (var i = 0; i < 4; i++) {
      _pig.burst(ParticleKind.drop, count: 8, at: Offset(70.0 + i * 55, 90));
      await Future<void>.delayed(const Duration(milliseconds: 220));
      if (!mounted) return;
    }
    _pet.rinse(startClean: _bathStartClean);
    _sfx.play(Sfx.sparkle);
    _pig.react(Reaction.sparkle);
    _say(context.l10n.sayClean);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() {
      _rinsing = false;
      _mode = _Mode.normal;
      _sponge = null;
    });
  }

  // ------------------------------------------------------- marketing scenes
  /// Poses for the store screenshots (see [MarketingScene]); touches go through
  /// the real gesture pipeline.
  Future<void> _runScene() async {
    Future<void> wait(int ms) => Future<void>.delayed(Duration(milliseconds: ms));
    await wait(500);
    if (!mounted) return;
    final l = context.l10n;
    final box = _pigKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final pig = box.localToGlobal(Offset.zero) & box.size;
    final screen = MediaQuery.sizeOf(context);
    final belly = Offset(pig.center.dx, pig.top + pig.height * 0.8);
    final finger = ScenePointer(900);
    switch (MarketingScene.id) {
      case 'love':
        _say(l.sayGiggle, long: true);
        finger.down(belly);
        for (var i = 0; mounted && i < 2000; i++) {
          await wait(16);
          finger.move(belly + Offset(34 * math.sin(i / 5), 0));
          if (i % 120 == 0) _say(l.sayGiggle, long: true);
        }
      case 'bath':
        _startBath();
        await wait(300);
        finger.down(belly);
        for (var i = 0; mounted && i < 2000; i++) {
          await wait(16);
          finger.move(belly + Offset(40 * math.sin(i / 9), 14 * math.cos(i / 9)));
        }
      case 'feed':
        _toggleFeed();
        await wait(700);
        final apple = Offset(56, screen.height - 97);
        final mouth = Offset(pig.center.dx, pig.top + pig.height * 0.66);
        finger.down(apple);
        for (var i = 1; mounted && i <= 30; i++) {
          await wait(16);
          finger.move(Offset.lerp(apple, mouth, 0.78 * i / 30)!);
        }
        _say(l.sayHungry, long: true);
      case 'closet':
        unawaited(_openCloset());
      case 'game':
        unawaited(_play());
        await wait(900);
        finger
          ..down(Offset(screen.width / 2, screen.height * 0.607))
          ..up();
        await wait(300);
        final at = Offset(screen.width / 2, screen.height * 0.87);
        final drag = ScenePointer(901)..down(at);
        for (var i = 0; mounted && i < 2000; i++) {
          await wait(16);
          drag.move(at + Offset(screen.width * 0.32 * math.sin(i / 40), 0));
        }
      default:
        for (var i = 0; mounted && i < 200; i++) {
          _say(l.sayHi(_state.name), long: true);
          if (i.isEven) _pig.react(Reaction.happy);
          await wait(2000);
        }
    }
  }

  // ----------------------------------------------------------- dock actions
  void _toggleFeed() {
    _sfx.play(Sfx.pop);
    if (_state.asleep) return _sayAsleep();
    setState(() => _mode = _mode == _Mode.feed ? _Mode.normal : _Mode.feed);
    if (_mode == _Mode.feed) _say(context.l10n.feedHint(_state.name));
  }

  void _toggleBath() {
    _sfx.play(Sfx.pop);
    if (_state.asleep) return _sayAsleep();
    _startBath();
  }

  Future<void> _play() async {
    _sfx.play(Sfx.pop);
    if (_state.asleep) return _sayAsleep();
    if (!_s.remote.value.miniGameEnabled) return;
    if (_state.needs.energy < 15) {
      _say(context.l10n.tooTiredToPlay(_state.name), long: true);
      _pig.react(Reaction.yawn);
      _sfx.play(Sfx.yawn);
      return;
    }
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const AppleCatchScreen()));
    if (mounted) _pig.react(Reaction.happy);
  }

  void _toggleSleep() {
    if (_state.asleep) {
      _pet.wake();
      _sfx.play(Sfx.wake);
      _pig.react(Reaction.happy);
      _say(context.l10n.sayMorning);
    } else {
      _pet.sleep();
      _sfx.play(Sfx.yawn, pitch: _pitch);
      _pig.react(Reaction.yawn);
      setState(() => _mode = _Mode.normal);
    }
  }

  void _sayAsleep() {
    _pig.react(Reaction.grumble);
    _say(context.l10n.sleepingHint(_state.name));
  }

  Future<void> _openCloset() async {
    _sfx.play(Sfx.pop);
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const ClosetScreen()));
  }

  Future<void> _openSettings() async {
    _sfx.play(Sfx.pop);
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const SettingsScreen()));
  }

  // ---------------------------------------------------------------- dialogs
  Future<void> _claimGift() async {
    final l = context.l10n;
    final streak = _pet.nextGiftStreak;
    final amount = _pet.claimGift();
    if (amount == 0) return;
    _sfx.play(Sfx.gift);
    _pig.react(Reaction.happy);
    await _guardedDialog(
      () => showDialog<void>(
        context: context,
        builder: (ctx) => _CelebrationDialog(
          icon: const ArtIconView(ArtIcon.gift, size: 72),
          title: l.giftTitle,
          body: l.giftBody(streak, amount),
          footer: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AcornIcon(size: 26),
              const SizedBox(width: 6),
              Text(
                '+$amount',
                style: const TextStyle(fontFamily: 'Fredoka', fontSize: 24, fontWeight: FontWeight.w600, color: AppColors.acorn),
              ),
            ],
          ),
          cta: l.giftClaim,
        ),
      ),
    );
    _sfx.play(Sfx.acorn);
  }

  Future<void> _showLevelUp(int level, bool grew) async {
    final l = context.l10n;
    final name = _state.name;
    final body = !grew ? l.levelUpBody(name) : (_state.stage == Stage.big ? l.grewUpBig(name) : l.grewUpLittle(name));
    await _guardedDialog(
      () => showDialog<void>(
        context: context,
        builder: (ctx) =>
            _CelebrationDialog(icon: const ArtIconView(ArtIcon.star, size: 72), title: l.levelUpTitle(level), body: body, cta: l.ok),
      ),
    );
  }

  Future<void> _guardedDialog(Future<void> Function() show) async {
    if (_dialogOpen) return;
    _dialogOpen = true;
    try {
      await show();
    } finally {
      _dialogOpen = false;
    }
  }

  Future<void> _maybeAskReview() async {
    if (!_pet.shouldAskReview || skipDeviceOnlyWork) return;
    _pet.markReviewAsked();
    try {
      final r = InAppReview.instance;
      if (await r.isAvailable()) await r.requestReview();
    } catch (_) {}
  }

  Future<void> _maybeShowUpdateOrAnnouncement() async {
    final remote = _s.remote;
    final l = context.l10n;
    final cfg = remote.value;
    if (remote.updateRequired && cfg.updateUrlIos.isNotEmpty) {
      await _guardedDialog(
        () => showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(l.updateTitle),
            content: Text(l.updateBody),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.later)),
              FilledButton(
                onPressed: () {
                  launchUrl(Uri.parse(cfg.updateUrlIos), mode: LaunchMode.externalApplication);
                  Navigator.pop(ctx);
                },
                child: Text(l.updateCta),
              ),
            ],
          ),
        ),
      );
      return;
    }
    final ann = cfg.announcement;
    if (ann == null) return;
    try {
      final p = await SharedPreferences.getInstance();
      const key = 'seenAnnouncement';
      if (p.getString(key) == ann.id) return;
      if (!mounted) return;
      final lang = Localizations.localeOf(context).languageCode;
      await _guardedDialog(
        () => showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(ann.title.resolve(lang)),
            content: Text(ann.body.resolve(lang)),
            actions: [
              if (ann.url.isNotEmpty)
                TextButton(
                  onPressed: () => launchUrl(Uri.parse(ann.url), mode: LaunchMode.externalApplication),
                  child: Text(l.learnMore),
                ),
              FilledButton(onPressed: () => Navigator.pop(ctx), child: Text(l.ok)),
            ],
          ),
        ),
      );
      await p.setString(key, ann.id);
    } catch (_) {}
  }

  // ------------------------------------------------------------------ build
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(listenable: Listenable.merge([_pet, _s.remote]), builder: (context, _) => _build(context));
  }

  Widget _build(BuildContext context) {
    final l = context.l10n;
    final st = _state;
    final mq = MediaQuery.of(context);
    final asleep = st.asleep;
    const topH = 64.0, metersH = 78.0, dockH = 128.0;
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, box) {
          final h = box.maxHeight;
          final bottom = dockH + mq.padding.bottom;
          final pigTop = mq.padding.top + topH + metersH;
          final pigH = math.max(120.0, h - pigTop - bottom);
          final floorY = ((h - bottom - pigH * 0.13) / h).clamp(0.3, 0.95);
          return Stack(
            children: [
              Positioned.fill(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(end: asleep ? 1 : 0),
                  duration: const Duration(milliseconds: 900),
                  builder: (context, night, _) => CustomPaint(
                    painter: RoomPainter(st.room, night: night, floorY: floorY),
                  ),
                ),
              ),
              // Pig area
              Positioned(left: 0, right: 0, top: pigTop, height: pigH, child: _pigArea(l, st, asleep)),
              if (asleep)
                Positioned(
                  right: 20,
                  top: pigTop + 4,
                  child: Semantics(
                    button: true,
                    label: l.wakeMoon,
                    excludeSemantics: true,
                    child: GestureDetector(
                      key: const ValueKey('moon'),
                      behavior: HitTestBehavior.opaque,
                      onTap: _toggleSleep,
                      child: const Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(Icons.nightlight_round, size: 44, color: Color(0xFFFFF3B0)),
                      ),
                    ),
                  ),
                ),
              // Top bar + meters
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    children: [
                      SizedBox(height: topH, child: _topBar(l, st)),
                      SizedBox(height: metersH, child: _meters(l, st)),
                    ],
                  ),
                ),
              ),
              // Dock / trays
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  transitionBuilder: (c, a) => SlideTransition(
                    position: Tween(
                      begin: const Offset(0, 0.4),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
                    child: FadeTransition(opacity: a, child: c),
                  ),
                  child: switch (_mode) {
                    _Mode.feed => _FeedTray(
                      key: const ValueKey('feed'),
                      pet: _pet,
                      height: bottom,
                      onClose: _toggleFeed,
                      onDragging: (v) => _pig.anticipating = v,
                    ),
                    _Mode.bath => _BathBar(
                      key: const ValueKey('bath'),
                      height: bottom,
                      clean: st.needs.clean,
                      busy: _rinsing,
                      onRinse: _rinse,
                      onClose: () => setState(() {
                        _mode = _Mode.normal;
                        _sponge = null;
                      }),
                    ),
                    _Mode.normal => _dock(l, st, bottom),
                  },
                ),
              ),
              if (DebugFlags.showInspector)
                Positioned(
                  left: 8,
                  bottom: bottom + 4,
                  child: IgnorePointer(
                    child: Text(
                      '${st.needs}\nlv ${st.level} xp ${st.xp} · ${DebugFlags.summary}',
                      style: const TextStyle(fontSize: 10, color: Colors.black54),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _pigArea(AppLocalizations l, PetState st, bool asleep) {
    final pigView = PigView(
      key: _pigKey,
      controller: _pig,
      stage: st.stage,
      needs: st.needs,
      mode: asleep ? PigMode.asleep : (_mode == _Mode.bath ? PigMode.bath : PigMode.normal),
      hat: st.equipped[Slot.hat],
      glasses: st.equipped[Slot.glasses],
      neck: st.equipped[Slot.neck],
      onZone: _onZone,
      onRub: _onRub,
      onScrub: _onScrub,
      animate: !isRunningUnderTest,
    );
    return Stack(
      children: [
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 46, 24, 0),
            child: _mode == _Mode.bath
                ? Listener(
                    onPointerDown: (e) => setState(() => _sponge = e.localPosition),
                    onPointerMove: (e) => setState(() => _sponge = e.localPosition),
                    onPointerUp: (_) => setState(() => _sponge = null),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned.fill(child: pigView),
                        if (_sponge != null)
                          Positioned(
                            left: _sponge!.dx - 26,
                            top: _sponge!.dy - 26,
                            child: const IgnorePointer(child: ArtIconView(ArtIcon.sponge, size: 58)),
                          ),
                      ],
                    ),
                  )
                : DragTarget<Food>(
                    onWillAcceptWithDetails: (_) {
                      _pig.anticipating = true;
                      return true;
                    },
                    onLeave: (_) => _pig.anticipating = false,
                    onAcceptWithDetails: (d) => _onFood(d.data),
                    builder: (context, _, _) => pigView,
                  ),
          ),
        ),
        // Speech bubble sits just above the pig's ears, wherever the pig is.
        Positioned.fill(
          child: LayoutBuilder(
            builder: (context, box) {
              final geo = PigGeometry.forStage(st.stage);
              final w = box.maxWidth - 48, h = box.maxHeight - 46;
              final scale = math.min(w / PigGeometry.designSize.width, h / PigGeometry.designSize.height);
              final pigTop = 46 + (h - PigGeometry.designSize.height * scale);
              final earTop = pigTop + (geo.headC.dy - geo.headR * 1.5) * scale;
              return Stack(
                children: [
                  Positioned(
                    top: math.max(0, earTop - 62),
                    left: 0,
                    right: asleep ? 76 : 0, // keep clear of the wake moon
                    child: Center(
                      child: IgnorePointer(child: SpeechBubble(text: _bubble)),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        if (_pet.giftAvailable && !asleep && _mode == _Mode.normal)
          Positioned(
            right: 16,
            top: 52,
            child: _GiftButton(tooltip: l.giftTooltip, onTap: _claimGift),
          ),
      ],
    );
  }

  Widget _topBar(AppLocalizations l, PetState st) {
    final need = Economy.xpForNext(st.level);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Flexible(
            child: GestureDetector(
              onTap: () {
                _sfx.play(Sfx.pop);
                showStatsSheet(context);
              },
              child: Container(
                padding: const EdgeInsets.fromLTRB(6, 6, 16, 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: const [BoxShadow(color: Color(0x1A8A3A5A), blurRadius: 10, offset: Offset(0, 3))],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox.square(
                      dimension: 40,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          TweenAnimationBuilder<double>(
                            tween: Tween(end: st.xp / need),
                            duration: const Duration(milliseconds: 600),
                            builder: (context, v, _) => CircularProgressIndicator(
                              value: v.clamp(0.0, 1.0),
                              strokeWidth: 4,
                              backgroundColor: AppColors.pinkSoft,
                              color: AppColors.pink,
                            ),
                          ),
                          Text(
                            '${st.level}',
                            style: const TextStyle(
                              fontFamily: 'Fredoka',
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: AppColors.pinkDeep,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            st.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.w600, fontSize: 17, color: AppColors.ink),
                          ),
                          Text(
                            stageName(l, st.stage),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.inkSoft),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          AcornBadge(count: st.acorns, onTap: _openCloset),
          const SizedBox(width: 6),
          IconButton(
            tooltip: l.settingsTitle,
            onPressed: _openSettings,
            style: IconButton.styleFrom(backgroundColor: Colors.white),
            icon: const Icon(Icons.settings_rounded, color: AppColors.inkSoft),
          ),
        ],
      ),
    );
  }

  Widget _meters(AppLocalizations l, PetState st) {
    final labels = {Need.tummy: l.needTummy, Need.clean: l.needClean, Need.fun: l.needFun, Need.energy: l.needEnergy};
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [for (final n in Need.values) NeedMeter(need: n, value: st.needs[n], label: labels[n]!)],
      ),
    );
  }

  Widget _dock(AppLocalizations l, PetState st, double height) {
    final asleep = st.asleep;
    final urgent = st.needs.mostUrgent;
    return Container(
      key: const ValueKey('dock'),
      height: height,
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom, left: 8, right: 8, top: 10),
      decoration: const BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [BoxShadow(color: Color(0x228A3A5A), blurRadius: 18, offset: Offset(0, -4))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          for (final b in <Widget>[
            DockButton(
              icon: Icons.restaurant_rounded,
              label: l.actFeed,
              color: AppColors.tummy,
              onTap: _toggleFeed,
              enabled: !asleep,
              highlight: urgent == Need.tummy && !asleep,
            ),
            DockButton(
              icon: Icons.bubble_chart_rounded,
              label: l.actBath,
              color: AppColors.clean,
              onTap: _toggleBath,
              enabled: !asleep,
              highlight: urgent == Need.clean && !asleep,
            ),
            if (_s.remote.value.miniGameEnabled)
              DockButton(
                icon: Icons.sports_esports_rounded,
                label: l.actPlay,
                color: AppColors.fun,
                onTap: _play,
                enabled: !asleep,
                highlight: urgent == Need.fun && !asleep,
              ),
            DockButton(
              icon: asleep ? Icons.wb_sunny_rounded : Icons.bedtime_rounded,
              label: asleep ? l.actWake : l.actSleep,
              color: AppColors.energy,
              onTap: _toggleSleep,
              highlight: (urgent == Need.energy || (_isNight && st.needs.energy < 70)) && !asleep,
            ),
            DockButton(icon: Icons.checkroom_rounded, label: l.actCloset, color: AppColors.pink, onTap: _openCloset),
          ])
            Expanded(child: Center(child: b)),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------ trays
class _FeedTray extends StatelessWidget {
  const _FeedTray({super.key, required this.pet, required this.height, required this.onClose, required this.onDragging});
  final PetController pet;
  final double height;
  final VoidCallback onClose;
  final ValueChanged<bool> onDragging;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final now = pet.clock();
    final foods = Catalog.foods.where((f) => f.seasonal == null || pet.config.seasonActive(f.seasonal, now)).toList();
    return Container(
      height: height,
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom, top: 8),
      decoration: const BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [BoxShadow(color: Color(0x228A3A5A), blurRadius: 18, offset: Offset(0, -4))],
      ),
      child: Row(
        children: [
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              itemCount: foods.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                final f = foods[i];
                final unlocked = pet.isUnlocked(f);
                final tile = _FoodTile(food: f, label: foodName(l, f.id), locked: !unlocked, lockLabel: l.unlockLevel(f.minLevel));
                if (!unlocked) return tile;
                return Draggable<Food>(
                  data: f,
                  onDragStarted: () => onDragging(false),
                  onDragEnd: (_) => onDragging(false),
                  feedback: ArtIconView(artIconForFood(f.id), size: 64),
                  childWhenDragging: Opacity(opacity: 0.35, child: tile),
                  child: tile,
                );
              },
            ),
          ),
          IconButton(
            tooltip: l.close,
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded, color: AppColors.inkSoft, size: 28),
          ),
          const SizedBox(width: 6),
        ],
      ),
    );
  }
}

class _FoodTile extends StatelessWidget {
  const _FoodTile({required this.food, required this.label, required this.locked, required this.lockLabel});
  final Food food;
  final String label;
  final bool locked;
  final String lockLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      child: Container(
        width: 74,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [BoxShadow(color: Color(0x148A3A5A), blurRadius: 8, offset: Offset(0, 3))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Opacity(opacity: locked ? 0.35 : 1, child: ArtIconView(artIconForFood(food.id), size: 46)),
            const SizedBox(height: 2),
            locked
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.lock_rounded, size: 13, color: AppColors.inkSoft),
                      Text(
                        lockLabel,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.inkSoft),
                      ),
                    ],
                  )
                : Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.ink),
                  ),
          ],
        ),
      ),
    );
  }
}

class _BathBar extends StatelessWidget {
  const _BathBar({super.key, required this.height, required this.clean, required this.busy, required this.onRinse, required this.onClose});
  final double height;
  final double clean;
  final bool busy;
  final VoidCallback onRinse;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Container(
      height: height,
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 8, left: 20, right: 6, top: 12),
      decoration: const BoxDecoration(
        color: Color(0xFFE6F6FF),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [BoxShadow(color: Color(0x2238789A), blurRadius: 18, offset: Offset(0, -4))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                  child: Text(
                    l.bathHint,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.ink),
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(end: clean / 100),
                    duration: const Duration(milliseconds: 250),
                    builder: (context, v, _) =>
                        LinearProgressIndicator(value: v, minHeight: 12, backgroundColor: Colors.white, color: AppColors.clean),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          FilledButton.icon(
            onPressed: busy ? null : onRinse,
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF3DA9E8)),
            icon: const Icon(Icons.shower_rounded),
            label: Text(l.bathRinse),
          ),
          IconButton(
            tooltip: l.close,
            onPressed: busy ? null : onClose,
            icon: const Icon(Icons.close_rounded, color: AppColors.inkSoft, size: 26),
          ),
        ],
      ),
    );
  }
}

class _GiftButton extends StatefulWidget {
  const _GiftButton({required this.tooltip, required this.onTap});
  final String tooltip;
  final VoidCallback onTap;

  @override
  State<_GiftButton> createState() => _GiftButtonState();
}

class _GiftButtonState extends State<_GiftButton> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));

  @override
  void initState() {
    super.initState();
    if (!isRunningUnderTest) _c.repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: Semantics(
        button: true,
        label: widget.tooltip,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, child) {
              final t = _c.value;
              final wobble = t < 0.3 ? math.sin(t / 0.3 * math.pi * 3) * 0.18 : 0.0;
              return Transform.rotate(angle: wobble, child: child);
            },
            child: Container(
              width: 62,
              height: 62,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.sun, width: 3),
                boxShadow: const [BoxShadow(color: Color(0x40FFB300), blurRadius: 14, offset: Offset(0, 4))],
              ),
              child: const ArtIconView(ArtIcon.gift, size: 40),
            ),
          ),
        ),
      ),
    );
  }
}

class _CelebrationDialog extends StatelessWidget {
  const _CelebrationDialog({required this.icon, required this.title, required this.body, required this.cta, this.footer});
  final Widget icon;
  final String title;
  final String body;
  final String cta;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 26, 24, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            const SizedBox(height: 8),
            Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(body, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge),
            if (footer != null) ...[const SizedBox(height: 14), footer!],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(onPressed: () => Navigator.pop(context), child: Text(cta)),
            ),
          ],
        ),
      ),
    );
  }
}
