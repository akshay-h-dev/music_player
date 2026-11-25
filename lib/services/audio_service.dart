import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:audio_session/audio_session.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:metatagger/metatagger.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/track.dart';

class PositionData {
  const PositionData(this.position, this.duration);
  final Duration position;
  final Duration duration;
}

/// Owns the AudioPlayer and the Android equalizer effect. Widgets never talk
/// to just_audio directly.
class AudioService extends ChangeNotifier {
  AudioService({required List<Track> tracks})
    : _tracks = List<Track>.of(tracks) {
    player = AudioPlayer(
      audioPipeline: AudioPipeline(androidAudioEffects: [equalizer]),
    );
  }

  static const _savedSongsKey = 'saved_local_song_paths';
  final List<Track> _tracks;
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
  List<Track> get tracks => List<Track>.unmodifiable(_tracks);
  Track get currentTrack => _tracks.isEmpty
      ? const Track(
          title: 'No tracks',
          artist: '',
          gradient: [Color(0xFF4B3971), Color(0xFF17121F), Color(0xFF332363)],
        )
      : _tracks[_index.clamp(0, _tracks.length - 1).toInt()];
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
          _index = _tracks.isEmpty ? 0 : i.clamp(0, _tracks.length - 1).toInt();
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

    await _restoreSavedSongs();

    try {
      // LoopMode.all = when a track ends, continue with the next one
      // (and wrap around after the last).
      await player.setLoopMode(LoopMode.all);
      await player.setAudioSources([
        for (final t in _tracks)
          if (t.isLocal)
            AudioSource.uri(Uri.file(t.filePath!))
          else
            AudioSource.asset(t.assetPath!),
      ]);
      _ready = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Loading tracks failed: $e');
      final localTracks = _tracks.where((t) => t.isLocal).toList();
      if (localTracks.isNotEmpty) {
        try {
          await player.setAudioSources([
            for (final t in localTracks) AudioSource.uri(Uri.file(t.filePath!)),
          ]);
          _tracks
            ..clear()
            ..addAll(localTracks);
          _index = 0;
          _ready = true;
          notifyListeners();
        } catch (_) {
          _reportError();
        }
      } else {
        _reportError();
      }
    }

