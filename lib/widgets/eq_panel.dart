import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/eq_service.dart';
import '../theme.dart';
import 'eq_slider.dart';

/// The "Custom / 3-band equalizer" card: sliders, scale, Reset to Flat.
class EqPanel extends StatelessWidget {
  const EqPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final eq = context.watch<EqService>();
    final accent = context.appAccent;
    const scaleStyle = TextStyle(
      fontSize: 9,
      fontWeight: FontWeight.w500,
      color: AppColors.textFaint,
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Custom',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 2),
                  Text(
                    '3-band equalizer',
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
              Semantics(
                label: 'Equalizer active',
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.primary,
                    boxShadow: [
                      BoxShadow(color: accent.primary, blurRadius: 12),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                for (var i = 0; i < EqBand.values.length; i++) ...[
                  if (i > 0) const SizedBox(width: 28),
                  Expanded(child: EqSliderFor(band: EqBand.values[i])),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${eq.minDb.round()} dB', style: scaleStyle),
                const Text('0 dB center', style: scaleStyle),
                Text('+${eq.maxDb.round()} dB', style: scaleStyle),
              ],
            ),
          ),
          if (eq.isInitialized && !eq.isAvailable) ...[
            const SizedBox(height: 12),
            const Text(
              'Equalizer unavailable on this device',
              style: TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ],
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: eq.isFlat ? null : eq.reset,
            style:
                OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(44),
                  shape: const StadiumBorder(),
                  foregroundColor: accent.light,
                  disabledForegroundColor: const Color(0xFF5F5A66),
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ).copyWith(
                  side: WidgetStateProperty.resolveWith(
                    (states) => BorderSide(
                      color: states.contains(WidgetState.disabled)
                          ? const Color(0xFF3C3941)
                          : accent.primary.withValues(alpha: 0.7),
                    ),
                  ),
                ),
            child: const Text('Reset to Flat'),
          ),
        ],
      ),
    );
  }
}

/// Wires one [EqSlider] to the [EqService].
class EqSliderFor extends StatelessWidget {
  const EqSliderFor({super.key, required this.band});
  final EqBand band;

  @override
  Widget build(BuildContext context) {
    final eq = context.watch<EqService>();
    return EqSlider(
      label: band.label,
      value: eq.valueOf(band),
      min: eq.minDb,
      max: eq.maxDb,
      enabled: eq.isAvailable,
      onChanged: (v) => eq.setGain(band, v),
    );
  }
}
