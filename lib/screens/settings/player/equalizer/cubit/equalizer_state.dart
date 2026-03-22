import 'package:flutter/foundation.dart';

@immutable
class EqualizerState {
  const EqualizerState();
}

class EqualizerLoading extends EqualizerState {
  const EqualizerLoading();
}

class EqualizerLoaded extends EqualizerState {
  final bool enabled;
  final double minDb;
  final double maxDb;
  final List bands;

  const EqualizerLoaded({
    required this.enabled,
    required this.minDb,
    required this.maxDb,
    required this.bands,
  });
}
