import 'dart:collection';
import 'package:collection/collection.dart';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:yt_music/ytmusic.dart';

import 'file_storage.dart';
import 'settings_manager.dart';
import 'favourites_manager.dart';
import 'stream_client.dart';

YoutubeExplode ytExplode = YoutubeExplode();

class DownloadCanceledException implements Exception {}

class DownloadManager {
  final Box _box;
  Client client = Client();
  ValueNotifier<List<Map>> downloadsNotifier = ValueNotifier([]);
  ValueNotifier<Map<String, Map>> playlistsNotifier = ValueNotifier({});
  final Map<String, ValueNotifier<double>> _activeDownloadProgress = {};
  static const String songsPlaylistId = 'SNGS';
  final int maxConcurrentDownloads = 3; // Limit concurrent downloads
  final Queue<String> _activeDownloads =
      Queue<String>(); // Currently active downloads
  final Queue<Map> _downloadQueue = Queue<Map>(); // Queue for pending downloads

  Map get downloads => _box.toMap();

  Listenable songListenable(String songId) {
    return _box.listenable(keys: [songId]);
  }

  Map? getDownload(String songId) {
    return _box.get(songId);
  }

  Map getCleanSong(Map song) {
    final Map clean = Map.from(song);
    clean.remove('status');
    clean.remove('path');
    clean.remove('playlists');
    return clean;
  }

  List? getDownloadedSongs(String? playlistId) {
    List? allSongs;
    if (playlistId == null) {
      allSongs = downloadsNotifier.value;
    } else {
      allSongs = playlistsNotifier.value[playlistId]?["songs"];
    }
    return allSongs
        ?.where((s) => getDownload(s['videoId'])?['status'] == 'DOWNLOADED')
        .map((s) => getCleanSong(s))
        .toList();
  }

  DownloadManager._(this._box) {
    _cleanAndMigrateData();
    _refreshData();
    _box.listenable().addListener(() {
      _refreshData();
    });
  }

  Future<void> reInit() async {
    await _cleanAndMigrateData();
    await _refreshData();
  }

  static Future<DownloadManager> create() async {
    final boxName = 'DOWNLOADS';
    await Hive.openBox(boxName);
    final instance = DownloadManager._(Hive.box(boxName));
    return instance;
  }

  Future<void> _cleanAndMigrateData() async {
    final activeIds = _activeDownloads.toSet();
    final queuedIds = _downloadQueue.map((e) => e['videoId']).toSet();
    final mapToUpdate = <String, Map>{};

    for (final key in _box.keys) {
      final Map song = Map.from(_box.get(key) as Map);
      final id = song['videoId'] ?? key.toString();
      String status = song['status'] ?? '';

      // 1) CHECK INTERRUPTED DOWNLOADS
      final isInvalidDownloading =
          status == 'DOWNLOADING' && !activeIds.contains(id);
      final isInvalidQueued = status == 'QUEUED' && !queuedIds.contains(id);
      if (isInvalidDownloading || isInvalidQueued) {
        debugPrint("Cleaning up interrupted download: ${song['title']}");
        song['status'] = 'DELETED';
        mapToUpdate[key.toString()] = song;
      }

      // 2) MIGRATE OLD DOWNLOADS TO SONGS PLAYLIST
      if (song["playlists"] == null || song["playlists"] is! Map) {
        song["playlists"] = {
          songsPlaylistId: {
            "id": songsPlaylistId,
            "title": "Songs",
            "timestamp":
                song["downloadedAt"] ??
                song["timestamp"] ??
                DateTime.now().millisecondsSinceEpoch,
          },
        };
        mapToUpdate[key.toString()] = song;
      } else if (song["playlists"] is Map &&
          (song["playlists"] as Map).keys.contains("songs")) {
        // 2) RENAME OLD SONGS PLAYLIST
        final pl = song["playlists"].remove("songs");
        song["playlists"][songsPlaylistId] = pl;
        mapToUpdate[key.toString()] = song;
      }
    }
    // 1) UPDATE DOWNLOADS
    if (mapToUpdate.isNotEmpty) {
      await _box.putAll(mapToUpdate);
    }
  }

  Future<void> _refreshData() async {
    // 1) LOAD DOWNLOADS FROM HIVE
    downloadsNotifier.value = _box.values.toList().cast<Map>();

    // 2) BUILD PLAYLIST MAP
    final Map<String, Map<String, dynamic>> playlists = {};

    for (final song in downloadsNotifier.value) {
      final Map songPlaylists = Map.from(song["playlists"] ?? {});

      for (final entry in songPlaylists.entries) {
        final String id = entry.key;
        final value = entry.value;

        if (value is! Map) continue;

        final String title = value["title"] ?? "Unknown";

        playlists
            .putIfAbsent(
              id,
              () => {
                "id": id,
                "title": title,
                "type":
                    id == songsPlaylistId || id == FavouritesManager.playlistId
                    ? "PLAYLIST"
                    : "ALBUM",
                "songs": <Map<String, dynamic>>[],
              },
            )["songs"]
            .add(Map<String, dynamic>.from(song));

        // ALBUM → PLAYLIST upgrade logic (unchanged, but safe)
        if (playlists[id]!["type"] == "ALBUM" &&
            playlists[id]!["title"] != song["album"]?["name"]) {
          playlists[id]!["type"] = "PLAYLIST";
        }
      }
    }

    // 3) SORT SONGS INSIDE PLAYLISTS
    for (final playlist in playlists.values) {
      final String playlistId = playlist["id"];

      (playlist["songs"] as List).sort((a, b) {
        final aTs = a["playlists"]?[playlistId]?["timestamp"] ?? 0;
        final bTs = b["playlists"]?[playlistId]?["timestamp"] ?? 0;
        return aTs.compareTo(bTs);
      });
    }

    // 4) UPDATE STATE IF CHANGED
    if (!const DeepCollectionEquality().equals(
      playlistsNotifier.value,
      playlists,
    )) {
      playlistsNotifier.value = playlists;
    }
  }

