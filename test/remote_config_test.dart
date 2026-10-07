import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oink_pet/core/remote_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// One test per config section (CLAUDE.md rule 6). The published file in
/// `config/config.json` must parse to exactly the code defaults, so pushing
/// it can never change behaviour by accident.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('the published config parses and matches the code defaults', () {
    final j = jsonDecode(File('config/config.json').readAsStringSync()) as Map<String, dynamic>;
    final c = RemoteConfig.fromJson(j);
    const d = RemoteConfig.defaults;
    expect(c.miniGameEnabled, d.miniGameEnabled);
    expect(c.dailyGiftEnabled, d.dailyGiftEnabled);
    expect(c.seasonalEnabled, d.seasonalEnabled);
    expect(c.drainMultiplier, d.drainMultiplier);
    expect(c.restMultiplier, d.restMultiplier);
    expect(c.dailyGiftBase, d.dailyGiftBase);
    expect(c.priceMultiplier, d.priceMultiplier);
    expect(c.reviewMinDays, d.reviewMinDays);
    expect(c.reviewMinLevel, d.reviewMinLevel);
    expect(c.privacyUrl, d.privacyUrl);
    expect(c.supportUrl, d.supportUrl);
    expect(c.supportEmail, d.supportEmail);
    expect(c.minSupportedVersion, d.minSupportedVersion);
    expect(c.latestVersion, d.latestVersion);
    expect(c.updateUrlIos, d.updateUrlIos);
    expect(c.reviewPromptEnabled, d.reviewPromptEnabled);
    expect(c.announcement, isNull, reason: 'disabled announcement must not show');
    expect(c.adsEnabled, isFalse);
    for (final id in ['halloween', 'winter']) {
      expect(c.seasons[id]!.from, d.seasons[id]!.from);
      expect(c.seasons[id]!.to, d.seasons[id]!.to);
    }
  });

  test('junk values fall back to defaults and numbers are clamped', () {
    final c = RemoteConfig.fromJson({
      'features': {'miniGame': 'yes', 'dailyGift': false},
      'economy': {'drainMultiplier': 99, 'restMultiplier': -1, 'dailyGiftBase': 'x', 'priceMultiplier': double.nan},
      'reviewPrompt': {'minDays': 1000},
      'seasonal': {
        'halloween': {'from': '13-40', 'to': 'oops'},
        'spring': {'enabled': true, 'from': '03-20', 'to': '04-10'},
        'broken': 'nope',
      },
      'announcement': {'enabled': true, 'id': '', 'title': 'x'},
      'ads': {'enabled': true},
    });
    expect(c.miniGameEnabled, isTrue);
    expect(c.dailyGiftEnabled, isFalse);
    expect(c.drainMultiplier, 3);
    expect(c.restMultiplier, 0.2);
    expect(c.dailyGiftBase, 5);
    expect(c.priceMultiplier, 1);
    expect(c.reviewMinDays, 60);
    expect(c.seasons['halloween']!.from, 1001, reason: 'invalid dates keep the built-in window');
    expect(c.seasons['spring']!.contains(DateTime(2027, 4, 1)), isTrue);
    expect(c.seasons.containsKey('broken'), isFalse);
    expect(c.announcement, isNull, reason: 'an announcement needs an id');
    expect(c.adsEnabled, isTrue, reason: 'read but never acted on in v1');
  });

  test('season windows, including one that wraps the new year', () {
    const c = RemoteConfig.defaults;
    expect(c.seasonActive('halloween', DateTime(2026, 10, 15)), isTrue);
    expect(c.seasonActive('halloween', DateTime(2026, 11, 8)), isFalse);
    expect(c.seasonActive('winter', DateTime(2026, 12, 24)), isTrue);
    expect(c.seasonActive('winter', DateTime(2027, 1, 5)), isTrue);
    expect(c.seasonActive('winter', DateTime(2027, 1, 11)), isFalse);
    expect(c.seasonActive(null, DateTime(2026)), isTrue, reason: 'non-seasonal items are always available');
    expect(c.seasonActive('unknown', DateTime(2026, 10, 15)), isFalse);
    const off = RemoteConfig(seasonalEnabled: false);
    expect(off.seasonActive('halloween', DateTime(2026, 10, 15)), isFalse);
  });

  test('announcement resolves the best language', () {
    final c = RemoteConfig.fromJson({
      'announcement': {
        'enabled': true,
        'id': 'hello-1',
        'title': {'en': 'Hi', 'fr': 'Salut'},
        'body': 'Body',
      },
    });
    expect(c.announcement!.title.resolve('fr'), 'Salut');
    expect(c.announcement!.title.resolve('de'), 'Hi');
    expect(c.announcement!.body.resolve('ja'), 'Body');
  });

  test('version compare', () {
    expect(compareVersions('1.2.10', '1.2.9'), greaterThan(0));
    expect(compareVersions('1.0.0', '1.0.0+5'), 0);
    expect(compareVersions('1.0', '1.0.1'), lessThan(0));
  });

  test('first launch with no cache and no network runs on the code defaults', () async {
    SharedPreferences.setMockInitialValues({});
    final s = RemoteConfigService();
    await s.init();
    await s.refresh(); // the test binding answers every HTTP request with 400
    expect(s.value.miniGameEnabled, RemoteConfig.defaults.miniGameEnabled);
    expect(s.value.dailyGiftBase, RemoteConfig.defaults.dailyGiftBase);
    expect(s.value.adsEnabled, isFalse);
  });
}
