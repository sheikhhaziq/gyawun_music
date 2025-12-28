import 'dart:collection';
import 'package:collection/collection.dart';
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
  ValueNotifier<Map<String, Map>> downloaded = ValueNotifier({});
  static const String songsPlaylistId = 'songs';
  final int maxConcurrentDownloads = 3; // Limit concurrent downloads
  int _activeDownloads = 0;
  final Queue<Map> _downloadQueue = Queue<Map>(); // Queue for pending downloads

  DownloadManager() {
    _refreshData();
    _box.listenable().addListener(() {
      _refreshData();
    });
  }

  void _refreshData() {
    downloads.value = _box.values.toList().cast<Map>();
    Map<String, Map> playlists = {};
    for (Map song in downloads.value) {
      if (!['DOWNLOADED', 'DELETED'].contains(song['status'])) {
        continue;
      }
      final Map songPlaylists = song["playlists"];
      for (MapEntry entry in songPlaylists.entries) {
        String id = entry.key;
        String title = entry.value;
        playlists
            .putIfAbsent(
                id,
                () => {
                      "id": id,
                      "title": title,
                      "type": id == songsPlaylistId ? "SONGS" : "ALBUM",
                      "songs": [],
                    })['songs']
            .add({...song});
        if (playlists[id]!['type'] == "ALBUM" &&
            playlists[id]!['title'] != song["album"]?["name"]) {
          playlists[id]!['type'] = "PLAYLIST";
        }
      }
    }
    for (var playlist in playlists.values) {
      playlist['songs'].sort((a, b) =>
          (a['timestamp'] ?? 0).compareTo(b['timestamp'] ?? 0) as int);
    }
    if (!DeepCollectionEquality().equals(downloaded.value, playlists)) {
      downloaded.value = playlists;
    }
  }

  Future<void> restoreDownloads({List? songs}) async {
    final songsToRestore = songs ?? downloads.value;
    for (var song in songsToRestore) {
      if (_box.get(song['videoId']) != null) {
        if (song['path'] == null ||
            !(await File(song['path']).exists()) ||
            song['status'] != 'DOWNLOADED') {
          _downloadSong(song);
        }
      }
    }
  }

  Future<void> downloadSong(Map song) async {
    final Map? downloadSong = _box.get(song['videoId']);
    if (downloadSong != null) {
      final String? path = downloadSong['path'];
      if (path != null) {
        final file = File(path);
        final exists = await file.exists();
        if (exists) {
          // Song already downloaded, just update metadata
          await _updateSongMetadata(song['videoId'], {
            ...song,
            'status': 'DOWNLOADED',
            'progress': 100,
            'path': file.path,
            'playlists': song['playlists'] ?? {songsPlaylistId: 'Songs'},
          });
          return;
        }
      }
    }
    await _downloadSong(song);
  }

  Future<void> _downloadSong(Map song) async {
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
      await _updateSongMetadata(song['videoId'], {
        ...song,
        'status': 'PROCESSING',
        'progress': 0,
      });
      stream.listen(
        (data) async {
          received.addAll(data);
          await _updateSongMetadata(song['videoId'], {
            'status': 'DOWNLOADING',
            'progress': (received.length / total) * 100,
          });
        },
        onDone: () async {
          if (received.length == total) {
            File? file = await GetIt.I<FileStorage>().saveMusic(received, song);
            if (file != null) {
              await _updateSongMetadata(song['videoId'], {
                'status': 'DOWNLOADED',
                'progress': 100,
                'path': file.path,
                'playlists': song['playlists'] ?? {songsPlaylistId: 'Songs'},
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
          _downloadNext(); // Trigger next download
        },
      );
    } catch (e) {
      await deleteSong(
        key: song['videoId'],
        playlistId: song['playlists']?.keys.first ?? songsPlaylistId,
      );
    } finally {
      _activeDownloads--;
    }
  }

  Future<void> _updateSongMetadata(String key, Map newMetadata) async {
    Map? song = _box.get(key);
    if (song != null) {
      if (newMetadata.containsKey('playlists')) {
        song['playlists'] = {
          ...song['playlists'] ?? {},
          ...newMetadata['playlists'] as Map,
        };
        newMetadata.remove('playlists');
      }
      await _box.put(key, {
        ...song,
        ...newMetadata,
      });
    } else {
      await _box.put(key, newMetadata);
    }
  }

  void _downloadNext() {
    if (_downloadQueue.isNotEmpty &&
        _activeDownloads < maxConcurrentDownloads) {
      _downloadSong(_downloadQueue.removeFirst());
    }
  }

  Future<String> deleteSong({
    required String key,
    String playlistId = songsPlaylistId,
    String? path,
  }) async {
    Map? song = _box.get(key);
    if (song != null && song['playlists'].keys.contains(playlistId)) {
      song['playlists'].remove(playlistId);
      if (song['playlists'].isNotEmpty) {
        await _box.put(key, song);
      } else {
        await _box.delete(key);
        if (path != null) await File(path).delete();
      }
    }
    return 'Song deleted successfully.';
  }

  Future<void> updateStatus(String key, String status) async {
    Map? song = _box.get(key);
    if (song != null) {
      song['status'] = status;
      await _box.put(key, song);
    }
  }

  Future<void> downloadPlaylist(Map playlist) async {
    List songs = playlist['isPredefined'] == false
        ? playlist['songs']
        : playlist['type'] == 'ARTIST'
            ? await GetIt.I<YTMusic>()
                .getNextSongList(playlistId: playlist['playlistId'])
            : await GetIt.I<YTMusic>().getPlaylistSongs(playlist['playlistId']);
    for (Map song in songs) {
      await downloadSong({
        ...song,
        'playlists': {
          playlist['playlistId']: playlist['title'],
        },
      }); // Queue each song download
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
