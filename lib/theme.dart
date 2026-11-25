import 'package:flutter/material.dart';

/// Colors taken from the Figma design.
class AppColors {
  static const background = Color(0xFF09090D);
  static const surface = Color(0xFF17161D);
  static const accent = Color(0xFF7C4DFF);
  static const accentSoft = Color(0xFFA98CFF);
  static const accentLight = Color(0xFFB49AFF);
  static const accentPale = Color(0xFFC9B7FF);
  static const textPrimary = Color(0xFFF5F1FA);
  static const textSecondary = Color(0xFFAAA4B7);
  static const textMuted = Color(0xFF87818F);
  static const textFaint = Color(0xFF696471);
  static const trackInactive = Color(0xFF34313B);
  static const snackbar = Color(0xFF302E36);

  static Color get cardBorder => Colors.white.withValues(alpha: 0.04);
}

/// White dot with a violet ring (the slider thumb in the design).
class RingThumbShape extends SliderComponentShape {
  const RingThumbShape({this.radius = 7});
  final double radius;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) =>
      Size.fromRadius(radius);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;
    canvas.drawShadow(
      Path()..addOval(Rect.fromCircle(center: center, radius: radius)),
      Colors.black,
      3,
      true,
    );
    canvas.drawCircle(center, radius, Paint()..color = AppColors.accent);
    canvas.drawCircle(center, radius - 3, Paint()..color = Colors.white);
  }
}

ThemeData buildAppTheme() {
  final scheme =
      ColorScheme.fromSeed(
        seedColor: AppColors.accent,
        brightness: Brightness.dark,
      ).copyWith(
        primary: AppColors.accent,
        surface: AppColors.background,
        onSurface: AppColors.textPrimary,
      );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.background,
    // To match the design exactly, bundle Inter and uncomment:
    // fontFamily: 'Inter',
    sliderTheme: SliderThemeData(
      trackHeight: 4,
      activeTrackColor: AppColors.accent,
      inactiveTrackColor: AppColors.trackInactive,
      thumbColor: AppColors.accent,
      thumbShape: const RingThumbShape(),
      trackShape: const RoundedRectSliderTrackShape(),
      overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
      overlayColor: AppColors.accent.withValues(alpha: 0.16),
      tickMarkShape: SliderTickMarkShape.noTickMark,
      disabledActiveTrackColor: AppColors.textFaint,
      disabledInactiveTrackColor: AppColors.trackInactive,
      disabledThumbColor: AppColors.textFaint,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.snackbar,
      contentTextStyle: const TextStyle(
        color: Color(0xFFF4EFF8),
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
      actionTextColor: AppColors.accentLight,
      insetPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.07)),
      ),
    ),
  );
}
