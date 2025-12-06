part of 'library_cubit.dart';

@immutable
sealed class LibraryState {}

/// Initial loading state
final class LibraryInitial extends LibraryState {}

/// Loaded successfully
final class LibrarySuccess extends LibraryState {
  LibrarySuccess({required this.localPlaylists, required this.remotePlaylists});

  final List<Playlist> localPlaylists;
  final List<Playlist> remotePlaylists;

  LibrarySuccess copyWith({List<Playlist>? localPlaylists, List<Playlist>? remotePlaylists}) {
    return LibrarySuccess(
      localPlaylists: localPlaylists ?? this.localPlaylists,
      remotePlaylists: remotePlaylists ?? this.remotePlaylists,
    );
  }
}

/// Error state
final class LibraryError extends LibraryState {
  LibraryError(this.failure);
  final Failure failure;
}
