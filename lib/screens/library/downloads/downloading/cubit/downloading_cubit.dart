import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:gyawun/services/download_manager.dart';

part 'downloading_state.dart';

class DownloadingCubit extends Cubit<DownloadingState> {
  final DownloadManager _manager = GetIt.I<DownloadManager>();

  late final VoidCallback _listener;

  DownloadingCubit() : super(const DownloadingLoading()) {
    _listener = () {
      if (!isClosed) {
        _emitState();
      }
    };

    _manager.downloads.addListener(_listener);
    _manager.downloadQueue.addListener(_listener);
  }

  void load() {
    _emitState();
  }

  void _emitState() {
    if (isClosed) return;

    try {
      final allSongs = _manager.downloads.value;

      final downloading =
          allSongs.where((s) => s['status'] == 'DOWNLOADING').toList();

      final queued = _manager.getDownloadQueue();

      final failed =
          allSongs.where((s) => s['status'] == 'FAILED').toList();

      emit(
        DownloadingLoaded(
          downloading: downloading,
          queued: queued,
          failed: failed,
        ),
      );
    } catch (e) {
      if (!isClosed) {
        emit(DownloadingError(e.toString()));
      }
    }
  }

  void cancelDownload(String videoId) {
    _manager.cancelDownload(videoId);
  }

  void retryDownload(Map song) {
    _manager.downloadSong(song);
  }

  void retryAllFailed() {
    _manager.restoreDownloads(
      songs: _manager.downloads.value
          .where((s) => s['status'] == 'FAILED')
          .toList(),
    );
  }

  @override
  Future<void> close() {
    _manager.downloads.removeListener(_listener);
    _manager.downloadQueue.removeListener(_listener);
    return super.close();
  }
}
