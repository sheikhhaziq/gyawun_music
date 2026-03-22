import 'package:bloc/bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:gyawun/services/media_player.dart';
import 'package:gyawun/services/settings_manager.dart';
import 'equalizer_state.dart';

class EqualizerCubit extends Cubit<EqualizerState> {
  final MediaPlayer _mediaPlayer = GetIt.I<MediaPlayer>();

  EqualizerCubit() : super(EqualizerLoading()) {
    _getEqualizerParameters();
  }

  Future<void> _getEqualizerParameters() async {
    if (isClosed) return;
    final parameters = await _mediaPlayer.getEqualizerParameters();
    emit(
      EqualizerLoaded(
        enabled: GetIt.I<SettingsManager>().equalizerEnabled,
        maxDb: parameters['maxDecibels'],
        minDb: parameters['minDecibels'],
        bands: parameters['bands'],
      ),
    );
  }

  Future<void> toggle(bool enabled) async {
    if (state is EqualizerLoading) return;
    await _mediaPlayer.setEqualizerEnabled(enabled);
    _getEqualizerParameters();
  }

  Future<void> setBandGain(int index, double gain) async {
    if (state is EqualizerLoading) return;
    await _mediaPlayer.setEqualizerBandGain(index, gain);
    _getEqualizerParameters();
  }
}
