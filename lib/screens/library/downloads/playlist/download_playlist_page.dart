import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_swipe_action_cell/core/cell.dart';

import '../../../../../generated/l10n.dart';
import '../../../../../utils/bottom_modals.dart';
import 'cubit/download_playlist_cubit.dart';
import 'widgets/download_playlist_header.dart';
import 'widgets/download_song_tile.dart';

class DownloadPlaylistPage extends StatelessWidget {
  const DownloadPlaylistPage({
    super.key,
    required this.playlistId,
  });

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
                body: Center(
                  child: Text(S.of(context).Playlist_Not_Available),
                ),
              ),
            DownloadPlaylistLoaded(
              :final playlist,
              :final songs,
            ) =>
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
      appBar: AppBar(
        title: playlist['type'] == 'SONGS'
            ? Text(S.of(context).Songs)
            : Text(playlist['title']),
        centerTitle: true,
      ),
      body: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          constraints: const BoxConstraints(maxWidth: 1000),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    DownloadPlaylistHeader(
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
                    final song = songs[index];

                    return SwipeActionCell(
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

                            // if (confirm) {
                            //   final message = await context
                            //       .read<DownloadPlaylistCubit>()
                            //       .removeSong(song);

                            //   BottomMessage.showText(
                            //     context,
                            //     message.toString(),
                            //   );
                            // }
                          },
                        ),
                      ],
                      child: DownloadedSongTile(song: song),
                    );
                  },
                  childCount: songs.length,
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
