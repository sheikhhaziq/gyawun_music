import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:gyawun/services/media_player.dart';
import 'package:gyawun/utils/adaptive_widgets/buttons.dart';
import 'package:gyawun/utils/adaptive_widgets/listtile.dart';
import 'package:gyawun/utils/adaptive_widgets/progress_ring.dart';
import 'package:gyawun/utils/song_thumbnail.dart';
import 'package:provider/provider.dart';

class BottomPlayer extends StatelessWidget {
  const BottomPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final mediaPlayer = GetIt.I<MediaPlayer>();
    return StreamBuilder(
        stream: mediaPlayer.currentTrackStream,
        builder: (
          context,
          snapshot,
        ) {
          final data = snapshot.data;
          final currentSong = data?.currentItem;
          if (currentSong == null) {
            return const SizedBox(); // or loading indicator
          }
          return Container(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            child: GestureDetector(
              onTap: () {
                context.push('/player');
              },
              child: SafeArea(
                top: false,
                child: Dismissible(
                  key: Key('bottomplayer${currentSong.id}'),
                  direction: DismissDirection.down,
                  confirmDismiss: (direction) async {
                    await GetIt.I<MediaPlayer>().stop();
                    return true;
                  },
                  child: Dismissible(
                    key: Key(currentSong.id),
                    confirmDismiss: (direction) async {
                      if (direction == DismissDirection.startToEnd) {
                        await GetIt.I<MediaPlayer>().player.seekToPrevious();
                      } else {
                        await GetIt.I<MediaPlayer>().player.seekToNext();
                      }
                      return Future.value(false);
                    },
                    child: AdaptiveListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 8),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SongThumbnail(
                          song: currentSong.extras!,
                          dp: MediaQuery.of(context).devicePixelRatio,
                          height: 50,
                          width: 50,
                          fit: BoxFit.fill,
                        ),
                      ),
                      title: Text(
                        currentSong.title,
                        // style: textStyle(context, bold: true),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: (currentSong.artist != null ||
                              currentSong.extras!['subtitle'] != null)
                          ? Text(
                              currentSong.artist ??
                                  currentSong.extras!['subtitle'],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            )
                          : null,
                      trailing: Row(
                        children: [
                          ValueListenableBuilder(
                            valueListenable: GetIt.I<MediaPlayer>().buttonState,
                            builder: (context, buttonState, child) {
                              return (buttonState == ButtonState.loading)
                                  ? const AdaptiveProgressRing()
                                  : AdaptiveIconButton(
                                      onPressed: () {
                                        GetIt.I<MediaPlayer>().player.playing
                                            ? GetIt.I<MediaPlayer>()
                                                .player
                                                .pause()
                                            : GetIt.I<MediaPlayer>()
                                                .player
                                                .play();
                                      },
                                      icon: Icon(
                                        buttonState == ButtonState.playing
                                            ? Icons.pause
                                            : Icons.play_arrow,
                                        size: 30,
                                      ),
                                    );
                            },
                          ),
                          StreamBuilder(
                              stream: context
                                  .watch<MediaPlayer>()
                                  .player
                                  .sequenceStateStream,
                              builder: (context, snapshot) {
                                if (context
                                    .watch<MediaPlayer>()
                                    .player
                                    .hasNext) {
                                  return AdaptiveIconButton(
                                    onPressed: () {
                                      GetIt.I<MediaPlayer>()
                                          .player
                                          .seekToNext();
                                    },
                                    icon: Icon(
                                      Icons.skip_next,
                                      size: 25,
                                    ),
                                  );
                                }
                                return const SizedBox.shrink();
                              })
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        });
  }
}
