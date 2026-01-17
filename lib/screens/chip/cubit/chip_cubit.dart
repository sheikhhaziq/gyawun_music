import 'package:bloc/bloc.dart';
import 'package:gyawun/ytmusic/ytmusic.dart';
import 'package:meta/meta.dart';

part 'chip_state.dart';

class ChipCubit extends Cubit<ChipState> {
  final YTMusic _ytMusic;
  final Map<String, dynamic> endpoint;
  ChipCubit(this._ytMusic, {required this.endpoint}) : super(ChipLoading());

  Future<void> fetch() async {
    emit(const ChipLoading());
    try {
      final feed = await _ytMusic.browse(body: endpoint);
      emit(ChipSuccess(
        sections: feed['sections'],
        continuation: feed['continuation'],
        loadingMore: false,
      ));
    } catch (e, st) {
      emit(ChipError(e.toString(), st.toString()));
    }
  }

  Future<void> refresh() async {
    try {
      final feed = await _ytMusic.browse();
      emit(ChipSuccess(
        sections: feed['sections'],
        continuation: feed['continuation'],
        loadingMore: false,
      ));
    } catch (e, st) {
      emit(ChipError(e.toString(), st.toString()));
    }
  }

  Future<void> fetchNext() async {
    final current = state;
    if (current is! ChipSuccess) return;
    if (current.loadingMore || current.continuation == null) return;
    emit(current.copyWith(loadingMore: true));
    try {
      final feed = await _ytMusic.browseContinuation(
          additionalParams: current.continuation!);
      emit(
        ChipSuccess(
          sections: [...current.sections, ...feed['sections']],
          continuation: feed['continuation'],
          loadingMore: false,
        ),
      );
    } catch (e, st) {
      emit(ChipError(e.toString(), st.toString()));
    }
  }
}
