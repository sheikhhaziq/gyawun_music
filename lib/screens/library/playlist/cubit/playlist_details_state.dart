part of 'playlist_details_cubit.dart';

@immutable
sealed class PlaylistDetailsState {
  const PlaylistDetailsState();
}

class PlaylistDetailsLoading extends PlaylistDetailsState {
  const PlaylistDetailsLoading();
}

class PlaylistDetailsLoaded extends PlaylistDetailsState {
  final Map playlist;
  const PlaylistDetailsLoaded(this.playlist);
}

class PlaylistDetailsError extends PlaylistDetailsState {
  final String message;
  const PlaylistDetailsError(this.message);
}
