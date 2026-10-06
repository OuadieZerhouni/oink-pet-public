// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'قالب التطبيق';

  @override
  String get greeting => 'مرحبا!';

  @override
  String get tapPrompt => 'المس البذرة لتنمو';

  @override
  String grownCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'نما $count مرة',
      many: 'نما $count مرة',
      few: 'نما $count مرات',
      two: 'نما مرتين',
      one: 'نما مرة',
      zero: 'لم ينمُ شيء بعد',
    );
    return '$_temp0';
  }
}
