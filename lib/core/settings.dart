import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

@immutable
class AppSettings {
  const AppSettings({this.sound = true, this.haptics = true, this.languageCode});

  final bool sound;
  final bool haptics;

  /// null = follow the device language.
  final String? languageCode;

  AppSettings copyWith({bool? sound, bool? haptics, String? languageCode, bool clearLanguage = false}) => AppSettings(
    sound: sound ?? this.sound,
    haptics: haptics ?? this.haptics,
    languageCode: clearLanguage ? null : (languageCode ?? this.languageCode),
  );
}

/// User preferences, persisted individually (they are independent toggles,
/// unlike the pet which is one atomic blob).
class SettingsService extends ValueNotifier<AppSettings> {
  SettingsService() : super(const AppSettings());

  static const _kSound = 'set_sound', _kHaptics = 'set_haptics', _kLang = 'set_lang';

  Future<void> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      value = AppSettings(
        sound: p.getBool(_kSound) ?? true,
        haptics: p.getBool(_kHaptics) ?? true,
        languageCode: p.getString(_kLang),
      );
    } catch (_) {}
  }

  Future<void> update(AppSettings s) async {
    value = s;
    try {
      final p = await SharedPreferences.getInstance();
      await p.setBool(_kSound, s.sound);
      await p.setBool(_kHaptics, s.haptics);
      if (s.languageCode == null) {
        await p.remove(_kLang);
      } else {
        await p.setString(_kLang, s.languageCode!);
      }
    } catch (_) {}
  }
}
