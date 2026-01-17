import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

part 'history_state.dart';

class HistoryCubit extends Cubit<HistoryState> {
  late final Box _box;
  late final VoidCallback _listener;

  HistoryCubit() : super(const HistoryLoading()) {
    _box = Hive.box('SONG_HISTORY');

    _listener = () {
      if (!isClosed) {
        _emitState();
      }
    };

    _box.listenable().addListener(_listener);
  }

  void load() {
    _emitState();
  }

  void _emitState() {
    if (isClosed) return;

    try {
      final songs = _box.values.toList();

      songs.sort(
        (a, b) => (b['updatedAt'] ?? 0).compareTo(a['updatedAt'] ?? 0),
      );

      emit(HistoryLoaded(songs));
    } catch (e) {
      if (!isClosed) {
        emit(HistoryError(e.toString()));
      }
    }
  }

  Future<void> remove(dynamic videoId) async {
    await _box.delete(videoId);
    // listener will re-emit safely
  }

  @override
  Future<void> close() {
    _box.listenable().removeListener(_listener);
    return super.close();
  }
}
