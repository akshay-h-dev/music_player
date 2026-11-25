import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';

import '../models/track.dart';

class PositionData {
  const PositionData(this.position, this.duration);
  final Duration position;
  final Duration duration;
}

/// Owns the AudioPlayer and the Android equalizer effect. Widgets never talk
/// to just_audio directly.
class AudioService extends ChangeNotifier {
  AudioService({required this.tracks}) {
    player = AudioPlayer(
      audioPipeline: AudioPipeline(androidAudioEffects: [equalizer]),
    );
  }

  final List<Track> tracks;
  final AndroidEqualizer equalizer = AndroidEqualizer();
  late final AudioPlayer player;

  final _errors = StreamController<String>.broadcast();
  final _subs = <StreamSubscription<dynamic>>[];
  final _durations = <int, Duration>{};

  int _index = 0;
  bool _playing = false;
  bool _shuffle = false;
  bool _repeat = false;
  bool _ready = false;
  bool _disposed = false;

  /// Emits a user-facing message whenever loading/playback fails.
  Stream<String> get errors => _errors.stream;

  late final Stream<PositionData> positionData =
      Rx.combineLatest2<Duration, Duration?, PositionData>(
        player.positionStream,
        player.durationStream,
        (p, d) => PositionData(p, d ?? Duration.zero),
      ).asBroadcastStream();

  bool get isReady => _ready;
  bool get isPlaying => _playing;
  bool get shuffleEnabled => _shuffle;
  bool get repeatEnabled => _repeat;
  int get currentIndex => _index;
  Track get currentTrack => tracks[_index];
  Duration? durationOf(int index) => _durations[index];

  Future<void> init() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
    } catch (e) {
      debugPrint('Audio session setup failed: $e');
    }

    _subs.add(
      player.currentIndexStream.listen((i) {
        if (i != null && i != _index) {
          _index = i;
          notifyListeners();
        }
      }),
    );
    _subs.add(
      player.playingStream.listen((p) {
        _playing = p;
        notifyListeners();
      }),
    );
    _subs.add(
      player.playbackEventStream.listen(
        (_) {},
        onError: (Object e, StackTrace st) => _reportError(),
      ),
    );

    try {
      // LoopMode.all = when a track ends, continue with the next one
      // (and wrap around after the last).
      await player.setLoopMode(LoopMode.all);
      await player.setAudioSources([
        for (final t in tracks) AudioSource.asset(t.assetPath),
      ]);
      _ready = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Loading tracks failed: $e');
      _reportError();
    }

    unawaited(_loadDurations());
  }

  /// Reads each track's length once so "Up Next" can show durations.
  Future<void> _loadDurations() async {
    for (var i = 0; i < tracks.length; i++) {
      if (_disposed) return;
      final probe = AudioPlayer();
      try {
        final d = await probe.setAsset(tracks[i].assetPath);
        if (d != null && !_disposed) {
          _durations[i] = d;
          notifyListeners();
        }
      } catch (_) {
        // Ignore: the row just won't show a duration.
      } finally {
        await probe.dispose();
      }
    }
  }

  void _reportError() {
    if (!_errors.isClosed) _errors.add("Couldn't load track");
  }

  // ---- Transport -----------------------------------------------------------

  void play() => unawaited(player.play());
  Future<void> pause() => player.pause();
  void togglePlay() => _playing ? unawaited(pause()) : play();
  Future<void> seek(Duration position) => player.seek(position);

  Future<void> next() => _skip(player.seekToNext);

  /// Restarts the track if more than 3 s in, otherwise goes to the previous one.
  Future<void> previous() {
    if (player.position > const Duration(seconds: 3)) {
      return player.seek(Duration.zero);
    }
    return _skip(player.seekToPrevious);
  }

  /// With LoopMode.one just_audio's next/previous stay on the same track,
  /// so briefly switch to LoopMode.all to actually skip.
  Future<void> _skip(Future<void> Function() action) async {
    if (_repeat) await player.setLoopMode(LoopMode.all);
    await action();
    if (_repeat) await player.setLoopMode(LoopMode.one);
  }

  Future<void> playIndex(int index) async {
    await player.seek(Duration.zero, index: index);
    play();
  }

  Future<void> toggleShuffle() async {
    final enable = !_shuffle;
    if (enable) await player.shuffle();
    await player.setShuffleModeEnabled(enable);
    _shuffle = enable;
    notifyListeners();
  }

  Future<void> toggleRepeat() async {
    _repeat = !_repeat;
    await player.setLoopMode(_repeat ? LoopMode.one : LoopMode.all);
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    for (final s in _subs) {
      s.cancel();
    }
    _errors.close();
    player.dispose();
    super.dispose();
  }
}
