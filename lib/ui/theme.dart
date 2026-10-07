import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();
  static const cream = Color(0xFFFFF6EC);
  static const card = Color(0xFFFFFFFF);
  static const pink = Color(0xFFFF7FA3);
  static const pinkDeep = Color(0xFFE85A86);
  static const pinkSoft = Color(0xFFFFE1EA);
  static const ink = Color(0xFF5B2A3F);
  static const inkSoft = Color(0xFF9A6A7E);
  static const acorn = Color(0xFFB5793F);
  static const acornLight = Color(0xFFFFE8C7);
  static const mint = Color(0xFF5CC8A0);
  static const sky = Color(0xFF7CC6F2);
  static const sun = Color(0xFFFFC94D);
  static const lavender = Color(0xFFB79CF2);
  static const danger = Color(0xFFFF6B6B);

  /// Meter colours, one per need, in [Need] order.
  static const tummy = Color(0xFFFF9F68);
  static const clean = Color(0xFF6EC6FF);
  static const fun = Color(0xFFFFC94D);
  static const energy = Color(0xFFA78BFA);
}

ThemeData buildTheme() {
  const display = 'Fredoka';
  const body = 'Nunito';
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.pink, primary: AppColors.pinkDeep, surface: AppColors.cream),
    scaffoldBackgroundColor: AppColors.cream,
    fontFamily: body,
  );
  final t = base.textTheme;
  return base.copyWith(
    textTheme: t.copyWith(
      displaySmall: t.displaySmall?.copyWith(fontFamily: display, fontWeight: FontWeight.w600, color: AppColors.ink),
      headlineMedium: t.headlineMedium?.copyWith(fontFamily: display, fontWeight: FontWeight.w600, color: AppColors.ink),
      headlineSmall: t.headlineSmall?.copyWith(fontFamily: display, fontWeight: FontWeight.w600, color: AppColors.ink),
      titleLarge: t.titleLarge?.copyWith(fontFamily: display, fontWeight: FontWeight.w600, color: AppColors.ink),
      titleMedium: t.titleMedium?.copyWith(fontFamily: display, fontWeight: FontWeight.w500, color: AppColors.ink),
      titleSmall: t.titleSmall?.copyWith(fontFamily: display, fontWeight: FontWeight.w500, color: AppColors.ink),
      labelLarge: t.labelLarge?.copyWith(fontFamily: display, fontWeight: FontWeight.w600),
      labelMedium: t.labelMedium?.copyWith(fontFamily: display, fontWeight: FontWeight.w500),
      bodyLarge: t.bodyLarge?.copyWith(color: AppColors.ink, fontWeight: FontWeight.w600),
      bodyMedium: t.bodyMedium?.copyWith(color: AppColors.ink, fontWeight: FontWeight.w600),
      bodySmall: t.bodySmall?.copyWith(color: AppColors.inkSoft, fontWeight: FontWeight.w600),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.pinkDeep,
        foregroundColor: Colors.white,
        minimumSize: const Size(64, 52),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(fontFamily: display, fontWeight: FontWeight.w600, fontSize: 18),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.pinkDeep,
        textStyle: const TextStyle(fontFamily: display, fontWeight: FontWeight.w600, fontSize: 16),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.cream,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      titleTextStyle: const TextStyle(fontFamily: display, fontWeight: FontWeight.w600, fontSize: 22, color: AppColors.ink),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.cream,
      showDragHandle: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? Colors.white : null),
      trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? AppColors.pink : null),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.ink,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      contentTextStyle: const TextStyle(fontFamily: body, fontWeight: FontWeight.w700, color: Colors.white),
    ),
  );
}

/// A soft white rounded card with a gentle shadow — the app's one surface.
class SoftCard extends StatelessWidget {
  const SoftCard({super.key, required this.child, this.padding = const EdgeInsets.all(12), this.radius = 22, this.color});
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? color;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    // Shadow only — the colour lives on the Material below, so ListTiles
    // inside a card keep their ink splashes.
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      boxShadow: const [BoxShadow(color: Color(0x1A8A3A5A), blurRadius: 16, offset: Offset(0, 6))],
    ),
    child: Material(
      color: color ?? AppColors.card,
      borderRadius: BorderRadius.circular(radius),
      clipBehavior: Clip.antiAlias,
      child: Padding(padding: padding, child: child),
    ),
  );
}
