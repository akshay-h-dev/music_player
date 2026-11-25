import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/audio_service.dart';
import '../theme.dart';

/// Shuffle, previous, play/pause, next, repeat.
class PlaybackControls extends StatelessWidget {
  const PlaybackControls({super.key});

  @override
  Widget build(BuildContext context) {
    final audio = context.watch<AudioService>();
    final accent = context.appAccent;
    return SizedBox(
      height: 72,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ModeButton(
              icon: Icons.shuffle_rounded,
              tooltip: 'Shuffle',
              active: audio.shuffleEnabled,
              onPressed: audio.toggleShuffle,
              accent: accent,
            ),
            const SizedBox(width: 12),
            _SkipButton(
              icon: Icons.skip_previous_rounded,
              tooltip: 'Previous track',
              onPressed: audio.previous,
            ),
            const SizedBox(width: 12),
            _PlayButton(playing: audio.isPlaying, onPressed: audio.togglePlay),
            const SizedBox(width: 12),
            _SkipButton(
              icon: Icons.skip_next_rounded,
              tooltip: 'Next track',
              onPressed: audio.next,
            ),
            const SizedBox(width: 12),
            _ModeButton(
              icon: Icons.repeat_rounded,
              tooltip: 'Repeat current track',
              active: audio.repeatEnabled,
              onPressed: audio.toggleRepeat,
              accent: accent,
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.icon,
    required this.tooltip,
    required this.active,
    required this.onPressed,
    required this.accent,
  });
  final IconData icon;
  final String tooltip;
  final bool active;
  final VoidCallback onPressed;
  final AppAccent accent;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      isSelected: active,
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      style: IconButton.styleFrom(
        fixedSize: const Size(34, 34),
        padding: EdgeInsets.zero,
        foregroundColor: active ? accent.soft : const Color(0xFF6F6976),
        backgroundColor: active
            ? accent.primary.withValues(alpha: 0.12)
            : Colors.transparent,
      ),
    );
  }
}

class _SkipButton extends StatelessWidget {
  const _SkipButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: 30),
      style: IconButton.styleFrom(
        fixedSize: const Size(48, 48),
        padding: EdgeInsets.zero,
        foregroundColor: const Color(0xFFD7D2DE),
      ),
    );
  }
}

class _PlayButton extends StatelessWidget {
  const _PlayButton({required this.playing, required this.onPressed});
  final bool playing;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final accent = context.appAccent;
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: accent.primary.withValues(alpha: 0.32),
            blurRadius: 28,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: accent.primary,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: SizedBox(
            width: 64,
            height: 64,
            child: Semantics(
              button: true,
              label: playing ? 'Pause' : 'Play',
              child: Icon(
                playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                size: 34,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
