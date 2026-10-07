import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_env.dart';

/// Where the live config lives: a public, JSON-only GitHub repo shared by the
/// owner's apps. Contains no secrets by design — anyone can read it.
const kRemoteConfigUrl = 'https://raw.githubusercontent.com/OuadieZerhouni/app-configs/main/oink-pet/config.json';

/// A localized string map: {"en": "...", "fr": "..."} → best match.
class LocalizedText {
  const LocalizedText(this.values);
  final Map<String, String> values;

  String resolve(String languageCode) => values[languageCode] ?? values['en'] ?? values.values.firstOrNull ?? '';

  bool get isEmpty => values.values.every((v) => v.trim().isEmpty);

  factory LocalizedText.fromJson(Object? j) {
    if (j is String) return LocalizedText({'en': j});
    if (j is Map) return LocalizedText(j.map((k, v) => MapEntry('$k', '$v')));
    return const LocalizedText({});
  }
}

@immutable
class Announcement {
  const Announcement({required this.id, required this.title, required this.body, this.url = ''});
  final String id;
  final LocalizedText title;
  final LocalizedText body;
  final String url;
}

/// A yearly window "MM-DD".."MM-DD" (may wrap the new year) during which
/// seasonal foods and outfits are available.
@immutable
class SeasonWindow {
  const SeasonWindow({required this.enabled, required this.from, required this.to});

  final bool enabled;

  /// Month*100 + day, e.g. 1001 for Oct 1.
  final int from;
  final int to;

  bool contains(DateTime d) {
    if (!enabled) return false;
    final md = d.month * 100 + d.day;
    return from <= to ? (md >= from && md <= to) : (md >= from || md <= to);
  }

  static int? parseMd(Object? v) {
    if (v is! String) return null;
    final m = RegExp(r'^(\d{2})-(\d{2})$').firstMatch(v);
    if (m == null) return null;
    final month = int.parse(m.group(1)!), day = int.parse(m.group(2)!);
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;
    return month * 100 + day;
  }
}

/// Everything the app can be tuned with remotely.
///
/// Rules (see docs/REMOTE_CONFIG.md): config tunes behaviour, it never invents
/// it; every key has a safe code default; malformed values fall back rather
/// than crash. The very first launch has no fetched config at all, so
/// [RemoteConfig.defaults] must be a complete, shippable app on its own.
@immutable
class RemoteConfig {
  const RemoteConfig({
    this.schemaVersion = 1,
    this.minSupportedVersion = '1.0.0',
    this.latestVersion = '1.0.0',
    this.updateUrlIos = '',
    this.announcement,
    this.miniGameEnabled = true,
    this.dailyGiftEnabled = true,
    this.seasonalEnabled = true,
    this.drainMultiplier = 1.0,
    this.restMultiplier = 1.0,
    this.dailyGiftBase = 5,
    this.priceMultiplier = 1.0,
    this.seasons = defaultSeasons,
    this.reviewPromptEnabled = true,
    this.reviewMinDays = 3,
    this.reviewMinLevel = 3,
    this.adsEnabled = false,
    this.privacyUrl = 'https://github.com/OuadieZerhouni/app-configs/blob/main/oink-pet/PRIVACY.md',
    this.supportUrl = 'https://github.com/OuadieZerhouni/app-configs/blob/main/oink-pet/SUPPORT.md',
    this.supportEmail = '',
  });

  static const defaults = RemoteConfig();

  static const defaultSeasons = <String, SeasonWindow>{
    'halloween': SeasonWindow(enabled: true, from: 1001, to: 1107),
    'winter': SeasonWindow(enabled: true, from: 1201, to: 110),
  };

  final int schemaVersion;
  final String minSupportedVersion;
  final String latestVersion;
  final String updateUrlIos;
  final Announcement? announcement;

  /// Kill switches.
  final bool miniGameEnabled;
  final bool dailyGiftEnabled;
  final bool seasonalEnabled;

  /// Balance knobs (clamped to sane ranges).
  final double drainMultiplier;
  final double restMultiplier;
  final int dailyGiftBase;
  final double priceMultiplier;

  final Map<String, SeasonWindow> seasons;

  final bool reviewPromptEnabled;
  final int reviewMinDays;
  final int reviewMinLevel;

  /// Reserved: v1 ships with no ad code at all, so this can only ever be read,
  /// never acted on. Present so the schema is stable when ads arrive.
  final bool adsEnabled;

  final String privacyUrl;
  final String supportUrl;
  final String supportEmail;

  /// Whether a seasonal id is available today. Unknown ids are never active.
  bool seasonActive(String? id, DateTime now) {
    if (id == null) return true;
    if (!seasonalEnabled) return false;
    return seasons[id]?.contains(now) ?? false;
  }

  /// Acorn price after the remote multiplier (never below 1 for paid items).
  int price(int base) => base <= 0 ? 0 : (base * priceMultiplier).round().clamp(1, 9999);

