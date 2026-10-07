import 'package:flutter/material.dart';

import '../core/app_services.dart';
import '../core/sfx.dart';
import '../core/test_env.dart';
import '../l10n/l10n.dart';
import '../pet/catalog.dart';
import '../pet/needs.dart';
import '../pet/pet_state.dart';
import 'pig/pig_view.dart';
import 'room_painter.dart';
import 'theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pig = PigViewController();
  final _name = TextEditingController(text: '');
  int _step = 0;

  static const _suggestions = ['Oinky', 'Truffle', 'Peanut', 'Muffin', 'Petunia', 'Waffles', 'Biscuit', 'Hamlet', 'Pumpkin', 'Mochi'];

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  String get _chosen => _name.text.trim().isEmpty ? PetState.defaultName : _name.text.trim();

  void _next() {
    final s = AppScope.of(context);
    FocusScope.of(context).unfocus();
    if (_step == 2) {
      s.sfx.play(Sfx.squealHappy);
      s.pet.completeOnboarding(_chosen);
      return;
    }
    s.sfx.play(_step == 0 ? Sfx.oink : Sfx.pop);
    _pig.react(_step == 0 ? Reaction.oink : Reaction.happy);
    setState(() => _step++);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final s = AppScope.of(context);
    final mq = MediaQuery.of(context);
    final compact = mq.size.height < 700 || mq.viewInsets.bottom > 0;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: RoomPainter('meadow', floorY: 0.52))),
          SafeArea(
            child: Column(
              children: [
                // Pig stage
                Expanded(
                  flex: compact ? 4 : 5,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(40, 12, 40, 0),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: PigView(
                            controller: _pig,
                            stage: Stage.piglet,
                            needs: const Needs(tummy: 90, clean: 100, fun: 90, energy: 100),
                            hat: 'bow',
                            onZone: (_) {
                              s.sfx.play(Sfx.oink, pitch: 1.15);
                              _pig.react(Reaction.oink);
                            },
                            animate: !isRunningUnderTest,
                          ),
                        ),
                        if (_step == 0)
                          const Positioned(left: 0, right: 0, bottom: 0, height: 92, child: IgnorePointer(child: CustomPaint(painter: _BasketPainter()))),
                      ],
                    ),
                  ),
                ),
                // Card
                Expanded(
                  flex: compact ? 6 : 5,
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: AppColors.cream,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                    ),
                    padding: const EdgeInsets.fromLTRB(24, 22, 24, 12),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 280),
                      child: KeyedSubtree(key: ValueKey(_step), child: _card(l)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(dynamic l) {
    final t = Theme.of(context).textTheme;
    switch (_step) {
      case 0:
        return Column(
          children: [
            Text(l.onbHello, textAlign: TextAlign.center, style: t.headlineSmall),
            const SizedBox(height: 10),
            Text(l.onbHelloBody, textAlign: TextAlign.center, style: t.bodyLarge),
            const Spacer(),
            SizedBox(width: double.infinity, child: FilledButton(onPressed: _next, child: Text(l.onbHelloCta))),
          ],
        );
      case 1:
        return SingleChildScrollView(
          child: Column(
            children: [
              Text(l.onbNameTitle, textAlign: TextAlign.center, style: t.headlineSmall),
              const SizedBox(height: 14),
              TextField(
                controller: _name,
                maxLength: 16,
                textAlign: TextAlign.center,
                textCapitalization: TextCapitalization.words,
                style: const TextStyle(fontFamily: 'Fredoka', fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.ink),
                decoration: InputDecoration(
                  hintText: PetState.defaultName,
                  counterText: '',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                ),
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _next(),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  for (final n in _suggestions)
                    ChoiceChip(
                      label: Text(n),
                      selected: _name.text.trim() == n,
                      onSelected: (_) {
                        AppScope.of(context).sfx.play(Sfx.tap);
                        setState(() => _name.text = n);
                      },
                      selectedColor: AppColors.pinkSoft,
                      backgroundColor: Colors.white,
                      side: BorderSide.none,
                      labelStyle: const TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.w500, color: AppColors.ink),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              SizedBox(width: double.infinity, child: FilledButton(onPressed: _next, child: Text(l.onbNameCta))),
            ],
          ),
        );
      default:
        final tips = <(IconData, Color, String)>[
          (Icons.restaurant_rounded, AppColors.tummy, l.onbTipFeed),
          (Icons.bubble_chart_rounded, AppColors.clean, l.onbTipBath),
          (Icons.favorite_rounded, AppColors.pink, l.onbTipLove),
          (Icons.checkroom_rounded, AppColors.lavender, l.onbTipGrow),
        ];
        return Column(
          children: [
            Text(l.onbTipsTitle(_chosen), textAlign: TextAlign.center, style: t.headlineSmall),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: [
                  for (final (icon, color, text) in tips)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                            child: Icon(icon, color: Colors.white, size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(child: Text(text, style: t.bodyLarge)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(width: double.infinity, child: FilledButton(onPressed: _next, child: Text(l.onbGo))),
          ],
        );
    }
  }
}

/// A wicker basket the piglet peeks out of on the very first screen.
class _BasketPainter extends CustomPainter {
  const _BasketPainter();

  @override
  void paint(Canvas c, Size s) {
    final w = s.width;
    final body = RRect.fromRectAndCorners(
      Rect.fromLTWH(w * 0.14, s.height * 0.18, w * 0.72, s.height * 0.82),
      bottomLeft: const Radius.circular(30),
      bottomRight: const Radius.circular(30),
      topLeft: const Radius.circular(8),
      topRight: const Radius.circular(8),
    );
    c.drawRRect(body, Paint()..color = const Color(0xFFD9A066));
    final weave = Paint()
      ..color = const Color(0xFFB97E45)
      ..strokeWidth = 3;
    for (var y = body.top + 14; y < body.bottom - 6; y += 14) {
      c.drawLine(Offset(body.left + 8, y), Offset(body.right - 8, y), weave);
    }
    for (var x = body.left + 18; x < body.right - 10; x += 22) {
      c.drawLine(Offset(x, body.top + 4), Offset(x, body.bottom - 8), weave..strokeWidth = 2);
    }
    final rim = RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.1, 0, w * 0.8, s.height * 0.24), const Radius.circular(14));
    c.drawRRect(rim, Paint()..color = const Color(0xFFC98B52));
    // Blanket edge
    final blanket = Path()
      ..moveTo(w * 0.18, s.height * 0.05)
      ..quadraticBezierTo(w * 0.3, -s.height * 0.08, w * 0.42, s.height * 0.04)
      ..quadraticBezierTo(w * 0.5, -s.height * 0.06, w * 0.6, s.height * 0.04)
      ..quadraticBezierTo(w * 0.72, -s.height * 0.08, w * 0.82, s.height * 0.05)
      ..lineTo(w * 0.82, s.height * 0.12)
      ..lineTo(w * 0.18, s.height * 0.12)
      ..close();
    c.drawPath(blanket, Paint()..color = const Color(0xFF9FD8F5));
  }

  @override
  bool shouldRepaint(_BasketPainter old) => false;
}
