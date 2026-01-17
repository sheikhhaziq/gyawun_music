part of 'favourites_cubit.dart';

@immutable
sealed class FavouritesState {
  const FavouritesState();
}

class FavouritesLoading extends FavouritesState {
  const FavouritesLoading();
}

class FavouritesLoaded extends FavouritesState {
  final List songs;

  const FavouritesLoaded(this.songs);
}

class FavouritesError extends FavouritesState {
  final String message;
  const FavouritesError(this.message);
}
