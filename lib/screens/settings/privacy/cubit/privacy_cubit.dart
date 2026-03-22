import 'package:bloc/bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:gyawun/services/settings_manager.dart';

import '../../../../services/history_manager.dart';

part 'privacy_state.dart';

class PrivacyCubit extends Cubit<PrivacyState> {
  late final SettingsManager _settingsManager;
  late final HistoryManager _historyManager;

  PrivacyCubit() : super(PrivacyState.initial()) {
    _settingsManager = GetIt.I<SettingsManager>();
    _historyManager = GetIt.I<HistoryManager>();
    _load();
  }

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
    await _historyManager.songs.clear();
    emit(state.copyWith(lastAction: PrivacyAction.playbackDeleted));
  }

  Future<void> clearSearchHistory() async {
    await _historyManager.searches.clear();
    emit(state.copyWith(lastAction: PrivacyAction.searchDeleted));
  }

  void consumeAction() {
    emit(state.copyWith(lastAction: null));
  }
}
