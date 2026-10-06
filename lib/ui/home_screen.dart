import 'package:flutter/material.dart';

import '../core/debug_flags.dart';
import '../l10n/l10n.dart';
import 'seed_sprout.dart';

/// The one screen. Minimal, but deliberately exercises what every app needs:
/// localization (including RTL), a custom-painted element that changes
/// visibly, persisted-ish state, and the debug inspector overlay.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _grow = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  int _grownCount = 0;

  @override
  void dispose() {
    _grow.dispose();
    super.dispose();
  }

  Future<void> _tap() async {
    if (_grow.isAnimating) return;
    if (_grow.value >= 1) {
      _grow.value = 0;
      return;
    }
    setState(() => _grownCount++);
    await _grow.forward();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.appTitle)),
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(l10n.greeting, style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text(l10n.tapPrompt,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colors.onSurfaceVariant)),
                const SizedBox(height: 24),
                Semantics(
                  button: true,
                  label: l10n.tapPrompt,
                  child: GestureDetector(
                    onTap: _tap,
                    child: AnimatedBuilder(
                      animation: _grow,
                      builder: (context, _) => SeedSprout(
                        growth: _grow.value,
                        inkColor: colors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(l10n.grownCount(_grownCount)),
              ],
            ),
          ),
          // The inspector: compiled out of release builds entirely, so it is
          // safe to leave wired up.
          if (DebugFlags.showInspector)
            Positioned(
              left: 8,
              right: 8,
              bottom: 8,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      DebugFlags.summary,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 11, height: 1.3),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