  List<Map> getDownloadQueue() {
    return _downloadQueue.toList();
  }

  ValueNotifier<double>? getProgressNotifier(String videoId) {
    return _activeDownloadProgress[videoId];
  }

  void _startTrackingProgress(String videoId) {
    _activeDownloadProgress[videoId]?.dispose();
    _activeDownloadProgress[videoId] = ValueNotifier(0.0);
  }

  void _updateTrackingProgress(String videoId, double value) {
    _activeDownloadProgress[videoId]?.value = value;
  }

  void _stopTrackingProgress(String videoId) {
    if (_activeDownloadProgress.containsKey(videoId)) {
      _activeDownloadProgress[videoId]!.dispose();
      _activeDownloadProgress.remove(videoId);
    }
  }

  Future<void> restoreDownloads({List? songs}) async {
    final songsToRestore = songs ?? downloadsNotifier.value;
    for (var song in songsToRestore) {
      final storedSong = _box.get(song['videoId']);
      if (storedSong != null) {
        final status = storedSong['status'];
        final path = storedSong['path'];
        final isFileMissing =
            status == 'DOWNLOADED' &&
            (path == null || !(await File(path).exists()));
        final isDeleted = status == 'DELETED';
        if (isDeleted || isFileMissing) {
          downloadSong(storedSong);
        }
      }
    }
  }

  Future<void> setDownloads(Map downloads) async {
    await Future.forEach(downloads.entries, (entry) async {
      _box.put(entry.key, entry.value);
    });
  }

  Future<void> downloadSong(Map songToDownaload) async {
    // Added "songs" playlist if needed
    final Map song = {
      ...songToDownaload,
      'playlists':
          songToDownaload['playlists'] ??
          {
            songsPlaylistId: {
              'title': 'Songs',
              'timestamp': DateTime.now().millisecondsSinceEpoch,
            },
          },
    };
    // Check downloaded songs
    final Map? downloadSong = _box.get(song['videoId']);
    if (downloadSong != null) {
      final queueSong = _downloadQueue.firstWhereOrNull(
        (item) => item['videoId'] == song['videoId'],
      );
      if (_activeDownloads.contains(song['videoId']) || queueSong != null) {
        // Already downloading, just update metadata
        await _updateSongMetadata(song['videoId'], {...song});
        _downloadNext();
        return;
      } else {
        final String? path = downloadSong['path'];
        if (path != null) {
          final file = File(path);
          final exists = await file.exists();
          if (exists) {
            // Already downloaded, just update metadata
            await _updateSongMetadata(song['videoId'], {
              ...song,
              'status': 'DOWNLOADED',
            });
            _downloadNext();
            return;
          }
        }
      }
    }
    // Execute download process
    if (!await _downloadStart(song)) return;
    await _downloadSong(song);
    _downloadEnd(song);
    _downloadNext();
  }

  Future<void> _downloadSong(Map song) async {
    try {
      await _updateSongMetadata(song['videoId'], {
        ...song,
        'status': 'DOWNLOADING',
      });
      _startTrackingProgress(song['videoId']);

      if (!(await GetIt.I<FileStorage>().requestPermissions())) {
        throw Exception('Storage permissions not granted.');
      }

      AudioOnlyStreamInfo audioSource = await _getSongInfo(
        song['videoId'],
        quality: GetIt.I<SettingsManager>().downloadQuality.name.toLowerCase(),
      );

      _ensureActive(song);

      int total = audioSource.size.totalBytes;
      BytesBuilder received = BytesBuilder();

      Stream<List<int>> stream = AudioStreamClient().getAudioStream(
        audioSource,
        start: 0,
        end: total,
      );

      _ensureActive(song);

      await for (var data in stream) {
        _ensureActive(song);

        received.add(data);
        _updateTrackingProgress(song['videoId'], received.length / total);
      }

      File? file = await GetIt.I<FileStorage>().saveMusic(
        received.takeBytes(),
        song,
      );

      _ensureActive(song);

      if (file != null) {
        await _updateSongMetadata(song['videoId'], {
          'status': 'DOWNLOADED',
          'path': file.path,
        });
      } else {
        throw Exception("File saving failed");
      }
    } on DownloadCanceledException {
      debugPrint("Download cancelled by user: ${song['videoId']}");
    } catch (e) {
      debugPrint("Error in _downloadSong: $e");
      await _updateSongMetadata(song['videoId'], {'status': 'DELETED'});
    } finally {
      _stopTrackingProgress(song['videoId']);
    }
  }

