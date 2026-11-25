import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

enum EqBand { low, mid, high }

extension EqBandLabel on EqBand {
  String get label => switch (this) {
    EqBand.low => 'Low',
    EqBand.mid => 'Mid',
    EqBand.high => 'High',
  };
}

/// Maps 3 UI sliders onto however many bands the device's equalizer has
/// (usually 5). Every device band gets the gain of the group it belongs to.
class EqService extends ChangeNotifier {
  EqService(this._equalizer);

  final AndroidEqualizer _equalizer;
  AndroidEqualizerParameters? _params;
  final Map<EqBand, double> _values = {for (final b in EqBand.values) b: 0};
  bool _initialized = false;

  static const double lowCutoffHz = 250;
  static const double highCutoffHz = 4000;
  static const double uiMin = -12;
  static const double uiMax = 12;

  bool get isInitialized => _initialized;
  bool get isAvailable => _params != null && _params!.bands.isNotEmpty;
  bool get isFlat => _values.values.every((v) => v == 0);
  double valueOf(EqBand band) => _values[band] ?? 0;

  /// Slider range: -12..+12 dB, narrowed if the device supports less.
  double get minDb =>
      _params == null ? uiMin : math.max(uiMin, _params!.minDecibels);
  double get maxDb =>
      _params == null ? uiMax : math.min(uiMax, _params!.maxDecibels);

  /// Which slider controls a band with this center frequency.
  static EqBand bandFor(double centerHz) {
    if (centerHz < lowCutoffHz) return EqBand.low;
    if (centerHz <= highCutoffHz) return EqBand.mid;
    return EqBand.high;
  }

  /// Device band indices per slider, e.g. [60, 230, 910, 3600, 14000] Hz ->
  /// low: [0, 1], mid: [2, 3], high: [4].
  static Map<EqBand, List<int>> groupBands(List<double> centerFrequencies) {
    final groups = {for (final b in EqBand.values) b: <int>[]};
    for (var i = 0; i < centerFrequencies.length; i++) {
      groups[bandFor(centerFrequencies[i])]!.add(i);
    }
    return groups;
  }

  /// Call after the audio source is loaded (the effect needs a live player).
  Future<void> init() async {
    try {
      await _equalizer.setEnabled(true);
      _params = await _equalizer.parameters.timeout(const Duration(seconds: 5));
      await _applyAll();
    } catch (e) {
      debugPrint('Equalizer unavailable: $e');
      _params = null;
    }
    _initialized = true;
    notifyListeners();
  }

  Future<void> setGain(EqBand band, double db) async {
    _values[band] = db.clamp(minDb, maxDb).toDouble();
    notifyListeners();
    await _applyBand(band);
  }

  Future<void> reset() async {
    for (final b in EqBand.values) {
      _values[b] = 0;
    }
    notifyListeners();
    await _applyAll();
  }

  Future<void> _applyAll() async {
    for (final b in EqBand.values) {
      await _applyBand(b);
    }
  }

  Future<void> _applyBand(EqBand band) async {
    final params = _params;
    if (params == null) return;
    final gain = valueOf(band)
        .clamp(params.minDecibels, params.maxDecibels)
        .toDouble();
    final groups = groupBands([
      for (final b in params.bands) b.centerFrequency,
    ]);
    for (final i in groups[band]!) {
      await params.bands[i].setGain(gain);
    }
  }
}
