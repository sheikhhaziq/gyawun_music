import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:yt_music/ytmusic.dart';

import '../services/download_manager.dart';
import '../services/settings_manager.dart';

Future<void> addHistory(Map song) async {
  if (GetIt.I<SettingsManager>().playbackHistory) {
    await addLocalHistory(song);
  }
  final downloadSong = GetIt.I<DownloadManager>().downloads[song['videoId']];
  if (GetIt.I<SettingsManager>().personalisedContent &&
      (downloadSong == null || downloadSong['status'] != 'DOWNLOADED')) {
    GetIt.I<YTMusic>().addYoutubeHistory(song['videoId']);
  }
}

Future<void> addLocalHistory(Map song) async {
  Box box = Hive.box('SONG_HISTORY');
  Map? oldState = box.get(song['videoId']);
  int timestamp = DateTime.now().millisecondsSinceEpoch;
  if (oldState != null) {
    await box.put(song['videoId'], {
      ...oldState,
      'plays': oldState['plays'] + 1,
      'updatedAt': timestamp,
    });
  } else {
    await box.put(song['videoId'], {
      ...song,
      'plays': 1,
      'CreatedAt': timestamp,
      'updatedAt': timestamp,
    });
  }
}
