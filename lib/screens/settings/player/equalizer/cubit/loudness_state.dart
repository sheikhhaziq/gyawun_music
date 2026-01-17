import 'package:flutter/foundation.dart';

@immutable
class LoudnessState {
  final bool enabled;
  final double targetGain;

  const LoudnessState({
    required this.enabled,
    required this.targetGain,
  });

  LoudnessState copyWith({
    bool? enabled,
    double? targetGain,
  }) {
    return LoudnessState(
      enabled: enabled ?? this.enabled,
      targetGain: targetGain ?? this.targetGain,
    );
  }
}
