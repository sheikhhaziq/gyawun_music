import 'package:bloc/bloc.dart';
import 'package:gyawun/ytmusic/ytmusic.dart';
import 'package:hive/hive.dart';
import 'package:meta/meta.dart';

part 'search_state.dart';

class SearchCubit extends Cubit<SearchState> {
  final YTMusic _ytmusic;
  Map<String, dynamic>? endpoint;
  SearchCubit(this._ytmusic, {this.endpoint}) : super(SearchLoading()) {
    if (endpoint != null) {
      search('');
    }
  }

  Future<void> search(String query) async {
    emit(const SearchLoading());
    try {
      if (Hive.box('SETTINGS').get('SEARCH_HISTORY', defaultValue: true)) {
        await Hive.box('SEARCH_HISTORY').delete(query.toLowerCase());
        await Hive.box('SEARCH_HISTORY').put(query.toLowerCase(), query);
      }
      final feed = await _ytmusic.search(query, endpoint: endpoint);
      emit(SearchSuccess(
          sections: feed['sections'],
          continuation: feed['continuation'],
          loadingMore: false));
    } catch (e, st) {
      print(e);
      print(st);
      emit(SearchError(e.toString(), st.toString()));
    }
  }

  Future<void> fetchNext() async {
    final current = state;
    if (current is! SearchSuccess) return;
    if (current.loadingMore || current.continuation == null) return;
    emit(current.copyWith(loadingMore: true));
    try {
      final feed = await _ytmusic.search('',
          endpoint: endpoint, additionalParams: current.continuation!);
      SearchSuccess(
        sections: [...current.sections, ...feed['sections']],
        continuation: feed['continuation'],
        loadingMore: false,
      );
    } catch (e, st) {
      emit(SearchError(e.toString(), st.toString()));
    }
  }

  Future<List<Map<String, dynamic>>> getSuggestions(String query) async {
    try {
      List<Map<String, dynamic>> suggestions =
          await _ytmusic.getSearchSuggestions(query);
      return suggestions;
    } catch (e) {
      return [];
    }
  }
}
