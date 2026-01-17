part of 'player_settings_cubit.dart';

@immutable
sealed class PlayerSettingsState {
  const PlayerSettingsState();
}

class PlayerSettingsLoaded extends PlayerSettingsState {
  final bool skipSilence;

  const PlayerSettingsLoaded({
    required this.skipSilence,
  });
}
