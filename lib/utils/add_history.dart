import 'package:get_it/get_it.dart';
import 'package:yt_music/ytmusic.dart';

import '../services/download_manager.dart';
import '../services/history_manager.dart';
import '../services/settings_manager.dart';

Future<void> addHistory(Map song) async {
  await GetIt.I<HistoryManager>().songs.add(song);
  final downloadSong = GetIt.I<DownloadManager>().getDownload(song['videoId']);
  if (GetIt.I<SettingsManager>().personalisedContent &&
      (downloadSong == null || downloadSong['status'] != 'DOWNLOADED')) {
    GetIt.I<YTMusic>().addYoutubeHistory(song['videoId']);
  }
}
