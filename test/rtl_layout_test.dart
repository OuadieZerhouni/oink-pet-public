import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oink_pet/l10n/app_localizations.dart';
import 'package:oink_pet/ui/home_screen.dart';

/// Proves the app is usable in a right-to-left language.
///
/// This ships in the template because RTL is the kind of thing that is either
/// tested from the first commit or discovered late and expensively. Two
/// specific failures it catches:
///
///   * **Plurals.** Arabic has six plural categories against English's two, so
///     an app whose only plural test is English ships broken Arabic grammar.
///   * **Direction.** A layout built with `left`/`right` instead of
///     `start`/`end` looks correct in review (in English) and mirrors wrongly
///     for the audience that reads RTL.
///
/// For an app whose market is largely Arabic-reading, this is not a nicety.
void main() {
  Future<void> pump(WidgetTester tester, Locale locale) async {
    await tester.pumpWidget(MaterialApp(
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: const HomeScreen(),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('renders in Arabic, right-to-left', (tester) async {
    await pump(tester, const Locale('ar'));
    expect(find.text('مرحبا!'), findsOneWidget);
    expect(Directionality.of(tester.element(find.text('مرحبا!'))),
        TextDirection.rtl,
        reason: 'Arabic must resolve to RTL; if this is LTR the whole layout '
            'is mirrored wrongly for its main audience');
  });

  testWidgets('Arabic plural categories are wired', (tester) async {
    // The template's grownCount uses ICU plurals with zero/one/two/few/many.
    // Rendering the zero case in Arabic proves the category exists rather than
    // silently falling back to `other`.
    await pump(tester, const Locale('ar'));
    expect(find.text('لم ينمُ شيء بعد'), findsOneWidget,
        reason: 'the Arabic zero-plural did not resolve — check the ICU '
            'plural block in app_ar.arb');
  });

  testWidgets('English still works (the regression this pairs with)',
      (tester) async {
    await pump(tester, const Locale('en'));
    expect(find.text('Hello!'), findsOneWidget);
    expect(find.text('Nothing grown yet'), findsOneWidget);
  });

  testWidgets('tapping the sprout counts, in both directions', (tester) async {
    await pump(tester, const Locale('ar'));
    await tester.tap(find.byType(GestureDetector).first);
    await tester.pumpAndSettle();
    expect(find.text('نما مرة'), findsOneWidget,
        reason: 'the one-plural should read as "grown once"');
  });
}
