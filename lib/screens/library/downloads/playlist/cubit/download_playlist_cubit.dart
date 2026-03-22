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

    _manager.playlistsNotifier.addListener(_listener);
  }

  void load() {
    _verifyPlaylistIntegrity();
    _emitState();
  }

  void _emitState() {
    if (isClosed) return;

    final allPlaylists = _manager.playlistsNotifier.value;
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
    final allPlaylists = _manager.playlistsNotifier.value;
    final playlist = allPlaylists[playlistId];
    if (playlist == null) return;

    final List songs = playlist['songs'] ?? [];

    for (final song in songs) {
      final path = song['path'];
      if (path == null) continue;

      final exists = await File(path).exists();
      final status = song['status'];

      if (!exists && status == 'DOWNLOADED') {
        await _manager.updateStatus(song['videoId'], 'DELETED');
      }
    }
  }

  Future<void> removeSong(Map song) async {
    await _manager.deleteSong(key: song['videoId'], playlistId: playlistId);
  }

  Map getCleanSong(Map song) {
    return _manager.getCleanSong(song);
  }

  List? getDownloadedSongs(String? playlistId) {
    return _manager.getDownloadedSongs(playlistId);
  }

  Future<void> restoreDownloads(List<Map> songs) async {
    await _manager.restoreDownloads(songs: songs);
  }

  @override
  Future<void> close() {
    _manager.playlistsNotifier.removeListener(_listener);
    return super.close();
  }
}
