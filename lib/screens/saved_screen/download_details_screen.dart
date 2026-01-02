import 'dart:io';

import 'package:expandable_text/expandable_text.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_swipe_action_cell/core/cell.dart';
import 'package:get_it/get_it.dart';
import 'package:gyawun/services/download_manager.dart';
import 'package:gyawun/utils/playlist_thumbnail.dart';
import 'package:gyawun/utils/song_thumbnail.dart';

import '../../generated/l10n.dart';
import '../../services/bottom_message.dart';
import '../../services/media_player.dart';
import '../../themes/colors.dart';
import '../../utils/adaptive_widgets/adaptive_widgets.dart';
import '../../utils/bottom_modals.dart';
import '../../utils/extensions.dart';

class DownloadDetailsScreen extends StatefulWidget {
  const DownloadDetailsScreen({
    super.key,
    required this.playlistId,
  });
  final String playlistId;

  @override
  State<DownloadDetailsScreen> createState() => _DownloadDetailsScreenState();
}

class _DownloadDetailsScreenState extends State<DownloadDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _verifyPlaylistIntegrity();
    });
  }

  Future<void> _verifyPlaylistIntegrity() async {
    final manager = GetIt.I<DownloadManager>();
    final allPlaylists = manager.downloadsByPlaylist.value;
    final playlistsMap = Map<String, dynamic>.from(allPlaylists);
    final playlist = playlistsMap[widget.playlistId];

    if (playlist == null || playlist['songs'] == null) return;

    final List songs = playlist['songs'];
    for (var song in songs) {
      final path = song['path'];
      if (path == null) continue;

      final file = File(path);
      final exists = await file.exists();
      final status = song['status'];

      if (!exists && status != 'DELETED') {
        await manager.updateStatus(song['videoId'], 'DELETED');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: GetIt.I<DownloadManager>().downloadsByPlaylist,
        builder: (context, allPlaylists, child) {
          final Map playlist = allPlaylists[widget.playlistId] ?? {};
          final List songs = playlist['songs'] ?? [];
          return AdaptiveScaffold(
            appBar: AdaptiveAppBar(
              title: playlist.isNotEmpty && playlist['type'] == 'SONGS'
                  ? Text(S.of(context).Songs)
                  : playlist.isNotEmpty
                      ? Text(playlist['title'])
                      : null,
              centerTitle: true,
            ),
            body: playlist.isNotEmpty
                ? Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      constraints: const BoxConstraints(maxWidth: 1000),
                      child: CustomScrollView(
                        slivers: [
                          SliverToBoxAdapter(
                            child: Column(
                              children: [
                                MyPlayistHeader(
                                  playlist: playlist,
                                  imageType: playlist['type'],
                                ),
                                const SizedBox(height: 8),
                              ],
                            ),
                          ),
                          SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                Map song = songs[index];
                                return SwipeActionCell(
                                  backgroundColor: Colors.transparent,
                                  key: ObjectKey(song['videoId']),
                                  trailingActions: <SwipeAction>[
                                    SwipeAction(
                                      title: S.of(context).Remove,
                                      onTap: (CompletionHandler handler) async {
                                        Modals.showConfirmBottomModal(
                                          context,
                                          message: S.of(context).Remove_Message,
                                          isDanger: true,
                                        ).then((bool confirm) {
                                          if (confirm) {
                                            GetIt.I<DownloadManager>()
                                                .deleteSong(
                                                  key: song['videoId'],
                                                  path: song['path'],
                                                  playlistId: widget.playlistId,
                                                )
                                                .then((message) =>
                                                    BottomMessage.showText(
                                                        context, message));
                                          }
                                        });
                                      },
                                      color: Colors.red,
                                    ),
                                  ],
                                  child: DownloadedSongTile(song: song),
                                );
                              },
                              childCount: songs.length,
                            ),
                          ),
                          const SliverToBoxAdapter(child: SizedBox(height: 20)),
                        ],
                      ),
                    ),
                  )
                : Center(
                    child: Text(
                      S.of(context).Playlist_Not_Available,
                      style: TextStyle(
                        fontSize: 18,
                      ),
                    ),
                  ),
          );
        });
  }
}

class MyPlayistHeader extends StatelessWidget {
  const MyPlayistHeader({
    super.key,
    required this.playlist,
    required this.imageType,
  });

  final Map playlist;
  final String imageType;

  Widget _buildImage(List songs, double maxWidth,
      {bool isRound = false, bool isDark = false}) {
    return (songs.isNotEmpty && imageType == "SONGS")
        ? Container(
            height: 200,
            width: 200,
            decoration: BoxDecoration(
              color: greyColor,
              borderRadius: BorderRadius.circular(3),
            ),
            child: Icon(
              CupertinoIcons.music_note_list,
              color: isDark ? Colors.white : Colors.black,
            ),
          )
        : (songs.isNotEmpty && imageType == "ALBUM")
            ? PlaylistThumbnail(playslist: [songs[0]], size: 225, radius: 8)
            : PlaylistThumbnail(playslist: songs, size: 225, radius: 8);
  }

