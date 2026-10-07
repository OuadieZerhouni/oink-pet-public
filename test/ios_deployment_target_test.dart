// iOS deployment target — one value, everywhere, and not below Xcode's floor.
//
// Xcode 27 refuses to archive anything with IPHONEOS_DEPLOYMENT_TARGET below
// 15.0 ("the range of supported deployment target versions is 15.0 to
// 27.0.x"). The template shipped 13.0 — Flutter's old default — and the first
// local release build died eight minutes in, after tests and signing had all
// passed. This test moves that failure to `flutter test`, seconds in.
//
// The value lives in project.pbxproj three times (Debug/Release/Profile) and,
// once the app has plugins, in ios/Podfile too. They must agree: CocoaPods
// builds pods against the Podfile's platform, and a mismatch surfaces first
// as linker warnings and later as errors.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const minimumIosTarget = 15.0;

void main() {
  test('IPHONEOS_DEPLOYMENT_TARGET is one value and >= $minimumIosTarget', () {
    final pbxproj =
        File('ios/Runner.xcodeproj/project.pbxproj').readAsStringSync();
    final targets = RegExp(r'IPHONEOS_DEPLOYMENT_TARGET = (\d+(?:\.\d+)?);')
        .allMatches(pbxproj)
        .map((m) => m.group(1)!)
        .toSet();
    expect(targets, isNotEmpty,
        reason: 'no IPHONEOS_DEPLOYMENT_TARGET in project.pbxproj');
    expect(targets, hasLength(1),
        reason: 'project.pbxproj disagrees with itself: $targets');
    expect(double.parse(targets.single), greaterThanOrEqualTo(minimumIosTarget),
        reason: 'Xcode 27 refuses to archive below $minimumIosTarget');

    final podfile = File('ios/Podfile');
    if (podfile.existsSync()) {
      final m = RegExp(r"^platform :ios, '(\d+(?:\.\d+)?)'", multiLine: true)
          .firstMatch(podfile.readAsStringSync());
      expect(m, isNotNull, reason: 'ios/Podfile has no `platform :ios` line');
      expect(m!.group(1), targets.single,
          reason: 'ios/Podfile platform must match project.pbxproj');
    }
  });
}
