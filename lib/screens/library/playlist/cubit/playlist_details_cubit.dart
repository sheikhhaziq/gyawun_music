import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:gyawun/services/library.dart';

part 'playlist_details_state.dart';

class PlaylistDetailsCubit extends Cubit<PlaylistDetailsState> {
  final String playlistKey;
  final LibraryService _library = GetIt.I<LibraryService>();

  late final VoidCallback _listener;

  PlaylistDetailsCubit(this.playlistKey)
      : super(const PlaylistDetailsLoading()) {
    _listener = () {
      if (!isClosed) {
        _emitState();
      }
    };

    _library.addListener(_listener);
  }

  void load() {
    _emitState();
  }

  void _emitState() {
    if (isClosed) return;

    try {
      final playlist = _library.getPlaylist(playlistKey);

      if (playlist == null) {
        emit(const PlaylistDetailsError('Playlist not available'));
        return;
      }

      emit(PlaylistDetailsLoaded(playlist));
    } catch (e) {
      if (!isClosed) {
        emit(PlaylistDetailsError(e.toString()));
      }
    }
  }

  Future<String> removeSong(Map song) {
    return _library.removeFromPlaylist(
      item: song,
      playlistId: playlistKey,
    );
  }

  @override
  Future<void> close() {
    _library.removeListener(_listener);
    return super.close();
  }
}
