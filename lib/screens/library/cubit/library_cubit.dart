import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../../services/library.dart';

part 'library_state.dart';

class LibraryCubit extends Cubit<LibraryState> {
  final LibraryService libraryService;

  late final Box _libraryBox;
  late final Box _favouritesBox;
  late final Box _downloadsBox;
  late final Box _historyBox;

  late final VoidCallback _listener;

  LibraryCubit(this.libraryService) : super(const LibraryLoading()) {
    _libraryBox = Hive.box('LIBRARY');
    _favouritesBox = Hive.box('FAVOURITES');
    _downloadsBox = Hive.box('DOWNLOADS');
    _historyBox = Hive.box('SONG_HISTORY');

    _listener = _emitCurrentState;

    _libraryBox.listenable().addListener(_listener);
    _favouritesBox.listenable().addListener(_listener);
    _downloadsBox.listenable().addListener(_listener);
    _historyBox.listenable().addListener(_listener);
  }

  void loadLibrary() {
    _emitCurrentState();
  }

  void _emitCurrentState() {
    try {
      final downloadedCount =
          _downloadsBox.values.where((e) => e['status'] == 'DOWNLOADED').length;

      emit(
        LibraryLoaded(
          playlists: libraryService.playlists,
          favouritesCount: _favouritesBox.length,
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
    _favouritesBox.listenable().removeListener(_listener);
    _downloadsBox.listenable().removeListener(_listener);
    _historyBox.listenable().removeListener(_listener);
    return super.close();
  }
}
