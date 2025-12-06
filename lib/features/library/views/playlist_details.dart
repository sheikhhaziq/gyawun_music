import 'dart:ui';

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gyawun_music/core/di.dart';
import 'package:gyawun_music/core/utils/modals.dart';
import 'package:gyawun_music/core/widgets/hint_text.dart';
import 'package:gyawun_music/features/library/views/cubit/playlist_details_cubit.dart';
import 'package:gyawun_music/features/library/widgets/library_song_tile.dart';
import 'package:gyawun_music/services/audio_service/media_player.dart';

class PlaylistDetailsScreen extends StatelessWidget {
  const PlaylistDetailsScreen({super.key, required this.name, required this.id});
  final String name;
  final String id;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PlaylistDetailsCubit(sl(), id)..fetchSongs(),
      child: PlaylistDetailsView(name: name),
    );
  }
}

class PlaylistDetailsView extends StatelessWidget {
  const PlaylistDetailsView({super.key, required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<PlaylistDetailsCubit, PlaylistDetailsState>(
        builder: (context, state) {
          if (state is PlaylistDetailsLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is PlaylistDetailsError) {
            return Center(child: Text('Error: ${state.message}'));
          }
          if (state is PlaylistDetailsSuccess) {
            final songs = state.songs;
            return NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverAppBar(
                    pinned: true,

                    expandedHeight: 120,
                    flexibleSpace: LayoutBuilder(
                      builder: (context, constraints) {
                        const maxHeight = 120;
                        final t =
                            ((constraints.maxHeight - kToolbarHeight) /
                                    (maxHeight - kToolbarHeight))
                                .clamp(0.0, 1.0);

                        final paddingLeft = lerpDouble(16, 72, 1 - t)!;

                        return FlexibleSpaceBar(
                          titlePadding: EdgeInsets.only(left: paddingLeft, bottom: 6, right: 16),
                          expandedTitleScale: 1.2,
                          title: Row(
                            children: [
                              Text(
                                name,
                                style: Theme.of(context).appBarTheme.titleTextStyle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const Spacer(),
                              IconButton.filled(
                                padding: EdgeInsets.zero,
                                onPressed: () async {
                                  await sl<MediaPlayer>().playSongs(state.songs);
                                },
                                icon: const Icon(Icons.play_arrow_rounded),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ];
              },
              body: (state.songs.isEmpty)
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            FluentIcons.heart_broken_24_filled,
                            size: 64,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No Items',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        HintText(
                          text: "Swipe left on an item to remove it from playlist",
                          color: Theme.of(context).colorScheme.onSecondaryContainer,
                          backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                        ),
                        Expanded(
                          child: ReorderableListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: songs.length,
                            buildDefaultDragHandles: false,
                            itemBuilder: (context, index) {
                              return Padding(
                                key: ValueKey('${songs[index].provider.name}_${songs[index].id}'),
                                padding: const EdgeInsets.symmetric(vertical: 1),
                                child: Dismissible(
                                  key: ValueKey(
                                    '${songs[index].provider.name}__${songs[index].id}',
                                  ),
                                  resizeDuration: const Duration(milliseconds: 200),

                                  direction: DismissDirection.endToStart,
                                  background: Container(
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.only(right: 20),
                                    color: Theme.of(context).colorScheme.errorContainer,
                                    child: Icon(
                                      Icons.delete_rounded,
                                      color: Theme.of(context).colorScheme.onErrorContainer,
                                      size: 24,
                                    ),
                                  ),
                                  onDismissed: (_) => context.read<PlaylistDetailsCubit>().remove(
                                    songs[index].id,
                                    songs[index].provider,
                                  ),

                                  child: LibrarySongTile(
                                    item: songs[index],
                                    isFirst: index == 0,
                                    isLast: index == songs.length - 1,
                                    trailing: Row(
                                      children: [
                                        IconButton(
                                          onPressed: () async {
                                            await Modals.showItemBottomSheet(context, songs[index]);
                                            if (context.mounted) {
                                              context.read<PlaylistDetailsCubit>().fetchSongs();
                                            }
                                          },
                                          icon: const Icon(Icons.more_vert_rounded),
                                        ),
                                        ReorderableDragStartListener(
                                          index: index,
                                          child: Icon(
                                            FluentIcons.re_order_24_filled,
                                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                                            size: 30,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                            onReorder: (int oldIndex, int newIndex) async {
                              if (newIndex > oldIndex) newIndex -= 1;
                              await context.read<PlaylistDetailsCubit>().reorder(
                                songs[oldIndex],
                                oldIndex,
                                newIndex,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
