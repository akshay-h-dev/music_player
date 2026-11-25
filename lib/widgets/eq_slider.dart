import 'package:flutter/material.dart';

import '../theme.dart';
import '../utils/format.dart';

/// One vertical EQ slider with dB readout on top and label below.
class EqSlider extends StatefulWidget {
  const EqSlider({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.enabled,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final bool enabled;
  final ValueChanged<double> onChanged;

  @override
  State<EqSlider> createState() => _EqSliderState();
}

class _EqSliderState extends State<EqSlider> {
  bool _dragging = false;

  @override
  Widget build(BuildContext context) {
    final accent = context.appAccent;
    final isZero = widget.value == 0;
    final valueColor = _dragging
        ? accent.pale
        : isZero
        ? accent.light
        : const Color(0xFFDDD8E8);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          formatDb(widget.value),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: valueColor,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: 44,
          height: 220,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 0 dB center mark
              Container(
                width: isZero ? 34 : 32,
                height: isZero ? 2 : 1,
                color: isZero
                    ? accent.light.withValues(alpha: 0.5)
                    : Colors.white.withValues(alpha: 0.16),
              ),
              // quarterTurns: 3 puts the minimum at the bottom.
              RotatedBox(
                quarterTurns: 3,
                child: SliderTheme(
                  data: Theme.of(context).sliderTheme.copyWith(
                    activeTrackColor: _dragging ? accent.soft : accent.primary,
                  ),
                  child: Slider(
                    value: widget.value.clamp(widget.min, widget.max),
                    min: widget.min,
                    max: widget.max,
                    divisions: (widget.max - widget.min).round(),
                    semanticFormatterCallback: formatDb,
                    onChanged: widget.enabled ? widget.onChanged : null,
                    onChangeStart: (_) => setState(() => _dragging = true),
                    onChangeEnd: (_) => setState(() => _dragging = false),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
