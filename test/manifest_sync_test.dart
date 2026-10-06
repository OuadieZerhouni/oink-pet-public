import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';

/// Fails when a fact that lives in `app.yaml` has drifted in a generated file.
///
/// The bug being prevented is not hypothetical. In OuO the App Group id is
/// typed by hand into four files (`Runner.entitlements`, the widget's
/// entitlements, the widget's Swift, the Dart sync service) with nothing
/// checking they agree — and the locale list is typed into three, where it
/// already disagrees: 21 `.arb` files against 10 declared locales, so eleven
/// translations can never be selected by the OS. Neither is a coding mistake;
/// both are what happens when a fact has no single home.
///
/// So: `app.yaml` is the home, generated files carry a DO-NOT-EDIT header, and
/// this test is the tripwire. It runs in CI, so a hand-edit is a red build
/// rather than a silent inconsistency discovered months later.
void main() {
  final manifestFile = File('app.yaml');

  test('the locale list agrees everywhere it appears', () {
    if (!manifestFile.existsSync()) {
      markTestSkipped('no app.yaml — running inside the factory template');
      return;
    }
    final manifest = loadYaml(manifestFile.readAsStringSync()) as Map;
    final locales = ((manifest['locales'] as Map?)?['supported'] as List?)
            ?.map((e) => '$e')
            .toList() ??
        ['en'];

    // 1. One .arb per locale.
    for (final loc in locales) {
      expect(File('lib/l10n/app_$loc.arb').existsSync(), isTrue,
          reason: 'app.yaml lists locale "$loc" but lib/l10n/app_$loc.arb is '
              'missing — run scaffold.py --regen l10n');
    }
    // 2. No .arb without a locale (the OuO failure, inverted).
    final arbs = Directory('lib/l10n')
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.arb'))
        .map((f) => RegExp(r'app_(.+)\.arb$').firstMatch(f.path)?.group(1))
        .whereType<String>();
    for (final arb in arbs) {
      expect(locales, contains(arb),
          reason: 'lib/l10n/app_$arb.arb exists but "$arb" is not in '
              'app.yaml locales.supported, so the OS can never select it');
    }
    // 3. l10n.yaml declares exactly the same set.
    final l10n = loadYaml(File('l10n.yaml').readAsStringSync()) as Map;
    final declared = (l10n['preferred-supported-locales'] as List)
        .map((e) => '$e')
        .toSet();
    expect(declared, equals(locales.toSet()),
        reason: 'l10n.yaml disagrees with app.yaml. This exact drift is live '
            'in OuO (10 declared, 21 shipped).');
    // 4. iOS CFBundleLocalizations declares the same set.
    final plist = File('ios/Runner/Info.plist').readAsStringSync();
    final block = RegExp(
      r'<key>CFBundleLocalizations</key>\s*<array>(.*?)</array>',
      dotAll: true,
    ).firstMatch(plist);
    expect(block, isNotNull,
        reason: 'ios/Runner/Info.plist has no CFBundleLocalizations');
    final inPlist = RegExp(r'<string>(.*?)</string>')
        .allMatches(block!.group(1)!)
        .map((m) => m.group(1)!)
        .toSet();
    expect(inPlist, equals(locales.toSet()),
        reason: 'Info.plist CFBundleLocalizations disagrees with app.yaml');
  });

  test('the App Group id agrees everywhere it appears', () {
    if (!manifestFile.existsSync()) {
      markTestSkipped('no app.yaml — running inside the factory template');
      return;
    }
    final manifest = loadYaml(manifestFile.readAsStringSync()) as Map;
    final features = (manifest['features'] as Map?) ?? {};
    if (features['widget'] != true) {
      markTestSkipped('features.widget is off — no App Group to check');
      return;
    }
    final bundle = (manifest['app'] as Map)['bundle_id'] as String;
    final explicit = (manifest['ios'] as Map?)?['app_group'] as String?;
    final group = (explicit != null && explicit.isNotEmpty)
        ? explicit
        : 'group.$bundle';

    // Every file that must agree. The point of listing them here is that
    // adding a fifth location without adding it to this list is itself the bug.
    for (final path in [
      'ios/Runner/Runner.entitlements',
      'lib/services/widget_sync_service.dart',
    ]) {
      final f = File(path);
      if (!f.existsSync()) continue;
      expect(f.readAsStringSync(), contains(group),
          reason: '$path does not contain the App Group "$group" from '
              'app.yaml — run scaffold.py --regen ios');
    }
  });

  test('generated files still carry their DO-NOT-EDIT header', () {
    for (final path in ['l10n.yaml', 'codemagic.yaml']) {
      final f = File(path);
      if (!f.existsSync()) continue;
      final head = const LineSplitter()
          .convert(f.readAsStringSync())
          .take(4)
          .join(' ');
      expect(head.toUpperCase(), contains('GENERATED'),
          reason: '$path lost its generated-file header. If it was hand-edited, '
              'move the change into app.yaml and re-run scaffold.py --regen.');
    }
  });
}
