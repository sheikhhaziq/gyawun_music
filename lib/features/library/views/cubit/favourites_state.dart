part of 'favourites_cubit.dart';

@immutable
sealed class FavouritesState {}

final class FavouritesInitial extends FavouritesState {}

final class FavouritesLoading extends FavouritesState {}

final class FavouritesSuccess extends FavouritesState {
  FavouritesSuccess(this.songs);
  final List<PlayableItem> songs;
}

final class FavouritesError extends FavouritesState {
  FavouritesError([this.message]);
  final String? message;
}