  Padding _buildContent(Map playlist, BuildContext context,
      {bool isRow = false}) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 4),
      child: Column(
        crossAxisAlignment:
            isRow ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        mainAxisAlignment:
            isRow ? MainAxisAlignment.start : MainAxisAlignment.center,
        children: [
          if (playlist['songs'] != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(S.of(context).nSongs(playlist['songs'].length),
                  maxLines: 2),
            ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            runAlignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (playlist['songs'].isNotEmpty)
                AdaptiveFilledButton(
                  onPressed: () {
                    GetIt.I<MediaPlayer>().playAll(playlist['songs']);
                  },
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(Platform.isWindows ? 8 : 35),
                  ),
                  color: context.isDarkMode ? Colors.white : Colors.black,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        AdaptiveIcons.play,
                        color: context.isDarkMode ? Colors.black : Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      const Text("Play All", style: TextStyle(fontSize: 18))
                    ],
                  ),
                ),
              AdaptiveFilledButton(
                shape: const CircleBorder(),
                color: greyColor,
                padding: const EdgeInsets.all(14),
                onPressed: () {
                  Modals.showDownloadDetailsBottomModal(context, playlist);
                },
                child: Icon(
                  AdaptiveIcons.more_vertical,
                  size: 20,
                  color: context.isDarkMode ? Colors.white : Colors.black,
                ),
              )
            ],
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.maxFinite,
      child: Adaptivecard(
        child: LayoutBuilder(builder: (context, constraints) {
          return constraints.maxWidth > 600
              ? Row(
                  children: [
                    if (playlist['songs'] != null)
                      _buildImage(playlist['songs'], constraints.maxWidth,
                          isRound: playlist['type'] == 'ARTIST',
                          isDark: context.isDarkMode),
                    const SizedBox(width: 4),
                    Expanded(
                        child: _buildContent(playlist, context, isRow: true)),
                  ],
                )
              : Column(
                  children: [
                    if (playlist['songs'] != null)
                      _buildImage(playlist['songs'], constraints.maxWidth,
                          isRound: playlist['type'] == 'ARTIST',
                          isDark: context.isDarkMode),
                    SizedBox(height: playlist['thumbnails'] != null ? 4 : 0),
                    _buildContent(playlist, context),
                  ],
                );
        }),
      ),
    );
  }
}

class DownloadedSongTile extends StatelessWidget {
  const DownloadedSongTile({required this.song, super.key});
  final Map song;

  @override
  Widget build(BuildContext context) {
    double height =
        (song['aspectRatio'] != null ? 50 / song['aspectRatio'] : 50)
            .toDouble();
    return AdaptiveListTile(
      onTap: () async {
        if (song['videoId'] != null && song['status'] == 'DOWNLOADED') {
          await GetIt.I<MediaPlayer>().playSong(Map.from(song));
        }
      },
      onSecondaryTap: () {
        if (song['videoId'] != null && song['status'] == 'DOWNLOADED') {
          Modals.showSongBottomModal(context, song);
        }
      },
      onLongPress: () {
        if (song['videoId'] != null && song['status'] == 'DOWNLOADED') {
          Modals.showSongBottomModal(context, song);
        }
      },
      title: Text(song['title'] ?? "", maxLines: 1),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: SongThumbnail(
          song: song,
          height: height,
          width: 50,
          fit: BoxFit.cover,
        ),
      ),
      subtitle: Text(
        song['status'] == 'DELETED'
            ? S.of(context).FileNotFound
            : song['status'] == 'DOWNLOADING'
                ? S.of(context).Downloading
                : song['status'] == 'QUEUED'
                    ? S.of(context).Queued
                    : _buildSubtitle(song),
        maxLines: 1,
        style: TextStyle(
          color: song['status'] == 'DELETED'
              ? Colors.red
              : song['status'] == 'DOWNLOADING'
                  ? Theme.of(context).colorScheme.primary
                  : song['status'] == 'QUEUED'
                      ? Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.5)
                      : Colors.grey.withAlpha(250),
        ),
        overflow: TextOverflow.ellipsis,
      ),
      trailing: song['status'] == 'DELETED'
          ? IconButton(
              onPressed: () {
                GetIt.I<DownloadManager>().downloadSong(song);
              },
              icon: const Icon(Icons.refresh))
          : null,
      description: song['type'] == 'EPISODE' && song['description'] != null
          ? ExpandableText(
              song['description'].split('\n')?[0] ?? '',
              expandText: S.of(context).Show_More,
              collapseText: S.of(context).Show_Less,
              maxLines: 3,
              style: TextStyle(color: context.subtitleColor),
            )
          : null,
    );
  }

  String _buildSubtitle(Map item) {
    List sub = [];
    if (sub.isEmpty && item['artists'] != null) {
      for (Map artist in item['artists']) {
        sub.add(artist['name']);
      }
    }
    if (sub.isEmpty && item['album'] != null) {
      sub.add(item['album']['name']);
    }
    String s = sub.join(' · ');
    return item['subtitle'] ?? s;
  }
}
