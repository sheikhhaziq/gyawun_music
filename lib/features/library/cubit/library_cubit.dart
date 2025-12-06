import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:gyawun_music/core/errors/failure.dart';
import 'package:library_manager/library_manager.dart';

part 'library_state.dart';

class LibraryCubit extends Cubit<LibraryState> {
  LibraryCubit(this.libraryManager) : super(LibraryInitial()) {
    loadLibrary();
  }
  final LibraryManager libraryManager;

  Future<void> loadLibrary() async {
    try {
      final localPlaylists = libraryManager.getLocalPlaylists();

      final remotePlaylists = libraryManager.getRemotePlaylists();

      emit(LibrarySuccess(localPlaylists: localPlaylists, remotePlaylists: remotePlaylists));
    } catch (e) {
      emit(LibraryError(GeneralFailure(e.toString())));
    }
  }

  Future<void> createPlaylist(String id, String name) async {
    try {
      await libraryManager.createPlaylist(id: id, name: name);
      await loadLibrary();
    } catch (e) {
      emit(LibraryError(GeneralFailure(e.toString())));
    }
  }

  Future<void> deletePlaylist(Playlist playlist) async {
    final previousState = state;
    if (previousState is LibrarySuccess) {
      libraryManager.deletePlaylist(playlist.id);
      final localPlaylists = libraryManager.getLocalPlaylists();

      final remotePlaylists = libraryManager.getRemotePlaylists();
      emit(
        previousState.copyWith(localPlaylists: localPlaylists, remotePlaylists: remotePlaylists),
      );
    }

    try {
      await libraryManager.deletePlaylist(playlist.id);
    } catch (e) {
      if (previousState is LibrarySuccess) {
        emit(previousState);
      }
      emit(LibraryError(GeneralFailure(e.toString())));
    }
  }
}
