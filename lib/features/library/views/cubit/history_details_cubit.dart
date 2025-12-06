import 'package:bloc/bloc.dart';
import 'package:gyawun_shared/gyawun_shared.dart';
import 'package:library_manager/library_manager.dart';
import 'package:meta/meta.dart';

part 'history_details_state.dart';

class HistoryDetailsCubit extends Cubit<HistoryDetailsState> {
  HistoryDetailsCubit(this.libraryManager) : super(HistoryDetailsInitial());

  final LibraryManager libraryManager;

  void fetchSongs() {
    emit(HistoryDetailsLoading());
    try {
      final songs = libraryManager.getRecentlyPlayed();
      emit(HistoryDetailsSuccess(songs));
    } catch (e) {
      emit(HistoryDetailsError(e.toString()));
    }
  }

  Future<void> remove(String itemId, DataProvider provider) async {
    if (state is HistoryDetailsSuccess) {
      await libraryManager.removeFromPlaybackHistory(itemId, provider);
      fetchSongs();
    }
  }
}
