part of 'privacy_cubit.dart';

enum PrivacyAction {
  playbackDeleted,
  searchDeleted,
}

class PrivacyState {
  final bool playbackHistory;
  final bool searchHistory;
  final PrivacyAction? lastAction;

  const PrivacyState({
    required this.playbackHistory,
    required this.searchHistory,
    this.lastAction,
  });

  factory PrivacyState.initial() => const PrivacyState(
        playbackHistory: true,
        searchHistory: true,
      );

  PrivacyState copyWith({
    bool? playbackHistory,
    bool? searchHistory,
    PrivacyAction? lastAction,
  }) {
    return PrivacyState(
      playbackHistory: playbackHistory ?? this.playbackHistory,
      searchHistory: searchHistory ?? this.searchHistory,
      lastAction: lastAction,
    );
  }
}
