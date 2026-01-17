import 'package:bloc/bloc.dart';
import 'package:gyawun/ytmusic/ytmusic.dart';
import 'package:meta/meta.dart';

part 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  final YTMusic _ytMusic;
  HomeCubit(this._ytMusic) : super(HomeLoading());

  Future<void> fetch() async {
    emit(const HomeLoading());
    try {
      final feed = await _ytMusic.browse();
      emit(HomeSuccess(
        chips: feed['chips'] ?? [],
        sections: feed['sections'],
        continuation: feed['continuation'],
        loadingMore: false,
      ));
    } catch (e, st) {
      emit(HomeError(e.toString(), st.toString()));
    }
  }

  Future<void> refresh() async {
    try {
      final feed = await _ytMusic.browse();
      emit(HomeSuccess(
        chips: feed['chips'] ?? [],
        sections: feed['sections'],
        continuation: feed['continuation'],
        loadingMore: false,
      ));
    } catch (e, st) {
      emit(HomeError(e.toString(), st.toString()));
    }
  }

  Future<void> fetchNext() async {
    final current = state;
    if (current is! HomeSuccess) return;
    if (current.loadingMore || current.continuation == null) return;
    emit(current.copyWith(loadingMore: true));
    try {
      final feed = await _ytMusic.browseContinuation(
          additionalParams: current.continuation!);
      emit(
        HomeSuccess(
          chips: current.chips,
          sections: [...current.sections, ...feed['sections']],
          continuation: feed['continuation'],
          loadingMore: false,
        ),
      );
    } catch (e, st) {
      emit(HomeError(e.toString(), st.toString()));
    }
  }
}
