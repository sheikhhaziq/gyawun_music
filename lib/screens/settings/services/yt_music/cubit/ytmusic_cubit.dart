import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:yt_music/client.dart';
import 'package:yt_music/ytmusic.dart';

import '../../../../../../services/settings_manager.dart';

part 'ytmusic_state.dart';

class YTMusicCubit extends Cubit<YTMusicState> {
  final SettingsManager _settingsManager = GetIt.I<SettingsManager>();
  final YTMusic _ytmusic = GetIt.I<YTMusic>();

  List<Map<String, String>> get locations => _settingsManager.locations;
  List<Map<String, String>> get languages => _settingsManager.languages;

  List<AudioQuality> get audioQualities => _settingsManager.audioQualities;

  late final VoidCallback _settingsListener;

  YTMusicCubit()
    : super(
        YTMusicState(
          location: GetIt.I<SettingsManager>().location,
          language: GetIt.I<SettingsManager>().language,
          autofetchSongs: GetIt.I<SettingsManager>().autofetchSongs,
          streamingQuality: GetIt.I<SettingsManager>().streamingQuality,
          downloadQuality: GetIt.I<SettingsManager>().downloadQuality,
          translateLyrics: GetIt.I<SettingsManager>().translateLyrics,
          personalisedContent: GetIt.I<SettingsManager>().personalisedContent,
          visitorId: GetIt.I<SettingsManager>().visitorId!,
        ),
      ) {
    _settingsListener = _emit;

    _settingsManager.addListener(_settingsListener);
  }

  void _emit() {
    if (isClosed) return;

    emit(
      state.copyWith(
        location: _settingsManager.location,
        language: _settingsManager.language,
        autofetchSongs: _settingsManager.autofetchSongs,
        streamingQuality: _settingsManager.streamingQuality,
        downloadQuality: _settingsManager.downloadQuality,
        translateLyrics: _settingsManager.translateLyrics,
        personalisedContent: _settingsManager.personalisedContent,
        visitorId: _settingsManager.visitorId,
      ),
    );
  }

  void setLocation(Map<String, String> location) {
    _settingsManager.location = location;
  }

  void setLanguage(Map<String, String> language) {
    _settingsManager.language = language;
  }

  void setAutofetchSongs(bool value) {
    _settingsManager.autofetchSongs = value;
  }

  void setStreamingQuality(AudioQuality quality) {
    _settingsManager.streamingQuality = quality;
  }

  void setDownloadQuality(AudioQuality quality) {
    _settingsManager.downloadQuality = quality;
  }

  Future<void> setTranslateLyrics(bool value) async {
    _settingsManager.translateLyrics = value;
  }

  Future<void> setPersonalisedContent(bool value) async {
    _settingsManager.personalisedContent = value;
    final config = await YTClient.getConfig();
    if (config != null) {
      _settingsManager.visitorId = config.visitorData;
    }
  }

  Future<void> setVisitorId(String id) async {
    _settingsManager.visitorId = id;
    _ytmusic.updateConfig(visitorData: id);
  }

  Future<void> resetVisitorId() async {
    final config = await YTClient.getConfig();
    if (config != null) {
      _settingsManager.visitorId = config.visitorData;
    }
  }

  @override
  Future<void> close() {
    _settingsManager.removeListener(_settingsListener);
    return super.close();
  }
}
