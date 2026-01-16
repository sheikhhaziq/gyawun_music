part of 'browse_cubit.dart';

@immutable
sealed class BrowseState {
  const BrowseState();
}

final class BrowseLoading extends BrowseState {
  const BrowseLoading();
}

final class BrowseError extends BrowseState {
  final String? message;
  final String? stackTrace;
  const BrowseError([this.message, this.stackTrace]);
}

final class BrowseSuccess extends BrowseState {
  final Map<dynamic, dynamic> header;
  final List sections;
  final bool loadingMore;
  final String? continuation;
  const BrowseSuccess({
    required this.header,
    required this.sections,
    required this.continuation,
    required this.loadingMore,
  });

  BrowseSuccess copyWith({
    Map<dynamic, dynamic>? header,
    List? sections,
    String? continuation,
    bool? loadingMore,
  }) {
    return BrowseSuccess(
      header: header ?? this.header,
      sections: sections ?? this.sections,
      continuation: continuation ?? this.continuation,
      loadingMore: loadingMore ?? this.loadingMore,
    );
  }
}