    unawaited(_loadDurations(0));
  }

  Future<void> _restoreSavedSongs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final paths = prefs.getStringList(_savedSongsKey) ?? const <String>[];
      for (final path in paths) {
        if (_disposed) return;
        final file = File(path);
        if (!await file.exists()) continue;
        final title = _titleFromFileName(file.uri.pathSegments.last);
        if (_tracks.any((t) => t.isLocal && t.filePath == path)) continue;
        _tracks.add(
          await _readLocalTrackMetadata(path: path, fallbackTitle: title),
        );
      }
    } catch (e) {
      debugPrint('Restoring songs failed: $e');
    }
  }

  /// Reads each track's length once so "Up Next" can show durations.
  Future<void> _loadDurations(int startIndex) async {
    for (var i = startIndex; i < _tracks.length; i++) {
      if (_disposed) return;
      final probe = AudioPlayer();
      try {
        final track = _tracks[i];
        final Duration? d = track.isLocal
            ? await probe.setFilePath(track.filePath!)
            : await probe.setAsset(track.assetPath!);
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

  String _titleFromFileName(String fileName) {
    final dot = fileName.lastIndexOf('.');
    final base = dot > 0 ? fileName.substring(0, dot) : fileName;
    return base.replaceAll(RegExp(r'[_-]+'), ' ').trim();
  }

  Future<Track> _readLocalTrackMetadata({
    required String path,
    required String fallbackTitle,
  }) async {
    var title = fallbackTitle;
    var artist = 'Unknown artist';
    Uint8List? artworkBytes;
    List<Color>? artworkGradient;

    try {
      final tags = await MetaTagger().readCommonTags(path);
      final taggedTitle = tags[CommonTags.title];
      final taggedArtist = tags[CommonTags.artist];
      if (taggedTitle is String && taggedTitle.trim().isNotEmpty) {
        title = taggedTitle.trim();
      }
      if (taggedArtist is String && taggedArtist.trim().isNotEmpty) {
        artist = taggedArtist.trim();
      }
      final taggedArtwork = tags[CommonTags.albumArt];
      if (taggedArtwork is Uint8List && taggedArtwork.isNotEmpty) {
        artworkBytes = taggedArtwork;
        try {
          final palette = await PaletteGenerator.fromImageProvider(
            MemoryImage(taggedArtwork),
            size: const Size(160, 160),
            maximumColorCount: 12,
          ).timeout(const Duration(seconds: 5));
          final dominantColors = palette.colors.take(3).toList();
          if (dominantColors.isNotEmpty) {
            final primary = _darkenColor(dominantColors.first, 0.28);
            final secondary = dominantColors.length > 1
                ? _darkenColor(dominantColors[1], 0.42)
                : primary.withValues(alpha: 0.85);
            final tertiary = dominantColors.length > 2
                ? _darkenColor(dominantColors[2], 0.50)
                : const Color(0xFF17121F);
            artworkGradient = [primary, secondary, tertiary];
          }
        } catch (_) {
          // Keep the deterministic fallback gradient.
        }
      }
    } catch (_) {
      // The filename fallback remains valid if metadata cannot be read.
    }

    return Track.fromLocalFile(
      title: title,
      artist: artist,
      filePath: path,
      artworkBytes: artworkBytes,
      gradient: artworkGradient,
    );
  }

  Color _darkenColor(Color color, double amount) {
    return Color.fromARGB(
      255,
      (color.r * 255 * (1 - amount)).round().clamp(0, 255).toInt(),
      (color.g * 255 * (1 - amount)).round().clamp(0, 255).toInt(),
      (color.b * 255 * (1 - amount)).round().clamp(0, 255).toInt(),
    );
  }

  Future<void> _persistSavedSongs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_savedSongsKey, [
        for (final track in _tracks)
          if (track.isLocal) track.filePath!,
      ]);
    } catch (e) {
      debugPrint('Saving songs failed: $e');
    }
  }

  Future<int> addSongsFromDevice() async {
    if (_disposed) return 0;

    final pickedFiles = await FilePicker.pickFiles(type: FileType.audio);
    if (pickedFiles.isEmpty) return 0;

    Directory? songsDirectory;
    try {
      final documents = await getApplicationDocumentsDirectory();
      songsDirectory = Directory(
        '${documents.path}${Platform.pathSeparator}songs',
      );
      await songsDirectory.create(recursive: true);
    } catch (e) {
      debugPrint('Creating songs directory failed: $e');
      _reportError();
      return 0;
    }

    final addedTracks = <Track>[];
    final addedSources = <AudioSource>[];

    for (final picked in pickedFiles) {
      try {
        final sourcePath = picked.path;
        if (sourcePath == null) {
          _reportError();
          continue;
        }

        final destination = File(
          '${songsDirectory.path}${Platform.pathSeparator}${picked.name}',
        );
        if (await destination.exists()) continue;
        if (_tracks.any(
          (track) => track.isLocal && track.filePath == destination.path,
        )) {
          continue;
        }

        await File(sourcePath).copy(destination.path);
        final fallbackTitle = _titleFromFileName(picked.name);
        final track = await _readLocalTrackMetadata(
          path: destination.path,
          fallbackTitle: fallbackTitle,
        );

        final probe = AudioPlayer();
        Duration? duration;
        try {
          duration = await probe
              .setFilePath(destination.path)
              .timeout(const Duration(seconds: 8));
        } finally {
          await probe.dispose();
        }
        if (duration == null) {
          await destination.delete();
          _reportError();
          continue;
        }

        addedTracks.add(track);
        addedSources.add(AudioSource.uri(Uri.file(destination.path)));
      } catch (e) {
        debugPrint('Loading picked song failed: $e');
        _reportError();
      }
    }

    if (addedTracks.isEmpty) return 0;

    try {
      if (!_ready || _tracks.isEmpty) {
        final localTracks = [
          ..._tracks.where((track) => track.isLocal),
          ...addedTracks,
        ];
        await player.setAudioSources([
          for (final track in localTracks)
            AudioSource.uri(Uri.file(track.filePath!)),
        ]);
        _tracks
          ..clear()
          ..addAll(localTracks);
        _index = 0;
        _ready = true;
      } else {
        await player.addAudioSources(addedSources);
        final startIndex = _tracks.length;
        _tracks.addAll(addedTracks);
        for (var i = 0; i < addedTracks.length; i++) {
          // Duration probing is repeated only for these newly added tracks.
          unawaited(_loadDuration(startIndex + i));
        }
      }

      await _persistSavedSongs();
      notifyListeners();
      return addedTracks.length;
    } catch (e) {
      debugPrint('Adding songs to playlist failed: $e');
      _reportError();
      return 0;
    }
  }

  Future<void> _loadDuration(int index) async {
    if (index >= _tracks.length || _disposed) return;
    final track = _tracks[index];
    if (!track.isLocal) return;
    final probe = AudioPlayer();
    try {
      final duration = await probe.setFilePath(track.filePath!);
      if (duration != null && !_disposed) {
        _durations[index] = duration;
        notifyListeners();
      }
    } catch (_) {
      // Ignore: the row just won't show a duration.
    } finally {
      await probe.dispose();
    }
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
