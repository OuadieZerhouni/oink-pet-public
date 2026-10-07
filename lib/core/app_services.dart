import 'package:flutter/widgets.dart';

import '../pet/pet_controller.dart';
import '../pet/pet_state.dart';
import '../pet/pet_store.dart';
import 'debug_flags.dart';
import 'remote_config.dart';
import 'settings.dart';
import 'sfx.dart';

/// Everything the UI needs, created once at startup.
class AppServices {
  AppServices({required this.settings, required this.remote, required this.pet, required this.sfx}) {
    _applySettings();
    settings.addListener(_applySettings);
  }

  final SettingsService settings;
  final RemoteConfigService remote;
  final PetController pet;
  final SfxPlayer sfx;

  void _applySettings() {
    sfx.soundOn = settings.value.sound;
    sfx.hapticsOn = settings.value.haptics;
  }

  static Future<AppServices> create({DateTime Function()? clock}) async {
    final now = clock ?? DateTime.now;
    final settings = SettingsService();
    final remote = RemoteConfigService();
    final store = PetStore();
    await Future.wait([settings.load(), remote.init()]);
    if (DebugFlags.resetFirstRun) await store.clear();
    final saved = await store.load(now());
    final pet = PetController(
      initial: saved ?? PetState.fresh(now()),
      store: store,
      configSource: () => remote.value,
      clock: now,
    )..sync();
    final sfx = SfxPlayer();
    // Audio loads in the background; the first frame never waits for it.
    sfx.init();
    return AppServices(settings: settings, remote: remote, pet: pet, sfx: sfx);
  }
}

class AppScope extends InheritedWidget {
  const AppScope({super.key, required this.services, required super.child});
  final AppServices services;

  static AppServices of(BuildContext context) {
    final s = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(s != null, 'AppScope missing');
    return s!.services;
  }

  @override
  bool updateShouldNotify(AppScope old) => old.services != services;
}
