import 'package:bloc/bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';

part 'privacy_state.dart';

class PrivacyCubit extends Cubit<PrivacyState> {
  PrivacyCubit() : super(PrivacyState.initial()) {
    _load();
  }

  final Box _settings = Hive.box('SETTINGS');
  final Box _songHistory = Hive.box('SONG_HISTORY');
  final Box _searchHistory = Hive.box('SEARCH_HISTORY');

  void _load() {
    emit(
      state.copyWith(
        playbackHistory: _settings.get('PLAYBACK_HISTORY', defaultValue: true),
        searchHistory: _settings.get('SEARCH_HISTORY', defaultValue: true),
      ),
    );
  }

  Future<void> togglePlaybackHistory(bool value) async {
    await _settings.put('PLAYBACK_HISTORY', value);
    emit(state.copyWith(playbackHistory: value));
  }

  Future<void> toggleSearchHistory(bool value) async {
    await _settings.put('SEARCH_HISTORY', value);
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
