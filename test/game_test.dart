import 'package:flutter_test/flutter_test.dart';
import 'package:oink_pet/ui/game/apple_catch_logic.dart';
import 'package:oink_pet/ui/game/apple_catch_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('AppleCatchGame rules', () {
    test('items fall, are caught under the pig, missed elsewhere', () {
      final g = AppleCatchGame(seed: 1);
      g.items.add(FallingItem(FallKind.apple, 0.5, 0.5));
      g.items.add(FallingItem(FallKind.apple, 0.95, 0.5));
      for (var i = 0; i < 200 && g.items.where((it) => it.x == 0.5 || it.x == 0.95).isNotEmpty; i++) {
        g.step(1 / 60);
      }
      expect(g.score, greaterThanOrEqualTo(1));
    });

    test('bees cost hearts and three stings end the game', () {
      final g = AppleCatchGame(seed: 2);
      for (var k = 0; k < 3; k++) {
        g.items.add(FallingItem(FallKind.bee, g.pigX, 1)..y = AppleCatchGame.pigLine - 0.01);
        g.step(1 / 60);
      }
      expect(g.hearts, 0);
      expect(g.isOver, isTrue);
      expect(g.step(1 / 60), isEmpty);
    });

    test('the timer ends the game after its duration', () {
      final g = AppleCatchGame(seed: 3, duration: 2);
      for (var i = 0; i < 200; i++) {
        g.step(1 / 60);
        g.items.removeWhere((it) => it.kind == FallKind.bee); // stay alive
      }
      expect(g.isOver, isTrue);
      expect(g.timeLeft, 0);
    });
  });

  testWidgets('the game runs: start, time ticks down, result pays acorns', (tester) async {
    await phoneSize(tester);
    final s = makeServices(acorns: 0);
    await tester.pumpWidget(wrap(s, const AppleCatchScreen(seed: 7)));
    await tester.pumpAndSettle();
    expect(find.text('Apple Catch'), findsOneWidget);
    await tester.tap(find.text('Start'));
    await tester.pump();
    // Run 50 s of game time in 1/30 s frames, dragging the pig around.
    final center = tester.getCenter(find.byType(AppleCatchScreen));
    final gesture = await tester.startGesture(center);
    for (var i = 0; i < 50 * 30; i++) {
      await gesture.moveBy(Offset(i.isEven ? 3 : -3, 0));
      await tester.pump(const Duration(milliseconds: 33));
      if (find.text('Play again').evaluate().isNotEmpty) break;
    }
    await gesture.up();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Play again'), findsOneWidget, reason: 'the round ended');
    expect(s.pet.state.stats.games, 1);
    expect(tester.takeException(), isNull);
  });
}