  factory RemoteConfig.fromJson(Map<String, dynamic> j) {
    const d = RemoteConfig.defaults;
    T pick<T>(Object? v, T fallback) => v is T ? v : fallback;
    double num_(Object? v, double fallback, double lo, double hi) =>
        v is num && v.isFinite ? v.toDouble().clamp(lo, hi) : fallback;
    int int_(Object? v, int fallback, int lo, int hi) => v is num && v.isFinite ? v.round().clamp(lo, hi) : fallback;

    final features = pick<Map<String, dynamic>>(j['features'], const {});
    final economy = pick<Map<String, dynamic>>(j['economy'], const {});
    final review = pick<Map<String, dynamic>>(j['reviewPrompt'], const {});
    final links = pick<Map<String, dynamic>>(j['links'], const {});
    final ads = pick<Map<String, dynamic>>(j['ads'], const {});

    Announcement? ann;
    final a = j['announcement'];
    if (a is Map<String, dynamic> && a['enabled'] == true && (a['id'] ?? '').toString().isNotEmpty) {
      final title = LocalizedText.fromJson(a['title']);
      final body = LocalizedText.fromJson(a['body']);
      if (!title.isEmpty || !body.isEmpty) {
        ann = Announcement(id: a['id'].toString(), title: title, body: body, url: (a['url'] ?? '').toString());
      }
    }

    final seasons = Map<String, SeasonWindow>.of(defaultSeasons);
    final s = j['seasonal'];
    if (s is Map) {
      s.forEach((k, v) {
        if (k is! String || v is! Map) return;
        final base = seasons[k];
        final from = SeasonWindow.parseMd(v['from']) ?? base?.from;
        final to = SeasonWindow.parseMd(v['to']) ?? base?.to;
        if (from == null || to == null) return;
        seasons[k] = SeasonWindow(enabled: v['enabled'] is bool ? v['enabled'] as bool : (base?.enabled ?? true), from: from, to: to);
      });
    }

    return RemoteConfig(
      schemaVersion: pick<int>(j['schemaVersion'], d.schemaVersion),
      minSupportedVersion: pick<String>(j['minSupportedVersion'], d.minSupportedVersion),
      latestVersion: pick<String>(j['latestVersion'], d.latestVersion),
      updateUrlIos: pick<String>(j['updateUrlIos'], d.updateUrlIos),
      announcement: ann,
      miniGameEnabled: pick<bool>(features['miniGame'], d.miniGameEnabled),
      dailyGiftEnabled: pick<bool>(features['dailyGift'], d.dailyGiftEnabled),
      seasonalEnabled: pick<bool>(features['seasonalItems'], d.seasonalEnabled),
      drainMultiplier: num_(economy['drainMultiplier'], d.drainMultiplier, 0.2, 3),
      restMultiplier: num_(economy['restMultiplier'], d.restMultiplier, 0.2, 3),
      dailyGiftBase: int_(economy['dailyGiftBase'], d.dailyGiftBase, 1, 50),
      priceMultiplier: num_(economy['priceMultiplier'], d.priceMultiplier, 0.25, 4),
      seasons: seasons,
      reviewPromptEnabled: pick<bool>(review['enabled'], d.reviewPromptEnabled),
      reviewMinDays: int_(review['minDays'], d.reviewMinDays, 1, 60),
      reviewMinLevel: int_(review['minLevel'], d.reviewMinLevel, 1, 50),
      adsEnabled: pick<bool>(ads['enabled'], false),
      privacyUrl: pick<String>(links['privacyPolicy'], d.privacyUrl),
      supportUrl: pick<String>(links['support'], d.supportUrl),
      supportEmail: pick<String>(links['supportEmail'], d.supportEmail),
    );
  }
}

/// Fetches, caches and exposes [RemoteConfig].
///
/// Startup never waits on the network: the cached copy (or the code defaults)
/// is available synchronously, and a fresh fetch replaces it when it lands.
/// The whole app works offline.
class RemoteConfigService extends ValueNotifier<RemoteConfig> {
  RemoteConfigService() : super(RemoteConfig.defaults);

  static const _cacheKey = 'remoteConfigCache';
  String appVersion = '1.0.0';

  Future<void> init() async {
    try {
      appVersion = (await PackageInfo.fromPlatform()).version;
    } catch (_) {}
    try {
      final p = await SharedPreferences.getInstance();
      final cached = p.getString(_cacheKey);
      if (cached != null) {
        final j = jsonDecode(cached);
        if (j is Map<String, dynamic>) value = RemoteConfig.fromJson(j);
      }
    } catch (_) {}
    if (!skipDeviceOnlyWork) unawaited(refresh());
  }

  Future<void> refresh() async {
    try {
      final res = await http
          .get(Uri.parse('$kRemoteConfigUrl?t=${DateTime.now().millisecondsSinceEpoch ~/ 600000}'))
          .timeout(const Duration(seconds: 6));
      if (res.statusCode != 200) return;
      final body = utf8.decode(res.bodyBytes);
      final j = jsonDecode(body);
      if (j is! Map<String, dynamic>) return;
      value = RemoteConfig.fromJson(j);
      final p = await SharedPreferences.getInstance();
      await p.setString(_cacheKey, body);
    } catch (e) {
      debugPrint('remote config fetch skipped: $e');
    }
  }

  /// True when the running build is older than the minimum supported one.
  bool get updateRequired => compareVersions(appVersion, value.minSupportedVersion) < 0;
  bool get updateAvailable => compareVersions(appVersion, value.latestVersion) < 0;
}

/// Semantic-ish version compare: "1.2.10" > "1.2.9". Non-numeric parts → 0.
int compareVersions(String a, String b) {
  List<int> parts(String v) => v.split(RegExp(r'[.+-]')).take(3).map((p) => int.tryParse(p) ?? 0).toList();
  final pa = parts(a), pb = parts(b);
  for (var i = 0; i < 3; i++) {
    final x = i < pa.length ? pa[i] : 0;
    final y = i < pb.length ? pb[i] : 0;
    if (x != y) return x.compareTo(y);
  }
  return 0;
}
