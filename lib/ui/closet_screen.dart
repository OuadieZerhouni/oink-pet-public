import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/app_services.dart';
import '../core/sfx.dart';
import '../core/test_env.dart';
import '../l10n/app_localizations.dart';
import '../l10n/l10n.dart';
import '../pet/catalog.dart';
import '../pet/pet_controller.dart';
import 'names.dart';
import 'pig/accessories.dart';
import 'pig/pig_view.dart';
import 'room_painter.dart';
import 'theme.dart';
import 'widgets.dart';

class ClosetScreen extends StatefulWidget {
  const ClosetScreen({super.key});

  @override
  State<ClosetScreen> createState() => _ClosetScreenState();
}

class _ClosetScreenState extends State<ClosetScreen> {
  final _pig = PigViewController();
  static const _tabs = [Slot.hat, Slot.glasses, Slot.neck, Slot.room];

  String _tabLabel(AppLocalizations l, Slot s) => switch (s) {
    Slot.hat => l.tabHats,
    Slot.glasses => l.tabGlasses,
    Slot.neck => l.tabNeck,
    Slot.room => l.tabRooms,
  };

  void _snack(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text), duration: const Duration(seconds: 3)));
  }

  Future<void> _tap(Cosmetic c) async {
    final l = context.l10n;
    final s = AppScope.of(context);
    final pet = s.pet;
    final st = pet.state;
    if (st.owned.contains(c.id)) {
      if (pet.isEquipped(c)) {
        if (c.slot == Slot.room) return;
        pet.unequip(c.slot);
        s.sfx.play(Sfx.pop);
      } else {
        pet.equip(c);
        s.sfx.play(Sfx.sparkle, volume: 0.6);
        _pig.react(Reaction.happy);
      }
      return;
    }
    if (!pet.isAvailable(c)) return _snack(l.closetGone);
    if (pet.isLevelLocked(c)) return _snack(l.closetNeedLevel(c.minLevel));
    final price = pet.priceOf(c);
    if (st.acorns < price) {
      s.sfx.play(Sfx.snort);
      return _snack(l.closetTooPoor(price - st.acorns, st.name));
    }
    s.sfx.play(Sfx.pop);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.closetBuyTitle(itemName(l, c.id))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(width: 120, height: 100, child: CustomPaint(painter: ItemThumbPainter(c))),
            const SizedBox(height: 12),
            Text(l.closetBuyBody(price, st.acorns), textAlign: TextAlign.center),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
          FilledButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const AcornIcon(size: 18),
            label: Text('${l.closetBuy} · $price'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    if (pet.buy(c) == BuyResult.bought) {
      s.sfx.play(Sfx.acorn);
      s.sfx.play(Sfx.sparkle, volume: 0.7);
      s.sfx.bump();
      _pig.react(Reaction.happy);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final s = AppScope.of(context);
    return DefaultTabController(
      length: _tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l.closetTitle, style: Theme.of(context).textTheme.titleLarge),
          backgroundColor: AppColors.cream,
          surfaceTintColor: Colors.transparent,
          actions: [
            ListenableBuilder(
              listenable: s.pet,
              builder: (context, _) => Padding(padding: const EdgeInsets.only(right: 12), child: AcornBadge(count: s.pet.state.acorns)),
            ),
          ],
        ),
        body: ListenableBuilder(
          listenable: s.pet,
          builder: (context, _) {
            final st = s.pet.state;
            return Column(
              children: [
                // Live preview
                SizedBox(
                  height: 230,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
                    child: Stack(
                      children: [
                        Positioned.fill(child: CustomPaint(painter: RoomPainter(st.room, floorY: 0.8))),
                        Positioned.fill(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 6, bottom: 4),
                            child: PigView(
                              controller: _pig,
                              stage: st.stage,
                              needs: st.needs,
                              hat: st.equipped[Slot.hat],
                              glasses: st.equipped[Slot.glasses],
                              neck: st.equipped[Slot.neck],
                              onZone: (_) {
                                s.sfx.play(Sfx.oink);
                                _pig.react(Reaction.oink);
                              },
                              animate: !isRunningUnderTest,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                TabBar(
                  labelColor: AppColors.pinkDeep,
                  unselectedLabelColor: AppColors.inkSoft,
                  indicatorColor: AppColors.pink,
                  labelStyle: const TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.w600, fontSize: 15),
                  tabs: [for (final t in _tabs) Tab(text: _tabLabel(l, t))],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      for (final t in _tabs)
                        GridView.count(
                          padding: const EdgeInsets.all(16),
                          crossAxisCount: 3,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.78,
                          children: [
                            for (final c in Catalog.inSlot(t).where((c) => s.pet.isAvailable(c) || c.seasonal == null))
                              _ItemTile(item: c, pet: s.pet, onTap: () => _tap(c)),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ItemTile extends StatelessWidget {
  const _ItemTile({required this.item, required this.pet, required this.onTap});
  final Cosmetic item;
  final PetController pet;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final st = pet.state;
    final owned = st.owned.contains(item.id);
    final equipped = pet.isEquipped(item);
    final levelLocked = !owned && pet.isLevelLocked(item);
    final price = pet.priceOf(item);
    final name = itemName(l, item.id);

    Widget status;
    if (equipped) {
      status = _pill(item.slot == Slot.room ? l.closetHome : l.closetWearing, AppColors.mint, Icons.check_rounded);
    } else if (owned) {
      status = _pill(l.closetOwned, AppColors.inkSoft, null);
    } else if (levelLocked) {
      status = _pill(l.unlockLevel(item.minLevel), AppColors.inkSoft, Icons.lock_rounded);
    } else {
      status = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AcornIcon(size: 16),
          const SizedBox(width: 3),
          Text('$price', style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.w600, fontSize: 15, color: st.acorns >= price ? AppColors.acorn : AppColors.inkSoft)),
        ],
      );
    }

    return Semantics(
      button: true,
      label: name,
      selected: equipped,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: equipped ? AppColors.mint : Colors.transparent, width: 3),
            boxShadow: const [BoxShadow(color: Color(0x148A3A5A), blurRadius: 8, offset: Offset(0, 3))],
          ),
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              Expanded(
                child: Opacity(
                  opacity: levelLocked ? 0.4 : 1,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: CustomPaint(size: Size.infinite, painter: ItemThumbPainter(item)),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.ink)),
              const SizedBox(height: 3),
              SizedBox(height: 20, child: Center(child: status)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pill(String text, Color color, IconData? icon) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (icon != null) Icon(icon, size: 14, color: color),
      if (icon != null) const SizedBox(width: 2),
      Flexible(child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color))),
    ],
  );
}

/// Draws one closet item on its own (thumbnails, purchase dialog).
class ItemThumbPainter extends CustomPainter {
  ItemThumbPainter(this.item);
  final Cosmetic item;

  @override
  void paint(Canvas c, Size s) {
    final w = s.width, h = s.height;
    c.save();
    c.clipRect(Offset.zero & s);
    const skin = Color(0xFFFFD3DF);
    switch (item.slot) {
      case Slot.room:
        // Paint the room at phone scale, then shrink it, so props keep the
        // proportions they have on the home screen.
        const virtualWidth = 390.0;
        final k = w / virtualWidth;
        c.scale(k, k);
        RoomPainter(item.id, floorY: 0.72).paint(c, Size(virtualWidth, h / k));
      case Slot.hat:
        // A pink "head top" for the hat to sit on.
        final r = math.min(w, h) * 0.5;
        final domeTop = h * 0.66;
        c.drawCircle(Offset(w / 2, domeTop + r * 1.15), r * 1.15, Paint()..color = skin);
        drawHat(c, item.id, Offset(w / 2, domeTop + r * 0.1), r);
      case Slot.glasses:
        final r = w * 0.62;
        c.drawCircle(Offset(w / 2, h * 0.55), math.min(w, h) * 0.46, Paint()..color = skin);
        drawGlasses(c, item.id, Offset(w / 2 - r * 0.42, h * 0.5), Offset(w / 2 + r * 0.42, h * 0.5), r);
      case Slot.neck:
        final r = w * 0.62;
        c.drawCircle(Offset(w / 2, -h * 0.05), math.min(w, h) * 0.55, Paint()..color = skin);
        drawNeck(c, item.id, Offset(w / 2, h * 0.36), r);
    }
    c.restore();
  }

  @override
  bool shouldRepaint(ItemThumbPainter old) => old.item.id != item.id;
}
