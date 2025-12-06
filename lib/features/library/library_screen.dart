import 'dart:convert';

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:gyawun_music/core/di.dart';
import 'package:gyawun_music/core/router/route_paths.dart';
import 'package:gyawun_music/core/utils/modals.dart';
import 'package:gyawun_music/features/library/cubit/library_cubit.dart';
import 'package:gyawun_music/features/library/widgets/library_tile.dart';
import 'package:gyawun_music/features/settings/widgets/group_title.dart';
import 'package:gyawun_music/l10n/generated/app_localizations.dart';
import 'package:gyawun_music/services/audio_service/media_player.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(create: (_) => LibraryCubit(sl()), child: const Libraryview());
  }
}

class Libraryview extends StatelessWidget {
  const Libraryview({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LibraryCubit, LibraryState>(
      builder: (context, state) {
        if (state is LibraryInitial) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (state is LibraryError) {
          return Scaffold(
            body: Center(child: Text(AppLocalizations.of(context)!.error(state.failure.message))),
          );
        }

        if (state is LibrarySuccess) {
          return _LibrarySuccessView(state: state);
        }

        return const SizedBox.shrink();
      },
    );
  }
}

class _LibrarySuccessView extends StatelessWidget {
  const _LibrarySuccessView({required this.state});
  final LibrarySuccess state;

  @override
  Widget build(BuildContext context) {
    final localPlaylists = state.localPlaylists;
    final remotePlaylists = state.remotePlaylists;

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              pinned: true,
              expandedHeight: 100,

              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  AppLocalizations.of(context)!.library,
                  style: Theme.of(context).appBarTheme.titleTextStyle,
                ),
                // expandedTitleScale: 1.5,
                titlePadding: const EdgeInsets.only(left: 16, bottom: 12),
              ),
            ),
          ];
        },
        body: CustomScrollView(
          slivers: [
            SliverGroupTitle(title: AppLocalizations.of(context)!.defaultCollection),

            // favourites
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverToBoxAdapter(
                child: LibraryTile(
                  leadingIcon: const Icon(FluentIcons.heart_24_filled, size: 30),
                  // subtitle: favorites.description,
                  title: AppLocalizations.of(context)!.favourites,
                  isFirst: true,
                  onTap: () {
                    context.push(RoutePaths.libraryFavourites);
                  },
                ),
              ),
            ),

            // history
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverToBoxAdapter(
                child: LibraryTile(
                  leadingIcon: const Icon(Icons.queue_music, size: 30),
                  title: AppLocalizations.of(context)!.history,
                  // subtitle: history.description,
                  onTap: () {
                    context.push(RoutePaths.libraryHistory);
                  },
                ),
              ),
            ),

            // downloads
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverToBoxAdapter(
                child: LibraryTile(
                  leadingIcon: const Icon(FluentIcons.cloud_arrow_down_24_filled, size: 30),
                  title: AppLocalizations.of(context)!.downloads,
                  // subtitle: downloads.description,
                  isLast: true,
                  onTap: () {
                    // context.push(RouteLocations.libraryPlaylist(downloads.name, downloads.id));
                  },
                ),
              ),
            ),

            if (localPlaylists.isNotEmpty)
              SliverGroupTitle(title: AppLocalizations.of(context)!.custom),

            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList.separated(
                itemCount: localPlaylists.length,
                itemBuilder: (context, index) {
                  return Dismissible(
                    key: ValueKey(localPlaylists[index].id),
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
                    onDismissed: (_) async {
                      await context.read<LibraryCubit>().deletePlaylist(localPlaylists[index]);
                    },
                    child: LibraryTile(
                      title: localPlaylists[index].name,
                      isFirst: index == 0,
                      isLast: index == localPlaylists.length - 1,
                      onTap: () {
                        context.push(
                          RouteLocations.libraryPlaylist(
                            localPlaylists[index].name,
                            localPlaylists[index].id,
                          ),
                        );
                      },
                    ),
                  );
                },
                separatorBuilder: (context, index) => const SizedBox(height: 2),
              ),
            ),
            if (remotePlaylists.isNotEmpty)
              SliverGroupTitle(title: AppLocalizations.of(context)!.remote),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList.separated(
                itemCount: remotePlaylists.length,
                itemBuilder: (context, index) {
                  final playlist = remotePlaylists[index];

                  return Dismissible(
                    key: ValueKey(playlist.id),
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
                    onDismissed: (_) async {
                      await context.read<LibraryCubit>().deletePlaylist(playlist);
                    },

                    child: LibraryTile(
                      title: playlist.name,
                      isFirst: index == 0,
                      isLast: index == remotePlaylists.length - 1,
                      onTap: () {
                        if (playlist.extraJson != null) {
                          context.push(
                            '/ytmusic/playlist/${jsonEncode(playlist.extraJson!.endpoint)}',
                          );
                        }
                      },
                    ),
                  );
                },
                separatorBuilder: (context, index) => const SizedBox(height: 1),
              ),
            ),
          ],
        ),
      ),

      floatingActionButton: StreamBuilder(
        stream: sl<MediaPlayer>().hasQueueItemsStream,
        builder: (context, asyncSnapshot) {
          return Padding(
            padding: EdgeInsets.only(bottom: asyncSnapshot.data == true ? 80 : 0),
            child: FloatingActionButton(
              onPressed: () async {
                final name = await Modals.showCreatePlaylistModal(context);
                if (context.mounted && name != null) {
                  final id = '$name-${DateTime.now().millisecondsSinceEpoch}';
                  await context.read<LibraryCubit>().createPlaylist(id, name);
                }
              },
              child: const Icon(FluentIcons.add_24_filled),
            ),
          );
        },
      ),
    );
  }
}
