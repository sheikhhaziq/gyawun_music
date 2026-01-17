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

  const DownloadingLoaded({
    required this.downloading,
    required this.queued,
  });
}

class DownloadingError extends DownloadingState {
  final String message;
  const DownloadingError(this.message);
}
