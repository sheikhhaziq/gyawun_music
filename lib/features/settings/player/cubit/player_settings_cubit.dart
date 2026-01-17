import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';

import '../../../../../../services/media_player.dart';
import '../../../../../../services/settings_manager.dart';

part 'player_settings_state.dart';

class PlayerSettingsCubit extends Cubit<PlayerSettingsState> {
  final SettingsManager _settings = GetIt.I<SettingsManager>();
  final MediaPlayer _player = GetIt.I<MediaPlayer>();

  late final VoidCallback _listener;

  PlayerSettingsCubit()
      : super(
          PlayerSettingsLoaded(
            skipSilence: GetIt.I<SettingsManager>().skipSilence,
          ),
        ) {
    _listener = () {
      if (!isClosed) {
        _emitState();
      }
    };

    _settings.addListener(_listener);
  }

  void _emitState() {
    if (isClosed) return;

    emit(
      PlayerSettingsLoaded(
        skipSilence: _settings.skipSilence,
      ),
    );
  }

  Future<void> setSkipSilence(bool value) async {
    await _player.skipSilence(value);
    _settings.skipSilence = value;
    // listener will re-emit
  }

  @override
  Future<void> close() {
    _settings.removeListener(_listener);
    return super.close();
  }
}
