import 'dart:ui';

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_swipe_action_cell/core/cell.dart';
import 'package:get_it/get_it.dart';
import 'package:gyawun/core/widgets/song_tile.dart';
import 'package:gyawun/services/media_player.dart';
import 'package:gyawun/themes/text_styles.dart';

import '../../../../generated/l10n.dart';
import '../../../../utils/bottom_modals.dart';
import '../../../../utils/adaptive_widgets/adaptive_widgets.dart';
import 'cubit/favourites_cubit.dart';

class FavouritesPage extends StatelessWidget {
  const FavouritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => FavouritesCubit()..load(),
      child: Scaffold(
        body: BlocBuilder<FavouritesCubit, FavouritesState>(
          builder: (context, state) {
            return switch (state) {
              FavouritesLoading() => const Center(
                child: AdaptiveProgressRing(),
              ),
              FavouritesError(:final message) => Center(child: Text(message)),
              FavouritesLoaded(:final songs) => _FavouritesBody(songs: songs),
            };
          },
        ),
      ),
    );
  }
}

class _FavouritesBody extends StatelessWidget {
  const _FavouritesBody({required this.songs});

  final List songs;

  @override
  Widget build(BuildContext context) {
    return NestedScrollView(
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
                        'Favourites',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textStyle(context).copyWith(fontSize: 16),
                      ),
                      SizedBox(height: 2),
                      Text(
                        S.of(context).nSongs(songs.length),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textStyle(
                          context,
                        ).copyWith(fontSize: 11, fontWeight: FontWeight.w600),
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
                ],
              ),
            ),
          ),
          if (songs.isNotEmpty)
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final song = songs[index];
                return Padding(
                  padding: const .symmetric(horizontal: 8, vertical: 4),
                  child: SwipeActionCell(
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerLowest,
                    key: ObjectKey(song['videoId']),
                    trailingActions: [
                      SwipeAction(
                        title: S.of(context).Remove,
                        color: Colors.red,
                        onTap: (handler) async {
                          final confirm = await Modals.showConfirmBottomModal(
                            context,
                            message: S.of(context).Remove_Message,
                            isDanger: true,
                          );

                          if (confirm && context.mounted) {
                            await context.read<FavouritesCubit>().remove(
                              song['id'] ?? song['videoId'],
                            );
                          }
                        },
                      ),
                    ],
                    child: SongTile(song: song),
                  ),
                );
              }, childCount: songs.length),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],
      ),
    );
  }
}
