import 'package:bloc/bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:gyawun/services/media_player.dart';
import 'package:gyawun/services/settings_manager.dart';
import 'loudness_state.dart';

class LoudnessCubit extends Cubit<LoudnessState> {
  final MediaPlayer _mediaPlayer = GetIt.I<MediaPlayer>();

  LoudnessCubit()
    : super(
        LoudnessState(
          enabled: GetIt.I<SettingsManager>().loudnessEnabled,
          targetGain: GetIt.I<SettingsManager>().loudnessTargetGain,
        ),
      );

  Future<void> toggle(bool enabled) async {
    await _mediaPlayer.setLoudnessEnabled(enabled);
    emit(state.copyWith(enabled: enabled));
  }

  Future<void> setTargetGain(double gain) async {
    await _mediaPlayer.setLoudnessTargetGain(gain);
    emit(state.copyWith(targetGain: gain));
  }
}
