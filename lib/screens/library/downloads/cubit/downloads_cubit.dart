import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:gyawun/services/download_manager.dart';

part 'downloads_state.dart';

class DownloadsCubit extends Cubit<DownloadsState> {
  final DownloadManager _manager = GetIt.I<DownloadManager>();

  late final VoidCallback _listener;

  DownloadsCubit() : super(const DownloadsLoading()) {
    _listener = () {
      if (!isClosed) {
        _emitState();
      }
    };

    _manager.downloadsByPlaylist.addListener(_listener);
  }

  void load() {
    _emitState();
  }

  void _emitState() {
    if (isClosed) return;

    try {
      emit(DownloadsLoaded(_manager.downloadsByPlaylist.value));
    } catch (e) {
      if (!isClosed) {
        emit(DownloadsError(e.toString()));
      }
    }
  }

  @override
  Future<void> close() {
    _manager.downloadsByPlaylist.removeListener(_listener);
    return super.close();
  }
}
