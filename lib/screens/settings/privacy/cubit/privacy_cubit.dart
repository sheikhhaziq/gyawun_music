import 'package:bloc/bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:gyawun/services/settings_manager.dart';
import 'package:hive_flutter/hive_flutter.dart';

part 'privacy_state.dart';

class PrivacyCubit extends Cubit<PrivacyState> {
  PrivacyCubit() : super(PrivacyState.initial()) {
    _load();
  }

  final SettingsManager _settingsManager = GetIt.I<SettingsManager>();
  final Box _songHistory = Hive.box('SONG_HISTORY');
  final Box _searchHistory = Hive.box('SEARCH_HISTORY');

  void _load() {
    emit(
      state.copyWith(
        playbackHistory: _settingsManager.playbackHistory,
        searchHistory: _settingsManager.searchHistory,
      ),
    );
  }

  Future<void> togglePlaybackHistory(bool value) async {
    _settingsManager.playbackHistory = value;
    emit(state.copyWith(playbackHistory: value));
  }

  Future<void> toggleSearchHistory(bool value) async {
    _settingsManager.searchHistory = value;
    emit(state.copyWith(searchHistory: value));
  }

  Future<void> clearPlaybackHistory() async {
    await _songHistory.clear();
    emit(state.copyWith(lastAction: PrivacyAction.playbackDeleted));
  }

  Future<void> clearSearchHistory() async {
    await _searchHistory.clear();
    emit(state.copyWith(lastAction: PrivacyAction.searchDeleted));
  }

  void consumeAction() {
    emit(state.copyWith(lastAction: null));
  }
}
