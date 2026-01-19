import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:gyawun/generated/l10n.dart';
import 'package:gyawun/services/media_player.dart';
import 'package:gyawun/utils/song_thumbnail.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

class QueueList extends StatelessWidget {
  const QueueList({super.key});

  @override
  Widget build(BuildContext context) {
    final mediaPlayer = GetIt.I<MediaPlayer>();
    final player = mediaPlayer.player;

    return StreamBuilder(
      stream: mediaPlayer.currentTrackStream,
      builder: (context, snapshot) {
        final sequence = snapshot.data?.sequence ?? [];
        final currentIndex = snapshot.data?.currentIndex ?? 0;

        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor.withAlpha(70),
          ),
          child: ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
              child: SafeArea(
                top: false,
                child: Column(
                  children: [
                    Expanded(
                      child: ReorderableListView(
                        onReorder: (oldIndex, newIndex) async {
                          if (newIndex > oldIndex) newIndex -= 1;
                          await player.moveAudioSource(oldIndex, newIndex);
                        },
                        children: [
                          for (int i = 0; i < sequence.length; i++)
                            QueueTile(
                              key: Key(sequence[i].tag?.id ?? '$i'),
                              index: i,
                              isCurrent: i == currentIndex,
                              source: sequence[i],
                            ),
                        ],
                      ),
                    ),
                    if (Platform.isAndroid)
                      StreamBuilder<bool>(
                        stream: player.shuffleModeEnabledStream,
                        builder: (context, snapshot) {
                          final shuffle = snapshot.data ?? false;
                          return Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  style: ButtonStyle(
                                    backgroundColor: WidgetStatePropertyAll(
                                      shuffle
                                          ? Colors.white
                                          : Colors.white.withAlpha(50),
                                    ),
                                    foregroundColor: WidgetStatePropertyAll(
                                      shuffle
                                          ? Theme.of(context)
                                              .scaffoldBackgroundColor
                                          : Colors.white,
                                    ),
                                  ),
                                  onPressed: () {
                                    player.setShuffleModeEnabled(!shuffle);
                                  },
                                  icon: const Icon(Icons.shuffle_outlined),
                                  label: Text(S.of(context).Shuffle),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class QueueTile extends StatelessWidget {
  final int index;
  final bool isCurrent;
  final IndexedAudioSource source;

  const QueueTile({
    super.key,
    required this.index,
    required this.isCurrent,
    required this.source,
  });

  @override
  Widget build(BuildContext context) {
    final player = GetIt.I<MediaPlayer>().player;
    final MediaItem? song = source.tag as MediaItem?;

    if (song == null) return const SizedBox();

    return Dismissible(
      key: Key(song.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        await player.removeAudioSourceAt(index);
        return true;
      },
      child: ListTile(
        key: Key(index.toString()),
        title: Text(song.title, maxLines: 1),
        leading: ArtworkWidget(song: song, isCurrent: isCurrent),
        subtitle: Text(
          song.artist ?? song.album ?? song.extras?['subtitle'] ?? '',
          maxLines: 1,
        ),
        trailing: const Icon(Icons.drag_handle),
        onTap: () {
          player.seek(Duration.zero, index: index);
        },
      ),
    );
  }
}

class ArtworkWidget extends StatelessWidget {
  final MediaItem song;
  final bool isCurrent;

  const ArtworkWidget({
    super.key,
    required this.song,
    required this.isCurrent,
  });

  @override
  Widget build(BuildContext context) {
    final double dp = MediaQuery.of(context).devicePixelRatio;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        children: [
          SongThumbnail(
            song: song.extras!,
            dp: dp,
            height: 50,
            width: 50,
            fit: BoxFit.fill,
            errorWidget: (_, _, _) => const Icon(Icons.music_note, size: 32),
          ),
          if (isCurrent)
            Container(
              height: 50,
              width: 50,
              color: Colors.black.withValues(alpha:0.6),
            ),
          if (isCurrent)
            const Positioned(
              width: 34,
              height: 34,
              left: 8,
              top: 8,
              child: Center(
                child: Icon(
                  Icons.music_note_outlined,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
