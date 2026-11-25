import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../models/track.dart';
import '../theme.dart';

const _waveBars = <int>[
  18, 32, 52, 70, 42, 62, 88, 54, 76, 46, 68, //
  36, 58, 82, 48, 64, 30, 44, 72, 38, 56, 26,
];

/// Gradient artwork with glow, ring, and an animated wave strip.
class AlbumArt extends StatefulWidget {
  const AlbumArt({super.key, required this.track, required this.playing});
  final Track track;
  final bool playing;

  @override
  State<AlbumArt> createState() => _AlbumArtState();
}

class _AlbumArtState extends State<AlbumArt>
    with SingleTickerProviderStateMixin {
  // 0..2 over 1.5 s so each bar can run a triangle wave (like CSS "alternate").
  late final AnimationController _wave = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
    upperBound: 2,
  );

  @override
  void initState() {
    super.initState();
    if (widget.playing) _wave.repeat();
  }

  @override
  void didUpdateWidget(AlbumArt old) {
    super.didUpdateWidget(old);
    if (widget.playing && !_wave.isAnimating) {
      _wave.repeat();
    } else if (!widget.playing && _wave.isAnimating) {
      _wave.stop();
    }
  }

  @override
  void dispose() {
    _wave.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(24);
    return Semantics(
      label: 'Artwork for ${widget.track.title}',
      child: AspectRatio(
        aspectRatio: 1,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 50,
                offset: const Offset(0, 24),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: Stack(
              fit: StackFit.expand,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(gradient: widget.track.artGradient),
                ),
                // Soft highlight, top right.
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0.36, -0.52),
                      radius: 0.36,
                      colors: [
                        const Color(0xFFB9A0FF).withValues(alpha: 0.36),
                        const Color(0xFFB9A0FF).withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
                // Blurred glow, bottom left.
                Positioned(
                  left: -40,
                  bottom: -56,
                  width: 176,
                  height: 176,
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.accent.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                ),
                // Center ring + dot.
                Center(
                  child: FractionallySizedBox(
                    widthFactor: 0.44,
                    heightFactor: 0.44,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.035),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.10),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accent.withValues(alpha: 0.16),
                            blurRadius: 60,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFB9A4FF),
                    ),
                  ),
                ),
                // Wave strip.
                Positioned(
                  left: 18,
                  right: 18,
                  bottom: 18,
                  height: 35,
                  child: Semantics(
                    label: widget.playing ? 'Audio playing' : 'Audio paused',
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                        child: ColoredBox(
                          color: const Color(0xFF08070C).withValues(alpha: 0.5),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 7),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                for (var i = 0; i < _waveBars.length; i++) ...[
                                  if (i > 0) const SizedBox(width: 3),
                                  _WaveBar(
                                    animation: _wave,
                                    heightPct: _waveBars[i],
                                    index: i,
                                    playing: widget.playing,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WaveBar extends StatelessWidget {
  const _WaveBar({
    required this.animation,
    required this.heightPct,
    required this.index,
    required this.playing,
  });

  final Animation<double> animation;
  final int heightPct;
  final int index;
  final bool playing;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        var scale = 1.0;
        if (playing) {
          final x = (animation.value + (index % 7) * 0.11 / 0.75) % 2;
          final tri = x > 1 ? 2 - x : x;
          scale = 0.35 + 0.65 * Curves.easeInOut.transform(tri);
        }
        return Opacity(
          opacity: playing ? 1 : 0.75,
          child: Transform.scale(scaleY: scale, child: child),
        );
      },
      child: Container(
        width: 3,
        height: math.max(3, 21 * heightPct / 100),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(2),
          gradient: const LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [AppColors.accent, Color(0xFFC8B8FF)],
          ),
        ),
      ),
    );
  }
}
