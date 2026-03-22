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

    _manager.downloadsNotifier.addListener(_listener);
  }

  void load() {
    _emitState();
  }

  void _emitState() {
    if (isClosed) return;

    try {
      final allSongs = _manager.downloadsNotifier.value;

      final downloading = allSongs
          .where((s) => s['status'] == 'DOWNLOADING')
          .toList();

      final queued = _manager.getDownloadQueue();

      emit(DownloadingLoaded(downloading: downloading, queued: queued));
    } catch (e) {
      if (!isClosed) {
        emit(DownloadingError(e.toString()));
      }
    }
  }

  @override
  Future<void> close() {
    _manager.downloadsNotifier.removeListener(_listener);
    return super.close();
  }
}
