import 'package:flutter/foundation.dart';

@immutable
class EqBand {
  final int index;
  final double centerFrequency; // Hz (double is correct)
  final double gain;

  const EqBand({
    required this.index,
    required this.centerFrequency,
    required this.gain,
  });

  EqBand copyWith({double? gain}) {
    return EqBand(
      index: index,
      centerFrequency: centerFrequency,
      gain: gain ?? this.gain,
    );
  }
}

@immutable
class EqualizerState {
  final bool enabled;
  final double minDb;
  final double maxDb;
  final List<EqBand> bands;

  const EqualizerState({
    required this.enabled,
    required this.minDb,
    required this.maxDb,
    required this.bands,
  });

  EqualizerState copyWith({
    bool? enabled,
    List<EqBand>? bands,
  }) {
    return EqualizerState(
      enabled: enabled ?? this.enabled,
      minDb: minDb,
      maxDb: maxDb,
      bands: bands ?? this.bands,
    );
  }
}
