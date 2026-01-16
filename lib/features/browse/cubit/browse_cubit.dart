import 'package:bloc/bloc.dart';
import 'package:gyawun/ytmusic/ytmusic.dart';
import 'package:meta/meta.dart';

part 'browse_state.dart';

class BrowseCubit extends Cubit<BrowseState> {
  final YTMusic _ytMusic;
  final Map<String, dynamic> endpoint;
  BrowseCubit(this._ytMusic, {required this.endpoint}) : super(BrowseLoading());
  Future<void> fetch() async {
    emit(const BrowseLoading());
    try {
      final feed = await _ytMusic.browse(body: endpoint, limit: 2);
      emit(BrowseSuccess(
        header: feed['header'] ?? {},
        sections: feed['sections'],
        continuation: feed['continuation'],
        loadingMore: false,
      ));
    } catch (e, st) {
      emit(BrowseError(e.toString(), st.toString()));
    }
  }
}
