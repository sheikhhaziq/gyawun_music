part of 'download_playlist_cubit.dart';

@immutable
sealed class DownloadPlaylistState {
  const DownloadPlaylistState();
}

class DownloadPlaylistLoading extends DownloadPlaylistState {
  const DownloadPlaylistLoading();
}

class DownloadPlaylistLoaded extends DownloadPlaylistState {
  final Map playlist;
  final List songs;

  const DownloadPlaylistLoaded({
    required this.playlist,
    required this.songs,
  });
}

class DownloadPlaylistError extends DownloadPlaylistState {
  final String message;
  const DownloadPlaylistError(this.message);
}
