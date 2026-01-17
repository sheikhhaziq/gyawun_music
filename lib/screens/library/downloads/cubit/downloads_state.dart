part of 'downloads_cubit.dart';

@immutable
sealed class DownloadsState {
  const DownloadsState();
}

class DownloadsLoading extends DownloadsState {
  const DownloadsLoading();
}

class DownloadsLoaded extends DownloadsState {
  final Map playlists;

  const DownloadsLoaded(this.playlists);
}

class DownloadsError extends DownloadsState {
  final String message;
  const DownloadsError(this.message);
}
