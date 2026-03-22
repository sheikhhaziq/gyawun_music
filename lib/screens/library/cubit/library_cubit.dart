import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:gyawun/services/download_manager.dart';
import 'package:gyawun/services/favourites_manager.dart';

import '../../../../services/library.dart';
import '../../../services/history_manager.dart';

part 'library_state.dart';

class LibraryCubit extends Cubit<LibraryState> {
  final LibraryService libraryService;

  late final FavouritesManager _favouritesManager;
  late final DownloadManager _downloadsManager;
  late final SongHistory _songHistory;

  late final VoidCallback _listener;

  LibraryCubit(this.libraryService) : super(const LibraryLoading()) {
    _favouritesManager = GetIt.I<FavouritesManager>();
    _downloadsManager = GetIt.I<DownloadManager>();
    _songHistory = GetIt.I<HistoryManager>().songs;

    _listener = _emitCurrentState;

    libraryService.addListener(_listener);
    _favouritesManager.listenable.addListener(_listener);
    _downloadsManager.downloadsNotifier.addListener(_listener);
    _songHistory.listenable.addListener(_listener);
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
          historyCount: _songHistory.count,
        ),
      );
    } catch (e) {
      emit(LibraryError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    libraryService.removeListener(_listener);
    _favouritesManager.listenable.removeListener(_listener);
    _downloadsManager.downloadsNotifier.removeListener(_listener);
    _songHistory.listenable.removeListener(_listener);
    return super.close();
  }
}
