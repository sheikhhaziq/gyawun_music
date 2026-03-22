import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

class FavouritesManager {
  final Box _box;
  static const playlistId = 'FVRTS';

  Listenable get listenable => _box.listenable();

  Map get songs => _box.toMap();
  int get songsCount => _box.length;

  Map<String, dynamic> get playlist => {
    'title': "Favourites",
    'playlistId': playlistId,
    'type': 'PLAYLIST',
    'isPredefined': false,
    'songs': getOrderedSongs(),
  };

  FavouritesManager._(this._box);

  static Future<FavouritesManager> create() async {
    final boxName = 'FAVOURITES';
    await Hive.openBox(boxName);
    final instance = FavouritesManager._(Hive.box(boxName));
    return instance;
  }

  List getOrderedSongs() {
    final list = _box.values.toList();
    list.sort((a, b) => (a['createdAt'] ?? 0).compareTo(b['createdAt'] ?? 0));
    return list;
  }

  bool isFavourite(Map? song) {
    if (song == null || song['videoId'] == null) return false;
    return _box.containsKey(song['videoId']);
  }

  Future<void> add(Map? song) async {
    if (song != null) {
      await _box.put(song['videoId'], {
        ...song,
        'createdAt': song['createdAt'] ?? DateTime.now().millisecondsSinceEpoch,
      });
    }
  }

  Future<void> remove(Map? song) async {
    if (song != null) {
      await _box.delete(song['videoId']);
    }
  }

  Future<void> addOrRemove(Map? song) async {
    if (song != null) {
      if (isFavourite(song)) {
        await remove(song);
      } else {
        await add(song);
      }
    }
  }

  Future<void> setFavourites(Map favourites) async {
    await Future.forEach(favourites.values, (song) async {
      await add(song);
    });
  }
}
