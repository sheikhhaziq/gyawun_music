import 'dart:ui';

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
import '../../../../services/bottom_message.dart';
import '../../../../services/download_manager.dart';
import '../../../../services/favourites_manager.dart';
import '../../../../utils/adaptive_widgets/appbar.dart';
import '../../../../utils/adaptive_widgets/scaffold.dart';
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
            DownloadPlaylistError() => AdaptiveScaffold(
              appBar: AdaptiveAppBar(),
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
  _PlaylistView({
    required this.playlist,
    required this.songs,
    required this.playlistId,
  });

  final Map playlist;
  final List songs;
  final String playlistId;

  final Map<String, _SongStatusConfig> statusMap = {
    "DELETED": _SongStatusConfig(
      onTap: (ctx, _) {
        BottomMessage.showText(ctx, S.of(ctx).File_Not_Found);
      },
      onLongPress: (ctx, _) {
        BottomMessage.showText(ctx, S.of(ctx).File_Not_Found);
      },
      icon: FluentIcons.arrow_circle_down_24_regular,
      onIconPress: (ctx, song) {
        ctx.read<DownloadPlaylistCubit>().restoreDownloads([song]);
      },
    ),
    "QUEUED": _SongStatusConfig(
      onTap: (ctx, _) {
        BottomMessage.showText(ctx, S.of(ctx).Queued);
      },
      onLongPress: (ctx, _) {
        BottomMessage.showText(ctx, S.of(ctx).Queued);
      },
      icon: FluentIcons.clock_24_regular,
      onIconPress: (ctx, _) {
        BottomMessage.showText(ctx, S.of(ctx).Queued);
      },
    ),
    "DOWNLOADING": _SongStatusConfig(
      onTap: (ctx, _) {
        BottomMessage.showText(ctx, S.of(ctx).Downloading);
      },
      onLongPress: (ctx, _) {
        BottomMessage.showText(ctx, S.of(ctx).Downloading);
      },
      icon: FluentIcons.arrow_sync_circle_24_regular,
      onIconPress: (ctx, _) {
        BottomMessage.showText(ctx, S.of(ctx).Downloading);
      },
    ),
  };

  @override
  Widget build(BuildContext context) {
    final downloadedSongs = context
        .read<DownloadPlaylistCubit>()
        .getDownloadedSongs(playlistId);
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
                              playlist.isNotEmpty &&
                                      playlist['id'] ==
                                          DownloadManager.songsPlaylistId
                                  ? S.of(context).Songs
                                  : playlist.isNotEmpty &&
                                        playlist['id'] ==
                                            FavouritesManager.playlistId
                                  ? S.of(context).Favourites
                                  : playlist.isNotEmpty
                                  ? playlist['title']
                                  : null,
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
                            if (downloadedSongs == null ||
                                downloadedSongs.isEmpty) {
                              BottomMessage.showText(
                                context,
                                S.of(context).No_Offline_Songs,
                              );
                            } else {
                              GetIt.I<MediaPlayer>().playAll(downloadedSongs);
                            }
                          },
                          icon: const Icon(FluentIcons.play_24_filled),
                          label: Text(S.of(context).Play_All),
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
                            if (downloadedSongs == null ||
                                downloadedSongs.isEmpty) {
                              BottomMessage.showText(
                                context,
                                S.of(context).No_Offline_Songs,
                              );
                            } else {
                              final shuffled = List.from(downloadedSongs);
                              shuffled.shuffle();
                              GetIt.I<MediaPlayer>().playAll(shuffled);
                            }
                          },
                          icon: const Icon(FluentIcons.arrow_shuffle_24_filled),
                          label: Text(S.of(context).Shuffle),
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
                    final config = statusMap[song['status']];
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
                              final confirm =
                                  await Modals.showConfirmBottomModal(
                                    context,
                                    message: S.of(context).Remove_Message,
                                    isDanger: true,
                                  );
                              if (confirm && context.mounted) {
                                await context
                                    .read<DownloadPlaylistCubit>()
                                    .removeSong(song);
                              } else {
                                handler(false);
                              }
                            },
                          ),
                        ],
                        child: SongTile(
                          song: context
                              .read<DownloadPlaylistCubit>()
                              .getCleanSong(song),
                          onTap: config?.onTap,
                          onLongPress: config?.onLongPress,
                          icon: config?.icon,
                          onIconPress: config?.onIconPress,
                          isFirst: index == 0,
                          isLast: index == songs.length - 1,
                        ),
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

class _SongStatusConfig {
  final void Function(BuildContext, Map)? onTap;
  final void Function(BuildContext, Map)? onLongPress;
  final IconData icon;
  final void Function(BuildContext, Map)? onIconPress;

  const _SongStatusConfig({
    required this.onTap,
    required this.onLongPress,
    required this.icon,
    this.onIconPress,
  });
}
