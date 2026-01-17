import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:gyawun/services/download_manager.dart';

part 'download_playlist_state.dart';

class DownloadPlaylistCubit extends Cubit<DownloadPlaylistState> {
  final String playlistId;
  final DownloadManager _manager = GetIt.I<DownloadManager>();

  late final VoidCallback _listener;

  DownloadPlaylistCubit(this.playlistId)
      : super(const DownloadPlaylistLoading()) {
    _listener = () {
      if (!isClosed) {
        _emitState();
      }
    };

    _manager.downloadsByPlaylist.addListener(_listener);
  }

  void load() {
    _emitState();
    _verifyPlaylistIntegrity();
  }

  void _emitState() {
    if (isClosed) return;

    final allPlaylists = _manager.downloadsByPlaylist.value;
    final playlist = allPlaylists[playlistId];

    if (playlist == null || playlist['songs'] == null) {
      emit(const DownloadPlaylistError('Playlist not available'));
      return;
    }

    emit(
      DownloadPlaylistLoaded(
        playlist: playlist,
        songs: List.from(playlist['songs']),
      ),
    );
  }

  Future<void> _verifyPlaylistIntegrity() async {
    final allPlaylists = _manager.downloadsByPlaylist.value;
    final playlist = allPlaylists[playlistId];
    if (playlist == null) return;

    final List songs = playlist['songs'] ?? [];

    for (final song in songs) {
      final path = song['path'];
      if (path == null) continue;

      final exists = await File(path).exists();
      final status = song['status'];

      if (!exists && status != 'DELETED') {
        await _manager.updateStatus(song['videoId'], 'DELETED');
      }
    }
  }

  Future<void> removeSong(Map song) async {
    await _manager.deleteSong(
      key: song['videoId'],
      path: song['path'],
      playlistId: playlistId,
    );
  }

  @override
  Future<void> close() {
    _manager.downloadsByPlaylist.removeListener(_listener);
    return super.close();
  }
}
