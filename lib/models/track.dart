import 'package:flutter/material.dart';

/// A bundled audio track plus the gradient used as its artwork.
class Track {
  const Track({
    required this.title,
    required this.artist,
    required this.assetPath,
    required this.gradient,
    this.stops,
  });

  final String title;
  final String artist;
  final String assetPath;
  final List<Color> gradient;
  final List<double>? stops;

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
