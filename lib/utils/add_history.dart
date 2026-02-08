import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:yt_music/ytmusic.dart';

Box _box = Hive.box('SETTINGS');

Future<void> addHistory(Map song) async {
  if (_box.get('PLAYBACK_HISTORY', defaultValue: true)) {
    await addLocalHistory(song);
  }
  final downloadSong = Hive.box('DOWNLOADS').toMap()[song['videoId']];
  if (_box.get('PERSONALISED_CONTENT', defaultValue: true) &&
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
