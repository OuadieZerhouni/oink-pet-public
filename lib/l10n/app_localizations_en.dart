// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Oink';

  @override
  String get greeting => 'Hello!';

  @override
  String get tapPrompt => 'Tap the seed to grow it';

  @override
  String grownCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Grown $count times',
      one: 'Grown once',
      zero: 'Nothing grown yet',
    );
    return '$_temp0';
  }
}
