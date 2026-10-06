import 'package:flutter/widgets.dart';

import 'app_localizations.dart';

/// `context.l10n` instead of `AppLocalizations.of(context)`.
///
/// Not sugar: the long form is verbose enough that people reach for a
/// hardcoded string instead, and a hardcoded string is a translation bug that
/// no test catches.
extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
