import 'package:flutter/material.dart';

import 'dart:typed_data';

/// A bundled audio track plus the gradient used as its artwork.
class Track {
  const Track({
    required this.title,
    required this.artist,
    required this.gradient,
    this.assetPath,
    this.filePath,
    this.artworkBytes,
    this.stops,
  });

  final String title;
  final String artist;
  final String? assetPath;
  final String? filePath;
  final Uint8List? artworkBytes;
  final List<Color> gradient;
  final List<double>? stops;
  bool get isLocal => filePath != null;
  Color get themeColor =>
      gradient.isNotEmpty ? gradient.first : const Color(0xFF7C4DFF);

  factory Track.fromLocalFile({
    required String title,
    required String filePath,
    String artist = 'Unknown artist',
    Uint8List? artworkBytes,
    List<Color>? gradient,
  }) {
    final seed = title.hashCode & 0x7fffffff;
    const palettes = <List<Color>>[
      [Color(0xFF4B3971), Color(0xFF17121F), Color(0xFF332363)],
      [Color(0xFF59428B), Color(0xFF1E1930), Color(0xFF29224A)],
      [Color(0xFF356273), Color(0xFF172327), Color(0xFF263E55)],
      [Color(0xFF703A59), Color(0xFF231923), Color(0xFF46334F)],
    ];
    final palette = gradient ?? palettes[seed % palettes.length];
    return Track(
      title: title,
      artist: artist,
      filePath: filePath,
      artworkBytes: artworkBytes,
      gradient: palette,
      stops: palette.length == 3 ? const [0, 0.54, 1] : null,
    );
  }

  /// ~145deg CSS gradient from the design.
  LinearGradient get artGradient => LinearGradient(
    begin: const Alignment(-0.57, -0.82),
    end: const Alignment(0.57, 0.82),
    colors: gradient,
    stops: stops,
  );
}

/// Put matching .mp3 files in assets/audio/ (or change the paths here).
const List<Track> kTracks = [
  Track(
    title: 'Midnight Echoes',
    artist: 'Nova Lane',
    assetPath: 'assets/audio/midnight_echoes.mp3',
    gradient: [Color(0xFF4B3971), Color(0xFF17121F), Color(0xFF332363)],
    stops: [0, 0.54, 1],
  ),
  Track(
    title: 'Neon Skyline',
    artist: 'Aria Vale',
    assetPath: 'assets/audio/neon_skyline.mp3',
    gradient: [Color(0xFF59428B), Color(0xFF1E1930)],
  ),
  Track(
    title: 'Slow Motion',
    artist: 'The Satellites',
    assetPath: 'assets/audio/slow_motion.mp3',
    gradient: [Color(0xFF703A59), Color(0xFF231923)],
  ),
  Track(
    title: 'Afterglow',
    artist: 'Mira Sol',
    assetPath: 'assets/audio/afterglow.mp3',
    gradient: [Color(0xFF356273), Color(0xFF172327)],
  ),
];
