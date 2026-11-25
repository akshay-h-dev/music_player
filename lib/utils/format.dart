/// m:ss
String formatTime(Duration d) {
  final total = d.inSeconds;
  return '${total ~/ 60}:${(total % 60).toString().padLeft(2, '0')}';
}

/// "+3 dB", "0 dB", "-2 dB"
String formatDb(double v) {
  final r = v.round();
  return '${r > 0 ? '+' : ''}$r dB';
}
