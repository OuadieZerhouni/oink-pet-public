import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/app_services.dart';
import 'core/debug_flags.dart';
import 'core/settings.dart';
import 'l10n/app_localizations.dart';
import 'ui/home_screen.dart';
import 'ui/onboarding_screen.dart';
import 'ui/theme.dart';
import 'ui/widgets.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
  runApp(const OinkApp());
}

class OinkApp extends StatefulWidget {
  const OinkApp({super.key, this.servicesFuture});

  /// Test seam: inject prepared services instead of loading from disk.
  final Future<AppServices>? servicesFuture;

  @override
  State<OinkApp> createState() => _OinkAppState();
}

class _OinkAppState extends State<OinkApp> {
  late final Future<AppServices> _services = widget.servicesFuture ?? AppServices.create(clock: DebugFlags.clock);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppServices>(
      future: _services,
      builder: (context, snap) {
        final services = snap.data;
        if (services == null) return _app(locale: null, home: const _Splash());
        return AppScope(
          services: services,
          child: ValueListenableBuilder<AppSettings>(
            valueListenable: services.settings,
            builder: (context, s, _) => _app(
              locale: s.languageCode == null ? null : Locale(s.languageCode!),
              // Onboarding ↔ home is decided by the pet itself, so "start
              // over" in settings lands back on onboarding automatically.
              home: ListenableBuilder(
                listenable: services.pet,
                builder: (context, _) => AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  child: services.pet.state.onboarded
                      ? const HomeScreen(key: ValueKey('home'))
                      : const OnboardingScreen(key: ValueKey('onboarding')),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _app({required Locale? locale, required Widget home}) => MaterialApp(
    debugShowCheckedModeBanner: false,
    onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
    locale: locale,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    theme: buildTheme(),
    builder: (context, child) => ClampedTextScale(child: child ?? const SizedBox()),
    home: home,
  );
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.pink)),
      ),
    );
  }
}
