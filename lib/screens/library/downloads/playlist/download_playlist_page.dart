import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_swipe_action_cell/core/cell.dart';
import 'package:get_it/get_it.dart';
import 'package:gyawun/core/widgets/song_tile.dart';
import 'package:gyawun/services/media_player.dart';
import 'package:gyawun/themes/text_styles.dart';
import '../../../../../generated/l10n.dart';
import '../../../../../utils/bottom_modals.dart';
import 'cubit/download_playlist_cubit.dart';

class DownloadPlaylistPage extends StatelessWidget {
  const DownloadPlaylistPage({super.key, required this.playlistId});

  final String playlistId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DownloadPlaylistCubit(playlistId)..load(),
      child: BlocBuilder<DownloadPlaylistCubit, DownloadPlaylistState>(
        builder: (context, state) {
          return switch (state) {
            DownloadPlaylistLoading() => const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
            DownloadPlaylistError() => Scaffold(
              appBar: AppBar(),
              body: Center(child: Text(S.of(context).Playlist_Not_Available)),
            ),
            DownloadPlaylistLoaded(:final playlist, :final songs) =>
              _PlaylistView(
                playlist: playlist,
                songs: songs,
                playlistId: playlistId,
              ),
          };
        },
      ),
    );
  }
}

class _PlaylistView extends StatelessWidget {
  const _PlaylistView({
    required this.playlist,
    required this.songs,
    required this.playlistId,
  });

  final Map playlist;
  final List songs;
  final String playlistId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  pinned: true,
                  expandedHeight: 120,
                  leading: BackButton(
                    style: ButtonStyle(
                      backgroundColor: WidgetStatePropertyAll(Theme.of(context).colorScheme.surfaceContainer)
                    ),
                  ),
                  flexibleSpace: LayoutBuilder(
                    builder: (context, constraints) {
                      final maxHeight = 120.0;
                      final t = (constraints.maxHeight / (maxHeight + 30))
                          .clamp(0.0, 1.0);
                      final paddingLeft = lerpDouble(100, 16, t)!;

                      return FlexibleSpaceBar(
                        
                        titlePadding: EdgeInsets.only(
                          left: paddingLeft,
                          bottom: 8,
                        ),
                        title: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              playlist['type'] == 'SONGS'
                                  ? S.of(context).Songs
                                  : playlist['title'],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textStyle(context).copyWith(fontSize: 16),
                            ),
                            SizedBox(height: 2),
                            Text(
                              S.of(context).nSongs(songs.length),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textStyle(context).copyWith(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        background:
                            playlist['thumbnails']!=null
                            ? Container(
                                height: 120,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  image: DecorationImage(
                                    image: CachedNetworkImageProvider(
                                      playlist['songs']?[1]?['thumbnails']?[1]?['url'],
                                    ),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                foregroundDecoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: .topCenter,
                                    end: .bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Theme.of(context).colorScheme.surface,
                                    ],
                                  ),
                                ),
                              )
                            : null,
                      );
                    },
                  ),
                ),
              ];
            },
            body: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        FilledButton.icon(
                          style: const ButtonStyle(
                            padding: WidgetStatePropertyAll(
                              .symmetric(horizontal: 24, vertical: 16),
                            ),
                            shape: WidgetStatePropertyAll(
                              RoundedRectangleBorder(
                                borderRadius: .only(
                                  topRight: .circular(8),
                                  bottomRight: .circular(8),
                                  topLeft: .circular(24),
                                  bottomLeft: .circular(24),
                                ),
                              ),
                            ),
                          ),
                          onPressed: () {
                            if (songs.isEmpty) return;

                            GetIt.I<MediaPlayer>().playAll(songs);
                          },
                          icon: const Icon(FluentIcons.play_24_filled),
                          label: const Text('Play it'),
                        ),
                        SizedBox(width: 4),
                        FilledButton.tonalIcon(
                          style: const ButtonStyle(
                            padding: WidgetStatePropertyAll(
                              .symmetric(horizontal: 24, vertical: 16),
                            ),
                            shape: WidgetStatePropertyAll(
                              RoundedRectangleBorder(
                                borderRadius: .only(
                                  topLeft: .circular(8),
                                  bottomLeft: .circular(8),
                                  topRight: .circular(24),
                                  bottomRight: .circular(24),
                                ),
                              ),
                            ),
                          ),

                          onPressed: () {
                            if (songs.isEmpty) return;
                            final shuffled = List.from(songs);
                            shuffled.shuffle();

                            GetIt.I<MediaPlayer>().playAll(shuffled);
                          },
                          icon: const Icon(FluentIcons.arrow_shuffle_24_filled),
                          label: const Text('Shuffle'),
                        ),
                        SizedBox(width: 8),
                        IconButton.filled(
                          enableFeedback: true,
                          onPressed: () {
                            Modals.showDownloadDetailsBottomModal(
                              context,
                              playlist,
                            );
                          },
                          icon: Icon(Icons.more_vert),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final song = songs[index];

                    return Padding(
                        padding: const .symmetric(horizontal: 8, vertical: 4),
                      child: SwipeActionCell(
                        key: ObjectKey(song['videoId']),
                        backgroundColor: Colors.transparent,
                        trailingActions: [
                          SwipeAction(
                            title: S.of(context).Remove,
                            color: Colors.red,
                            onTap: (handler) async {
                              await Modals.showConfirmBottomModal(
                                context,
                                message: S.of(context).Remove_Message,
                                isDanger: true,
                              );
                            },
                          ),
                        ],
                        child: SongTile(song: song),
                      ),
                    );
                  }, childCount: songs.length),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 20)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
