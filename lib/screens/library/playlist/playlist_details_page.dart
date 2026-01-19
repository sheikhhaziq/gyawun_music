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
import 'cubit/playlist_details_cubit.dart';

class PlaylistDetailsPage extends StatelessWidget {
  const PlaylistDetailsPage({super.key, required this.playlistkey});

  final String playlistkey;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PlaylistDetailsCubit(playlistkey)..load(),
      child: BlocBuilder<PlaylistDetailsCubit, PlaylistDetailsState>(
        builder: (context, state) {
          return switch (state) {
            PlaylistDetailsLoading() => const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
            PlaylistDetailsError() => const Scaffold(
              body: Center(child: Text('Not available')),
            ),
            PlaylistDetailsLoaded(:final playlist) => _PlaylistView(
              playlist: playlist,
              playlistKey: playlistkey,
            ),
          };
        },
      ),
    );
  }
}

class _PlaylistView extends StatelessWidget {
  const _PlaylistView({required this.playlist, required this.playlistKey});

  final Map playlist;
  final String playlistKey;

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              pinned: true,
              expandedHeight: 120,
              flexibleSpace: LayoutBuilder(
                builder: (context, constraints) {
                  final maxHeight = 120.0;
                  final t = (constraints.maxHeight / (maxHeight + 30)).clamp(
                    0.0,
                    1.0,
                  );
                  final paddingLeft = lerpDouble(100, 16, t)!;

                  return FlexibleSpaceBar(
                    titlePadding: EdgeInsets.only(left: paddingLeft, bottom: 8),
                    title: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          playlist['title'],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textStyle(context).copyWith(fontSize: 16),
                        ),
                        SizedBox(height: 2,),
                        Text(
                          S.of(context).nSongs(playlist['songs'].length),
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
                          RoundedRectangleBorder(borderRadius: .only(
                            topRight: .circular(8),
                            bottomRight: .circular(8),
                            topLeft: .circular(24),
                            bottomLeft: .circular(24)
                          ))
                        ),
                      ),
                      onPressed: () {
                        GetIt.I<MediaPlayer>().playAll(playlist['songs']);
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
                          RoundedRectangleBorder(borderRadius: .only(
                            topLeft: .circular(8),
                            bottomLeft: .circular(8),
                            topRight: .circular(24),
                            bottomRight: .circular(24)
                          ))
                        ),
                      ),
                      
                      onPressed: () {
                        final shuffled = List.from(playlist['songs']);
                        shuffled.shuffle();

                        GetIt.I<MediaPlayer>().playAll(shuffled);
                      },
                      icon: const Icon(FluentIcons.arrow_shuffle_24_filled),
                      label: const Text('Shuffle'),
                    ),
                  ],
                ),
              ),
            ),
            if(playlist['songs'].isNotEmpty)
            SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final song = playlist['songs'][index];

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
                  }, childCount: playlist['songs'].length),
                ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),
          ],
        ),
      ),
    );
  }
}
