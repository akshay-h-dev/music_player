import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/audio_service.dart';
import '../theme.dart';
import '../widgets/album_art.dart';
import '../widgets/equalizer_icon.dart';
import '../widgets/playback_controls.dart';
import '../widgets/seek_bar.dart';
import '../widgets/up_next_list.dart';
import 'equalizer_screen.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  StreamSubscription<String>? _errorSub;

  @override
  void initState() {
    super.initState();
    _errorSub = context.read<AudioService>().errors.listen(_showError);
  }

  @override
  void dispose() {
    _errorSub?.cancel();
    super.dispose();
  }

  void _showError(String message) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final accent = context.appAccent;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning_amber_rounded, size: 20, color: accent.light),
              const SizedBox(width: 12),
              Expanded(child: Text(message)),
            ],
          ),
          action: SnackBarAction(label: 'DISMISS', onPressed: () {}),
        ),
      );
  }

  Future<void> _addSongs() async {
    final count = await context.read<AudioService>().addSongsFromDevice();
    if (!mounted || count == 0) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$count songs added')));
  }

  @override
  Widget build(BuildContext context) {
    final audio = context.watch<AudioService>();
    final track = audio.currentTrack;
    final height = MediaQuery.sizeOf(context).height;
    final compact = height < 760;
    final artworkSize = height < 640
        ? 160.0
        : compact
        ? 190.0
        : 248.0;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, compact ? 12 : 16, 20, 16),
          child: Column(
            children: [
              SizedBox(
                height: 40,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    const Text(
                      'Now Playing',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.18,
                      ),
                    ),

                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        tooltip: 'Open equalizer page',
                        color: AppColors.textSecondary,
                        icon: const EqualizerIcon(size: 22),
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const EqualizerScreen(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: compact ? 12 : 16),
              Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: artworkSize),
                  child: AlbumArt(track: track, playing: audio.isPlaying),
                ),
              ),
              SizedBox(height: compact ? 8 : 16),
              Text(
                track.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  height: 24 / 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                track.artist,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  height: 20 / 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              SeekBar(stream: audio.positionData, onSeek: audio.seek),
              const SizedBox(height: 8),
              const PlaybackControls(),
              const SizedBox(height: 12),
              Expanded(child: UpNextList(onAddSongs: _addSongs)),
            ],
          ),
        ),
      ),
    );
  }
}
