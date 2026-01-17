import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../../../../services/settings_manager.dart';
import '../../../../../../ytmusic/ytmusic.dart';

part 'ytmusic_state.dart';

class YTMusicCubit extends Cubit<YTMusicState> {
  final SettingsManager _settings = GetIt.I<SettingsManager>();
  final YTMusic _ytmusic = GetIt.I<YTMusic>();
  final Box _box = Hive.box('SETTINGS');

  List<Map<String, String>> get locations => _settings.locations;
  List<Map<String, String>> get languages => _settings.languages;

  List<AudioQuality> get audioQualities => _settings.audioQualities;

  late final VoidCallback _settingsListener;
  late final VoidCallback _hiveListener;

  YTMusicCubit()
      : super(
          YTMusicState(
            location: GetIt.I<SettingsManager>().location,
            language: GetIt.I<SettingsManager>().language,
            autofetchSongs: GetIt.I<SettingsManager>().autofetchSongs,
            streamingQuality: GetIt.I<SettingsManager>().streamingQuality,
            downloadQuality: GetIt.I<SettingsManager>().downloadQuality,
            translateLyrics: Hive.box('SETTINGS')
                .get('TRANSLATE_LYRICS', defaultValue: false),
            personalisedContent: Hive.box('SETTINGS')
                .get('PERSONALISED_CONTENT', defaultValue: true),
            visitorId: Hive.box('SETTINGS').get('VISITOR_ID', defaultValue: ''),
          ),
        ) {
    _settingsListener = _emit;
    _hiveListener = _emit;

    _settings.addListener(_settingsListener);
    _box.listenable().addListener(_hiveListener);
  }

  void _emit() {
    if (isClosed) return;

    emit(
      state.copyWith(
        location: _settings.location,
        language: _settings.language,
        autofetchSongs: _settings.autofetchSongs,
        streamingQuality: _settings.streamingQuality,
        downloadQuality: _settings.downloadQuality,
        translateLyrics: _box.get('TRANSLATE_LYRICS', defaultValue: false),
        personalisedContent:
            _box.get('PERSONALISED_CONTENT', defaultValue: true),
        visitorId: _box.get('VISITOR_ID', defaultValue: ''),
      ),
    );
  }

  void setLocation(Map<String, String> location) {
    _settings.location = location;
  }

  void setLanguage(Map<String, String> language) {
    _settings.language = language;
  }

  void setAutofetchSongs(bool value) {
    _settings.autofetchSongs = value;
  }

  void setStreamingQuality(dynamic quality) {
    _settings.streamingQuality = quality;
  }

  void setDownloadQuality(dynamic quality) {
    _settings.downloadQuality = quality;
  }

  Future<void> setTranslateLyrics(bool value) async {
    await _box.put('TRANSLATE_LYRICS', value);
  }

  Future<void> setPersonalisedContent(bool value) async {
    await _box.put('PERSONALISED_CONTENT', value);
    await _ytmusic.resetVisitorId();
  }

  Future<void> setVisitorId(String id) async {
    await _box.put('VISITOR_ID', id);
    _ytmusic.refreshHeaders();
  }

  Future<void> resetVisitorId() async {
    await _ytmusic.resetVisitorId();
  }

  @override
  Future<void> close() {
    _settings.removeListener(_settingsListener);
    _box.listenable().removeListener(_hiveListener);
    return super.close();
  }
}
