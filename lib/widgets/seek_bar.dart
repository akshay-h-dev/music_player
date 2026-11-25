import 'package:flutter/material.dart';

import '../services/audio_service.dart';
import '../theme.dart';
import '../utils/format.dart';

/// Progress slider with elapsed / total time. Doesn't jump while dragging.
class SeekBar extends StatefulWidget {
  const SeekBar({super.key, required this.stream, required this.onSeek});
  final Stream<PositionData> stream;
  final Future<void> Function(Duration) onSeek;

  @override
  State<SeekBar> createState() => _SeekBarState();
}

class _SeekBarState extends State<SeekBar> {
  double? _drag; // ms while the user is dragging

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PositionData>(
      stream: widget.stream,
      builder: (context, snapshot) {
        final data =
            snapshot.data ?? const PositionData(Duration.zero, Duration.zero);
        final totalMs = data.duration.inMilliseconds.toDouble();
        final max = totalMs > 0 ? totalMs : 1.0;
        final posMs = (_drag ?? data.position.inMilliseconds.toDouble()).clamp(
          0.0,
          max,
        );

        const labelStyle = TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: AppColors.textMuted,
          fontFeatures: [FontFeature.tabularFigures()],
        );

        return Column(
          children: [
            Slider(
              value: posMs,
              max: max,
              onChanged: totalMs > 0 ? (v) => setState(() => _drag = v) : null,
              onChangeEnd: (v) async {
                await widget.onSeek(Duration(milliseconds: v.round()));
                if (mounted) setState(() => _drag = null);
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    formatTime(Duration(milliseconds: posMs.round())),
                    style: labelStyle,
                  ),
                  Text(formatTime(data.duration), style: labelStyle),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