  Future<void> _updateSongMetadata(String key, Map newMetadata) async {
    Map? song = _box.get(key);
    if (song != null) {
      if (newMetadata.containsKey('playlists')) {
        Map<String, dynamic> mergedPlaylists = {};
        if (song['playlists'] != null) {
          (song['playlists'] as Map).forEach((k, v) {
            mergedPlaylists[k] = Map<String, dynamic>.from(v);
          });
        }
        (newMetadata['playlists'] as Map).forEach((k, v) {
          mergedPlaylists[k] = Map<String, dynamic>.from(v);
        });
        song['playlists'] = mergedPlaylists;
        newMetadata.remove('playlists');
      }
      await _box.put(key, {...song, ...newMetadata});
    } else {
      await _box.put(key, newMetadata);
    }
  }

  Future<bool> _downloadStart(Map song) async {
    if (_activeDownloads.length >= maxConcurrentDownloads) {
      _downloadQueue.add(song);
      await _updateSongMetadata(song['videoId'], {...song, 'status': 'QUEUED'});
      return false;
    }
    _activeDownloads.add(song['videoId']);
    return true;
  }

  void _ensureActive(Map song) {
    if (!_activeDownloads.contains(song['videoId'])) {
      throw DownloadCanceledException();
    }
  }

  void _downloadEnd(Map song) {
    if (_activeDownloads.isNotEmpty) {
      _activeDownloads.remove(song['videoId']);
    }
  }

  void _downloadNext() {
    if (_downloadQueue.isNotEmpty &&
        _activeDownloads.length < maxConcurrentDownloads) {
      downloadSong(_downloadQueue.removeFirst());
    }
  }

  Future<void> _deleteSongInstance(Map song) async {
    // Remove Song from Queue
    if (song['status'] == "QUEUED") {
      _downloadQueue.removeWhere((item) => item['videoId'] == song['videoId']);
    }
    // Stop in-progress download
    else if (song['status'] == "DOWNLOADING") {
      _downloadEnd(song);
    }
    // Delete Song from box
    await _box.delete(song['videoId']);
    // Remove file if exists
    if (song['path'] != null && await File(song['path']).exists()) {
      await File(song['path']).delete();
    }
  }

  Future<String> deleteSong({
    required String key,
    String playlistId = songsPlaylistId,
  }) async {
    Map? song = _box.get(key);
    final Map playlists = song?['playlists'];
    if (song != null && (playlists.keys.contains(playlistId))) {
      song['playlists'].remove(playlistId);
      if (song['playlists'].isEmpty) {
        await _deleteSongInstance(song);
      } else {
        if (song['status'] == "QUEUED") {
          for (var item in _downloadQueue) {
            if (item['videoId'] == song['videoId']) {
              item['playlists'] = playlists;
              break;
            }
          }
        }
        await _box.put(key, song);
      }
    }
    return 'Song deleted successfully.';
  }

  Future<void> deleteAllSongs() async {
    List<Map> songs = _box.values.toList().cast<Map>();
    for (Map song in songs) {
      await _deleteSongInstance(song);
    }
  }

  Future<void> updateStatus(String key, String status) async {
    Map? song = _box.get(key);
    if (song != null) {
      song['status'] = status;
      await _box.put(key, song);
    }
  }

  Future<List> _getSongs({
    String? playlistId,
    int maxContinuations = 50, // playlist and albums with up to 24 * 51 songs
  }) async {
    final songs = [];
    if (playlistId != null) {
      Map result = await GetIt.I<YTMusic>().getNextSongList(
        playlistId: playlistId,
      );
      songs.addAll(result['contents']);
      String? continuation = result['continuation'];
      while (maxContinuations > 0 && continuation != null) {
        result = await GetIt.I<YTMusic>().getNextSongList(
          continuation: continuation,
        );
        songs.addAll(result['contents']);
        continuation = result['continuation'];
        maxContinuations -= 1;
      }
    }
    return songs;
  }

  Future<void> downloadPlaylist(Map playlist) async {
    List songs = playlist['isPredefined'] == false
        ? playlist['songs']
        : await _getSongs(
            playlistId: playlist['playlistId'],
            maxContinuations: playlist['type'] == 'ARTIST' ? 0 : 50,
          );
    int timestamp = DateTime.now().millisecondsSinceEpoch;
    for (Map song in songs) {
      downloadSong({
        ...song,
        'playlists': {
          playlist['playlistId']: {
            'title': playlist['title'],
            'timestamp': timestamp++,
          },
        },
      }); // Queue each song download
    }
  }

  Future<AudioOnlyStreamInfo> _getSongInfo(
    String videoId, {
    String quality = 'high',
  }) async {
    try {
      StreamManifest manifest = await ytExplode.videos.streamsClient
          .getManifest(
            videoId,
            requireWatchPage: true,
            ytClients: [YoutubeApiClient.androidVr],
          );
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
