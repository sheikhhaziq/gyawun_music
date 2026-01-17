import 'package:bloc/bloc.dart';
import 'loudness_state.dart';

class LoudnessCubit extends Cubit<LoudnessState> {
  LoudnessCubit({
    required bool enabled,
    required double targetGain,
  }) : super(
          LoudnessState(
            enabled: enabled,
            targetGain: targetGain,
          ),
        );

  void toggle(bool enabled) {
    emit(state.copyWith(enabled: enabled));
  }

  void setTargetGain(double gain) {
    emit(state.copyWith(targetGain: gain));
  }
}
