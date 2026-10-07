import 'package:flutter/material.dart';

import '../core/app_services.dart';
import '../l10n/l10n.dart';
import '../pet/catalog.dart';
import 'names.dart';
import 'theme.dart';

/// The pig's "diary": age, level progress and lifetime counters.
Future<void> showStatsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => const _StatsSheet(),
  );
}

class _StatsSheet extends StatelessWidget {
  const _StatsSheet();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final pet = AppScope.of(context).pet;
    final st = pet.state;
    final s = st.stats;
    final fav = s.favoriteFood;
    final favFood = fav == null ? null : Catalog.food(fav);
    final next = Economy.xpForNext(st.level);
    final tiles = <(String, String)>[
      (l.statsMeals, '${s.feeds}'),
      (l.statsBaths, '${s.baths}'),
      (l.statsOinks, '${s.oinks}'),
      (l.statsRubs, '${s.bellyRubs}'),
      (l.statsGames, '${s.games}'),
      (l.statsBest, '${s.bestScore}'),
    ];
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.statsTitle(st.name), textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text('${stageName(l, st.stage)} · ${l.statsAge(st.ageDays(pet.clock()))}', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
            SoftCard(
              child: Column(
                children: [
                  Text(l.statsXp(st.xp, next, st.level + 1), style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(value: (st.xp / next).clamp(0.0, 1.0), minHeight: 12, backgroundColor: AppColors.pinkSoft, color: AppColors.pink),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.25,
              children: [
                for (final (label, value) in tiles)
                  SoftCard(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(value, style: const TextStyle(fontFamily: 'Fredoka', fontSize: 24, fontWeight: FontWeight.w600, color: AppColors.pinkDeep)),
                        Text(label, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
              ],
            ),
            if (favFood != null) ...[
              const SizedBox(height: 12),
              SoftCard(
                child: Row(
                  children: [
                    Text(favFood.emoji, style: const TextStyle(fontSize: 32)),
                    const SizedBox(width: 12),
                    Expanded(child: Text(l.statsFavorite, style: Theme.of(context).textTheme.bodyMedium)),
                    Text(foodName(l, favFood.id), style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
