part of 'downloading_cubit.dart';

@immutable
sealed class DownloadingState {
  const DownloadingState();
}

class DownloadingLoading extends DownloadingState {
  const DownloadingLoading();
}

class DownloadingLoaded extends DownloadingState {
  final List downloading;
  final List queued;
  final List failed;

  const DownloadingLoaded({
    required this.downloading,
    required this.queued,
    this.failed = const [],
  });
}

class DownloadingError extends DownloadingState {
  final String message;
  const DownloadingError(this.message);
}
