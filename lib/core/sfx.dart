import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

import 'test_env.dart';

/// Every sound in the app. File names match `assets/audio/<name>.mp3`
/// (produced by tools/audio/synth.py).
enum Sfx {
  oink,
  snort,
  giggle,
  squealHappy,
  whimper,
  yawn,
  snore,
  munch,
  gulp,
  bubbles,
  scrub,
  shower,
  sparkle,
  pop,
  tap,
  acorn,
  catch_,
  bonk,
  levelup,
  gift,
  wake,
}

const _files = <Sfx, List<String>>{
  Sfx.oink: ['oink_1', 'oink_2', 'oink_3', 'oink_4', 'oink_5', 'oink_6'],
  Sfx.snort: ['snort_1', 'snort_2'],
  Sfx.giggle: ['giggle_1', 'giggle_2'],
  Sfx.squealHappy: ['squeal_happy'],
  Sfx.whimper: ['whimper'],
  Sfx.yawn: ['yawn'],
  Sfx.snore: ['snore'],
  Sfx.munch: ['munch_1', 'munch_2', 'munch_3'],
  Sfx.gulp: ['gulp'],
  Sfx.bubbles: ['bubbles'],
  Sfx.scrub: ['scrub'],
  Sfx.shower: ['shower'],
  Sfx.sparkle: ['sparkle'],
  Sfx.pop: ['pop'],
  Sfx.tap: ['tap'],
  Sfx.acorn: ['acorn'],
  Sfx.catch_: ['catch'],
  Sfx.bonk: ['bonk'],
  Sfx.levelup: ['levelup'],
  Sfx.gift: ['gift'],
  Sfx.wake: ['wake'],
};

/// Fire-and-forget sound + haptics.
///
/// Every method is safe before [init] finishes, under `flutter test`, and on a
/// device with no audio output: it silently does nothing. A pet app must
/// never crash or stall because a sound failed to load.
class SfxPlayer {
  SfxPlayer();

  final _rng = math.Random();
  final Map<String, AudioSource> _sources = {};
  final Map<Sfx, int> _lastIndex = {};
  final Map<Sfx, DateTime> _lastPlayed = {};
  bool _ready = false;
  Future<void>? _initFuture;

  bool soundOn = true;
  bool hapticsOn = true;

  /// Exposed for tests and the debug inspector.
  final List<Sfx> log = [];

  SoLoud get _soloud => SoLoud.instance;

  Future<void> init() => _initFuture ??= _init();

  Future<void> _init() async {
    if (skipDeviceOnlyWork) return;
    try {
      await _configureSession();
      if (!_soloud.isInitialized) await _soloud.init(bufferSize: 1024);
      // flutter_soloud 5 stops the output device after 500 ms of silence; keep
      // it running (4.x behaviour) so a tap's sound has no restart latency.
      _soloud.setAudioDeviceIdleTimeout(null);
      for (final names in _files.values) {
        for (final n in names) {
          try {
            _sources[n] = await _soloud.loadAsset('assets/audio/$n.mp3');
          } catch (e) {
            debugPrint('sfx: could not load $n: $e');
          }
        }
      }
      _ready = true;
    } catch (e) {
      debugPrint('sfx init failed: $e');
    }
  }

  /// Ambient: respects the silent switch and mixes with the user's music —
  /// a pet app must never stop someone's podcast.
  Future<void> _configureSession() async {
    try {
      final s = await AudioSession.instance;
      await s.configure(const AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.ambient,
        avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.mixWithOthers,
        avAudioSessionMode: AVAudioSessionMode.defaultMode,
        androidAudioAttributes: AndroidAudioAttributes(
          contentType: AndroidAudioContentType.sonification,
          usage: AndroidAudioUsage.game,
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gainTransientMayDuck,
      ));
      if (Platform.isIOS) await s.setActive(true);
    } catch (e) {
      debugPrint('audio session: $e');
    }
  }

  /// Plays a variant of [sfx]. [pitch] 1 = as recorded; variants are picked
  /// so the same one never repeats twice in a row. [minGap] throttles rapid
  /// repeats (rubbing fires dozens of events per second).
  void play(Sfx sfx, {double volume = 1, double pitch = 1, Duration minGap = Duration.zero}) {
    final now = DateTime.now();
    final last = _lastPlayed[sfx];
    if (minGap > Duration.zero && last != null && now.difference(last) < minGap) return;
    _lastPlayed[sfx] = now;
    log.add(sfx);
    if (log.length > 200) log.removeRange(0, 100);
    if (!soundOn || !_ready) return;
    final names = _files[sfx]!;
    var i = names.length == 1 ? 0 : _rng.nextInt(names.length);
    if (names.length > 1 && i == _lastIndex[sfx]) i = (i + 1) % names.length;
    _lastIndex[sfx] = i;
    final src = _sources[names[i]];
    if (src == null) return;
    unawaited(() async {
      try {
        final h = _soloud.play(src, volume: volume.clamp(0.0, 1.0));
        if (pitch != 1) _soloud.setRelativePlaySpeed(h, pitch.clamp(0.5, 2.0));
      } catch (_) {}
    }());
  }

  void tick() {
    if (hapticsOn && !skipDeviceOnlyWork) HapticFeedback.selectionClick();
  }

  void bump() {
    if (hapticsOn && !skipDeviceOnlyWork) HapticFeedback.lightImpact();
  }

  void thump() {
    if (hapticsOn && !skipDeviceOnlyWork) HapticFeedback.mediumImpact();
  }
}
