import 'dart:collection';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:gyawun/ytmusic/ytmusic.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import 'file_storage.dart';
import 'settings_manager.dart';
import 'stream_client.dart';

Box _box = Hive.box('DOWNLOADS');
YoutubeExplode ytExplode = YoutubeExplode();

class DownloadManager {
  Client client = Client();
  ValueNotifier<List<Map>> downloads = ValueNotifier([]);
  final int maxConcurrentDownloads = 3; // Limit concurrent downloads
  int _activeDownloads = 0;
  final Queue<Map> _downloadQueue = Queue<Map>(); // Queue for pending downloads

  DownloadManager() {
    downloads.value = _box.values.toList().cast<Map>();
    _box.listenable().addListener(() {
      downloads.value = _box.values.toList().cast<Map>();
    });
  }

  Future<void> downloadSong(Map song) async {
    if (_activeDownloads >= maxConcurrentDownloads) {
      _downloadQueue.add(song); // Add to queue if limit reached
      return;
    }

    _activeDownloads++;
    try {
      if (!(await FileStorage.requestPermissions())) return;

      AudioOnlyStreamInfo audioSource = await _getSongInfo(song['videoId'],
          quality:
              GetIt.I<SettingsManager>().downloadQuality.name.toLowerCase());
      int start = 0;
      int end = audioSource.size.totalBytes;

      Stream<List<int>> stream = AudioStreamClient()
          .getAudioStream(audioSource, start: start, end: end);
      int total = audioSource.size.totalBytes;
      List<int> received = [];
      await _box.put(song['videoId'], {
        ...song,
        'status': 'PROCESSING',
        'progress': 0,
      });
      stream.listen(
        (data) async {
          received.addAll(data);
          await _box.put(song['videoId'], {
            ...song,
            'status': 'DOWNLOADING',
            'progress': (received.length / total) * 100,
          });
        },
        onDone: () async {
          if (received.length == total) {
            File? file = await GetIt.I<FileStorage>().saveMusic(received, song);
            if (file != null) {
              await _box.put(song['videoId'], {
                ...song,
                'status': 'DOWNLOADED',
                'progress': 100,
                'path': file.path,
                'timestamp': DateTime.now().millisecondsSinceEpoch
              });
            } else {
              await _box.delete(song['videoId']);
            }
          }
          _downloadNext(); // Trigger next download
        },
        onError: (err) async {
          await _box.delete(song['videoId']);
          print(err);
          _downloadNext(); // Trigger next download
        },
      );
    } catch (e) {
      await _box.delete(song['videoId']); // Handle errors by removing entry
    } finally {
      _activeDownloads--;
    }
  }

  void _downloadNext() {
    if (_downloadQueue.isNotEmpty &&
        _activeDownloads < maxConcurrentDownloads) {
      downloadSong(_downloadQueue.removeFirst());
    }
  }

  Future<String> deleteSong(String key, String path) async {
    await _box.delete(key);
    await File(path).delete();
    return 'Song deleted successfully.';
  }

  updateStatus(String key, String status) {
    Map? song = _box.get(key);
    if (song != null) {
      song['status'] = status;
      _box.put(key, song);
    }
  }

  Future<void> downloadPlaylist(Map playlist) async {
    List songs =
        await GetIt.I<YTMusic>().getPlaylistSongs(playlist['playlistId']);
    for (Map song in songs) {
      await downloadSong(song); // Queue each song download
    }
  }

  Future<AudioOnlyStreamInfo> _getSongInfo(String videoId,
      {String quality = 'high'}) async {
    try {
      StreamManifest manifest = await ytExplode.videos.streamsClient
          .getManifest(videoId,
              requireWatchPage: true, ytClients: [YoutubeApiClient.androidVr]);
      List<AudioOnlyStreamInfo> streamInfos = manifest.audioOnly
          .where((a) => a.container == StreamContainer.mp4)
          .sortByBitrate()
          .reversed
          .toList();
      return quality == 'low' ? streamInfos.first : streamInfos.last;
    } catch (e) {
      rethrow;
    }
  }
}
