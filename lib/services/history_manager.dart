import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:gyawun/services/settings_manager.dart';

class HistoryManager {
  final SearchHistory searches;
  final SongHistory songs;

  HistoryManager._(this.searches, this.songs);

  static Future<HistoryManager> create() async {
    final searches = await SearchHistory.create();
    final songs = await SongHistory.create();
    final instance = HistoryManager._(searches, songs);
    return instance;
  }
}

class SearchHistory {
  final Box _box;

  SearchHistory._(this._box);

  static Future<SearchHistory> create() async {
    final boxName = 'SEARCH_HISTORY';
    await Hive.openBox(boxName);
    final instance = SearchHistory._(Hive.box(boxName));
    return instance;
  }

  Map get all => _box.toMap();

  List<Map<String, dynamic>> getList({String? filter}) {
    final searchHistory = filter == null
        ? _box.values
        : _box.values.where(
            (el) => el.toLowerCase().contains(filter.toLowerCase()),
          );
    return searchHistory
        .toList()
        .map((el) => {'type': 'TEXT', 'query': el, 'isHistory': true})
        .toList();
  }

  Future<void> add(String value) async {
    if (GetIt.I<SettingsManager>().searchHistory) {
      await _box.delete(value.toLowerCase());
      await _box.put(value.toLowerCase(), value);
    }
  }

  Future<void> clear() async {
    await _box.clear();
  }
}

class SongHistory {
  final Box _box;

  SongHistory._(this._box);

  static Future<SongHistory> create() async {
    final boxName = 'SONG_HISTORY';
    await Hive.openBox(boxName);
    final instance = SongHistory._(Hive.box(boxName));
    return instance;
  }

  Listenable get listenable => _box.listenable();
  int get count => _box.length;
  Map get all => _box.toMap();

  List getList() {
    final list = _box.values.toList();
    list.sort((a, b) => (b['updatedAt'] ?? 0).compareTo(a['updatedAt'] ?? 0));
    return list;
  }

  Future<void> add(Map song) async {
    if (GetIt.I<SettingsManager>().playbackHistory) {
      Map? oldState = _box.get(song['videoId']);
      int timestamp = DateTime.now().millisecondsSinceEpoch;
      if (oldState != null) {
        await _box.put(song['videoId'], {
          ...oldState,
          'plays': oldState['plays'] + 1,
          'updatedAt': timestamp,
        });
      } else {
        await _box.put(song['videoId'], {
          ...song,
          'plays': 1,
          'createdAt': timestamp,
          'updatedAt': timestamp,
        });
      }
    }
  }

  Future<void> remove(Map song) async {
    await _box.delete(song['videoId']);
  }

  Future<void> clear() async {
    await _box.clear();
  }

  Future<void> setHistory(Map history) async {
    await Future.forEach(history.entries, (entry) async {
      _box.put(entry.key, entry.value);
    });
  }
}
