import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../pet/needs.dart';
import 'theme.dart';

/// Acorn currency icon, drawn (not an emoji) so it matches the app's palette
/// on every device.
class AcornIcon extends StatelessWidget {
  const AcornIcon({super.key, this.size = 20});
  final double size;

  @override
  Widget build(BuildContext context) => CustomPaint(size: Size.square(size), painter: _AcornPainter());
}

class _AcornPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final w = s.width;
    final nut = Rect.fromLTWH(w * 0.2, w * 0.32, w * 0.6, w * 0.62);
    c.drawOval(nut, Paint()..color = const Color(0xFFC98A4B));
    c.drawOval(Rect.fromLTWH(w * 0.3, w * 0.42, w * 0.16, w * 0.3), Paint()..color = const Color(0x55FFFFFF));
    final cap = RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.12, w * 0.2, w * 0.76, w * 0.24), Radius.circular(w * 0.12));
    c.drawRRect(cap, Paint()..color = const Color(0xFF7A4A24));
    c.drawLine(
      Offset(w * 0.5, w * 0.2),
      Offset(w * 0.58, w * 0.04),
      Paint()
        ..color = const Color(0xFF7A4A24)
        ..strokeWidth = w * 0.09
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_AcornPainter old) => false;
}

/// "🌰 42" pill. Animates the number when it changes.
class AcornBadge extends StatelessWidget {
  const AcornBadge({super.key, required this.count, this.onTap});
  final int count;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$count acorns',
      button: onTap != null,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(8, 6, 14, 6),
          decoration: BoxDecoration(
            color: AppColors.acornLight,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: const Color(0xFFEFC98F), width: 2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AcornIcon(size: 22),
              const SizedBox(width: 6),
              TweenAnimationBuilder<double>(
                tween: Tween(end: count.toDouble()),
                duration: const Duration(milliseconds: 500),
                builder: (context, v, _) => Text(
                  '${v.round()}',
                  style: const TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.w600, fontSize: 18, color: AppColors.acorn),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A round need meter: icon in a ring that fills, pulses when low.
class NeedMeter extends StatefulWidget {
  const NeedMeter({super.key, required this.need, required this.value, required this.label});
  final Need need;
  final double value;
  final String label;

  static Color colorFor(Need n) => switch (n) {
    Need.tummy => AppColors.tummy,
    Need.clean => AppColors.clean,
    Need.fun => AppColors.fun,
    Need.energy => AppColors.energy,
  };

  static IconData iconFor(Need n) => switch (n) {
    Need.tummy => Icons.restaurant_rounded,
    Need.clean => Icons.bubble_chart_rounded,
    Need.fun => Icons.star_rounded,
    Need.energy => Icons.bedtime_rounded,
  };

  @override
  State<NeedMeter> createState() => _NeedMeterState();
}

class _NeedMeterState extends State<NeedMeter> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(NeedMeter old) {
    super.didUpdateWidget(old);
    _sync();
  }

  void _sync() {
    final low = widget.value < Needs.low;
    if (low && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (!low && _pulse.isAnimating) {
      _pulse
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = NeedMeter.colorFor(widget.need);
    final v = (widget.value / 100).clamp(0.0, 1.0);
    return Semantics(
      label: '${widget.label} ${widget.value.round()}%',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _pulse,
            builder: (context, child) => Transform.scale(scale: 1 + 0.08 * _pulse.value, child: child),
            child: SizedBox.square(
              dimension: 48,
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: v),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                builder: (context, t, _) => CustomPaint(
                  painter: _RingPainter(t, color),
                  child: Center(
                    child: Icon(NeedMeter.iconFor(widget.need), color: t < Needs.low / 100 ? AppColors.danger : color, size: 22),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 3),
          SizedBox(
            width: 70,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                widget.label,
                maxLines: 1,
                style: const TextStyle(fontFamily: 'Fredoka', fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.ink),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.value, this.color);
  final double value;
  final Color color;

  @override
  void paint(Canvas c, Size s) {
    final center = s.center(Offset.zero);
    final r = s.width / 2;
    c.drawCircle(center, r, Paint()..color = Colors.white);
    final track = Paint()
      ..color = color.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;
    c.drawCircle(center, r - 3.5, track);
    final arc = Paint()
      ..color = value < Needs.low / 100 ? AppColors.danger : color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    c.drawArc(Rect.fromCircle(center: center, radius: r - 3.5), -math.pi / 2, 2 * math.pi * value, false, arc);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.value != value || old.color != color;
}

/// A rounded speech bubble with a little tail, that pops in and out.
class SpeechBubble extends StatelessWidget {
  const SpeechBubble({super.key, required this.text});
  final String? text;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      transitionBuilder: (child, a) => ScaleTransition(
        scale: CurvedAnimation(parent: a, curve: Curves.easeOutBack),
        child: FadeTransition(opacity: a, child: child),
      ),
      child: text == null
          ? const SizedBox(key: ValueKey('none'), height: 52)
          : CustomPaint(
              key: ValueKey(text),
              painter: _BubbleTail(),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 260),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: const [BoxShadow(color: Color(0x228A3A5A), blurRadius: 12, offset: Offset(0, 4))],
                ),
                child: Text(
                  text!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.w500, fontSize: 17, color: AppColors.ink),
                ),
              ),
            ),
    );
  }
}

class _BubbleTail extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final path = Path()
      ..moveTo(s.width / 2 - 10, s.height - 11)
      ..lineTo(s.width / 2, s.height)
      ..lineTo(s.width / 2 + 10, s.height - 11)
      ..close();
    c.drawPath(path, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_BubbleTail old) => false;
}

/// A chunky round action button for the bottom dock.
class DockButton extends StatelessWidget {
  const DockButton({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.enabled = true,
    this.highlight = false,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool enabled;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) => _build(context, box.maxWidth.isFinite ? box.maxWidth : 70));
  }

  Widget _build(BuildContext context, double maxWidth) {
    final d = (maxWidth - 6).clamp(44.0, 58.0);
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: enabled ? 1 : 0.45,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: d,
                height: d,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: highlight ? 4 : 3),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: highlight ? 0.6 : 0.35),
                      blurRadius: highlight ? 16 : 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: d * 0.48),
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: maxWidth,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: const TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.ink),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Clamp text scaling so the playful layout never explodes, while still
/// honouring the user's preference up to a point.
class ClampedTextScale extends StatelessWidget {
  const ClampedTextScale({super.key, required this.child, this.max = 1.25});
  final Widget child;
  final double max;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return MediaQuery(
      data: mq.copyWith(textScaler: mq.textScaler.clamp(minScaleFactor: 0.9, maxScaleFactor: max)),
      child: child,
    );
  }
}
