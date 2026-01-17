import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

part 'favourites_state.dart';

class FavouritesCubit extends Cubit<FavouritesState> {
  late final Box _box;
  late final VoidCallback _listener;

  FavouritesCubit() : super(const FavouritesLoading()) {
    _box = Hive.box('FAVOURITES');

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
      emit(FavouritesLoaded(_box.values.toList()));
    } catch (e) {
      if (!isClosed) {
        emit(FavouritesError(e.toString()));
      }
    }
  }

  Future<void> remove(dynamic key) async {
    await _box.delete(key);
    // Hive listener will trigger emit safely
  }

  @override
  Future<void> close() {
    _box.listenable().removeListener(_listener);
    return super.close();
  }
}
