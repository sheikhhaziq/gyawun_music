part of 'search_cubit.dart';

@immutable
sealed class SearchState {
  const SearchState();
}

final class SearchLoading extends SearchState {
  const SearchLoading();
}

final class SearchError extends SearchState {
  final String? message;
  final String? stackTrace;
  const SearchError([this.message, this.stackTrace]);
}

final class SearchSuccess extends SearchState {
  final List sections;
  final bool loadingMore;
  final String? continuation;
  const SearchSuccess({
    required this.sections,
    required this.continuation,
    required this.loadingMore,
  });

  SearchSuccess copyWith({
    List? sections,
    String? continuation,
    bool? loadingMore,
  }) {
    return SearchSuccess(
      sections: sections ?? this.sections,
      continuation: continuation ?? this.continuation,
      loadingMore: loadingMore ?? this.loadingMore,
    );
  }
}
