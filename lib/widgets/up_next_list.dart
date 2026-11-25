import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/audio_service.dart';
import '../theme.dart';
import '../utils/format.dart';

/// Every track except the current one; tap to play.
class UpNextList extends StatelessWidget {
  const UpNextList({super.key});

  @override
  Widget build(BuildContext context) {
    final audio = context.watch<AudioService>();
    final upcoming = [
      for (var i = 0; i < audio.tracks.length; i++)
        if (i != audio.currentIndex) i,
    ];

    return Material(
      color: AppColors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppColors.cardBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Up Next',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                Text(
                  '${upcoming.length} tracks',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF77717F),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (var n = 0; n < upcoming.length; n++) ...[
              if (n > 0)
                Divider(
                  height: 1,
                  thickness: 1,
                  color: Colors.white.withValues(alpha: 0.045),
                ),
              _QueueRow(number: n + 1, index: upcoming[n]),
            ],
          ],
        ),
      ),
    );
  }
}

class _QueueRow extends StatelessWidget {
  const _QueueRow({required this.number, required this.index});
  final int number;
  final int index;

  @override
  Widget build(BuildContext context) {
    final audio = context.read<AudioService>();
    final track = audio.tracks[index];
    final duration = audio.durationOf(index);

    return Semantics(
      label: 'Play ${track.title} by ${track.artist}',
      button: true,
      child: InkWell(
        onTap: () => audio.playIndex(index),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: track.artGradient,
                ),
                child: Text(
                  '$number',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      track.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFE9E4ED),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      track.artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF817B89),
                      ),
                    ),
                  ],
                ),
              ),
              if (duration != null) ...[
                const SizedBox(width: 12),
                Text(
                  formatTime(duration),
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textFaint,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
              const SizedBox(width: 12),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < 3; i++) ...[
                    if (i > 0) const SizedBox(height: 3),
                    Container(
                      width: 12,
                      height: 1,
                      color: const Color(0xFF65606C),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
