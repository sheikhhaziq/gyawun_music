import 'package:bloc/bloc.dart';
import 'package:gyawun_shared/gyawun_shared.dart';
import 'package:library_manager/library_manager.dart';
import 'package:meta/meta.dart';

part 'favourites_state.dart';

class FavouritesCubit extends Cubit<FavouritesState> {
  FavouritesCubit(this.libraryManager) : super(FavouritesInitial());

  final LibraryManager libraryManager;

  void fetchSongs() {
    emit(FavouritesLoading());
    try {
      final songs = libraryManager.getAllFavourites();
      emit(FavouritesSuccess(songs));
    } catch (e) {
      emit(FavouritesError(e.toString()));
    }
  }

  Future<void> remove(String itemId, DataProvider provider) async {
    if (state is FavouritesSuccess) {
      await libraryManager.removeFavourite(itemId, provider);
      fetchSongs();
    }
  }

  Future<void> reorder(PlayableItem item, int oldIndex, int newIndex) async {
    if (state is FavouritesSuccess) {
      await libraryManager.moveFavouriteToPosition(
        itemId: item.id,
        provider: item.provider,
        newIndex: newIndex,
      );
      fetchSongs();
    }
  }
}
