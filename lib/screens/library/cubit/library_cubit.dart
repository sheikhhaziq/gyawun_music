import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:gyawun/services/download_manager.dart';
import 'package:gyawun/services/favourites_manager.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../../services/library.dart';

part 'library_state.dart';

class LibraryCubit extends Cubit<LibraryState> {
  final LibraryService libraryService;

  late final Box _libraryBox;
  late final FavouritesManager _favouritesManager;
  late final DownloadManager _downloadsManager;
  late final Box _historyBox;

  late final VoidCallback _listener;

  LibraryCubit(this.libraryService) : super(const LibraryLoading()) {
    _libraryBox = Hive.box('LIBRARY');
    _favouritesManager = GetIt.I<FavouritesManager>();
    _downloadsManager = GetIt.I<DownloadManager>();
    _historyBox = Hive.box('SONG_HISTORY');

    _listener = _emitCurrentState;

    _libraryBox.listenable().addListener(_listener);
    _favouritesManager.listenable.addListener(_listener);
    _downloadsManager.downloadsNotifier.addListener(_listener);
    _historyBox.listenable().addListener(_listener);
  }

  void loadLibrary() {
    _emitCurrentState();
  }

  void _emitCurrentState() {
    try {
      final downloadedCount = _downloadsManager.downloads.length;

      emit(
        LibraryLoaded(
          playlists: libraryService.playlists,
          favourites: _favouritesManager.playlist,
          downloadsCount: downloadedCount,
          historyCount: _historyBox.length,
        ),
      );
    } catch (e) {
      emit(LibraryError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _libraryBox.listenable().removeListener(_listener);
    _favouritesManager.listenable.removeListener(_listener);
    _downloadsManager.downloadsNotifier.removeListener(_listener);
    _historyBox.listenable().removeListener(_listener);
    return super.close();
  }
}
