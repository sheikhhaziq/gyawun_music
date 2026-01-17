part of 'history_cubit.dart';

@immutable
sealed class HistoryState {
  const HistoryState();
}

class HistoryLoading extends HistoryState {
  const HistoryLoading();
}

class HistoryLoaded extends HistoryState {
  final List songs;
  const HistoryLoaded(this.songs);
}

class HistoryError extends HistoryState {
  final String message;
  const HistoryError(this.message);
}
