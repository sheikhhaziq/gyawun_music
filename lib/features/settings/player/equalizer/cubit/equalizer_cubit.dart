import 'package:bloc/bloc.dart';
import 'equalizer_state.dart';

class EqualizerCubit extends Cubit<EqualizerState> {
  EqualizerCubit({
    required bool enabled,
    required double minDb,
    required double maxDb,
    required List<EqBand> bands,
  }) : super(
          EqualizerState(
            enabled: enabled,
            minDb: minDb,
            maxDb: maxDb,
            bands: bands,
          ),
        );

  void toggle(bool enabled) {
    emit(state.copyWith(enabled: enabled));
  }

  void setBandGain(int index, double gain) {
    final updated = state.bands
        .map(
          (b) => b.index == index ? b.copyWith(gain: gain) : b,
        )
        .toList();

    emit(state.copyWith(bands: updated));
  }
}
