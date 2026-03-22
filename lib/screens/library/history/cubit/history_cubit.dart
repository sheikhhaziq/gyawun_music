import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';

import '../../../../services/history_manager.dart';

part 'history_state.dart';

class HistoryCubit extends Cubit<HistoryState> {
  late final SongHistory _songHistory;
  late final VoidCallback _listener;

  HistoryCubit() : super(const HistoryLoading()) {
    _songHistory = GetIt.I<HistoryManager>().songs;

    _listener = () {
      if (!isClosed) {
        _emitState();
      }
    };

    _songHistory.listenable.addListener(_listener);
  }

  void load() {
    _emitState();
  }

  void _emitState() {
    if (isClosed) return;

    try {
      final songs = _songHistory.getList();
      emit(HistoryLoaded(songs));
    } catch (e) {
      if (!isClosed) {
        emit(HistoryError(e.toString()));
      }
    }
  }

  Future<void> remove(Map song) async {
    await _songHistory.remove(song);
  }

  @override
  Future<void> close() {
    _songHistory.listenable.removeListener(_listener);
    return super.close();
  }
}
