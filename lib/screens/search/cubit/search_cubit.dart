import 'package:bloc/bloc.dart';
import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:yt_music/ytmusic.dart';

import '../../../services/history_manager.dart';

part 'search_state.dart';

class SearchCubit extends Cubit<SearchState> {
  final YTMusic _ytmusic;
  Map<String, dynamic>? endpoint;
  late final SearchHistory _searchHistory;

  SearchCubit(this._ytmusic, {this.endpoint}) : super(SearchInitial()) {
    _searchHistory = GetIt.I<HistoryManager>().searches;
    if (endpoint != null) {
      search('');
    }
  }

  Future<void> search(String query) async {
    emit(const SearchLoading());
    try {
      await _searchHistory.add(query);
      final feed = await _ytmusic.search(query, endpoint: endpoint);
      emit(
        SearchSuccess(
          sections: feed['sections'],
          continuation: feed['continuation'],
          loadingMore: false,
        ),
      );
    } catch (e, st) {
      debugPrint(e.toString());
      debugPrint(st.toString());
      emit(SearchError(e.toString(), st.toString()));
    }
  }

  Future<void> fetchNext() async {
    final current = state;
    if (current is! SearchSuccess) return;
    if (current.loadingMore || current.continuation == null) return;
    emit(current.copyWith(loadingMore: true));
    try {
      final feed = await _ytmusic.search(
        '',
        endpoint: endpoint,
        additionalParams: current.continuation!,
      );
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
      List<Map<String, dynamic>> suggestions = await _ytmusic
          .getSearchSuggestions(query);
      return suggestions.isNotEmpty ? suggestions : _searchHistory.getList();
    } catch (e) {
      return [];
    }
  }
}
