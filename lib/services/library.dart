import 'package:flutter/cupertino.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:yt_music/ytmusic.dart';

class LibraryService extends ChangeNotifier {
  final Box _box;
  late Map _playlists;

  LibraryService._(this._box) {
    _init();
  }

  static Future<LibraryService> create() async {
    final boxName = 'LIBRARY';
    await Hive.openBox(boxName);
    final instance = LibraryService._(Hive.box(boxName));
    await instance._migrateLibIcons();
    return instance;
  }

  void _init() {
    _playlists = _box.toMap();
    _box.listenable().addListener(() {
      _playlists = _box.toMap();
      notifyListeners();
    });
  }

  Map get playlists => _playlists;
  Map get userPlaylists => Map.fromEntries(
    _playlists.entries.where((item) => item.value['isPredefined'] == false),
  );
  Map? getPlaylist(String playlistId) => _box.get(playlistId);

  Future<void> _migrateLibIcons() async {
    for (final entry in userPlaylists.entries) {
      final id = entry.key;
      final item = entry.value;
      if (!item.keys.contains("iconId")) {
        await _box.put(id, {...item, 'iconId': 'musicNoteList'});
      }
    }
  }

  Future<String> createPlaylist(
    String title,
    String iconId, {
    Map? item,
  }) async {
    if (title.trim().isEmpty) {
      return "Playlist name can't be empty";
    }
    await _box.put("CSTMPL${DateTime.now().millisecondsSinceEpoch}", {
      'title': title,
      'iconId': iconId,
      'isPredefined': false,
      'songs': item != null ? [item] : [],
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    });
    notifyListeners();
    if (item != null) {
      return '${item['title']} added to $title';
    } else {
      return 'Playlist $title created';
    }
  }

  Future<String> importPlaylist(String playlistUrl) async {
    try {
      Uri uri = Uri.parse(playlistUrl);
      String? playlistId = uri.queryParameters['list'];
      if (!uri.host.contains('youtube.com') || playlistId == null) {
        return 'Invalid Url';
      }
      String browseId = playlistId.startsWith("VL")
          ? playlistId
          : "VL$playlistId";
      Map<String, dynamic> playlist = await GetIt.I<YTMusic>().importPlaylist(
        browseId,
      );
      String id = playlistId;
      if (_playlists[id] != null) {
        await _box.delete(id);
        notifyListeners();
        return 'Playlist is already added';
      } else {
        await _box.put(id, {
          ...playlist,
          'iconId': 'musicNoteList',
          'isPredefined': true,
          'createdAt': DateTime.now().millisecondsSinceEpoch,
        });
        notifyListeners();
        return 'Added to Library';
      }
    } catch (e) {
      return "Error importing playlist";
    }
  }

  Future<String> addToOrRemoveFromLibrary(Map item) async {
    String id = item['playlistId'];
    if (_playlists[id] != null) {
      await _box.delete(id);
      notifyListeners();
      return 'Removed from Library';
    } else {
      await _box.put(id, {
        ...item,
        'isPredefined': true,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      });
      notifyListeners();
      return 'Added to Library';
    }
  }

  Future<String> editPlaylist({
    String? title,
    required String playlistId,
    required String iconId,
  }) async {
    if (_playlists[playlistId] == null) {
      return 'Playlist does not exist';
    }
    if (title == null || title.trim().isEmpty) {
      return "Playlist name can't be empty";
    }
    Map playlist = await _box.get(playlistId);
    playlist['title'] = title;
    playlist['iconId'] = iconId;
    await _box.put(playlistId, playlist);
    notifyListeners();
    return 'Playlist updated';
  }

  Future<String> removeFromLibrary(String key) async {
    if (_playlists.containsKey(key)) {
      await _box.delete(key);
      notifyListeners();
      return 'Removed from Library';
    } else {
      return 'Does not exist in Library';
    }
  }

  Future<String> addToPlaylist({required Map item, required String key}) async {
    Map? playlist = await _box.get(key);
    if (playlist == null) return 'Playlist does not exist';
    List songs = playlist['songs'] ?? [];
    if (songs.contains(item)) {
      return 'Already present in Playlist';
    }
    songs.add(item);
    playlist['songs'] = songs;
    await _box.put(key, playlist);
    notifyListeners();
    return 'Added to Playlist';
  }

  Future<String> removeFromPlaylist({
    required Map item,
    required String playlistId,
  }) async {
    Map? playlist = await _box.get(playlistId);
    if (playlist == null) return 'Playlist does not exist';
    List songs = playlist['songs'] ?? [];
    if (songs.remove(item)) {
      playlist['songs'] = songs;
      await _box.put(playlistId, playlist);
      notifyListeners();
      return 'Removed from Playlist';
    } else {
      return 'An error occured';
    }
  }

  Future setPlaylists(Map value) async {
    await Future.forEach(value.entries, (entry) async {
      await _box.put(entry.key, entry.value);
    });
    notifyListeners();
  }
}
