import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:gyawun/utils/song_thumbnail.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:provider/provider.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:text_scroll/text_scroll.dart';

import '../../generated/l10n.dart';
import '../../services/download_manager.dart';
import '../../services/media_player.dart';
import '../../themes/colors.dart';
import '../../themes/dark.dart';
import '../../themes/text_styles.dart';
import '../../utils/adaptive_widgets/adaptive_widgets.dart';
import '../../utils/bottom_modals.dart';
import '../../ytmusic/ytmusic.dart';
import 'lyrics_box.dart';
import 'play_button.dart';
import 'queue_list.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key, this.videoId});
  final String? videoId;

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late PanelController panelController;
  final GlobalKey<ScaffoldState> _key = GlobalKey();
  Color? color;
  ImageProvider? image;
  bool canPop = false;
  bool showLyrics = false;
  bool fetchedSong = false;
  late MediaItem? currentSong;

  @override
  void initState() {
    super.initState();
    panelController = PanelController();
    if (widget.videoId != null) {
      GetIt.I<YTMusic>().getSongDetails(widget.videoId!).then((song) {
        if (song != null) {
          GetIt.I<MediaPlayer>().playSong(song);
          setState(() {
            fetchedSong = true;
          });
        }
      });
    }
    currentSong = GetIt.I<MediaPlayer>().currentSongNotifier.value;
    GetIt.I<MediaPlayer>().currentSongNotifier.addListener(songListener);
  }

  @override
  dispose() {
    GetIt.I<MediaPlayer>().currentSongNotifier.removeListener(songListener);
    super.dispose();
  }

  void songListener() {
    if (currentSong != GetIt.I<MediaPlayer>().currentSongNotifier.value) {
      if (mounted) {
        setState(() {
          currentSong = GetIt.I<MediaPlayer>().currentSongNotifier.value;
        });
      }
    }
  }

  void setShowLyrics() {
    if (mounted) {
      setState(() {
        showLyrics = !showLyrics;
      });
    }
  }

  Future<void> updateBackgroundColor(ImageProvider image) async {
    final c = await ColorScheme.fromImageProvider(
      provider: image,
    );
    if (mounted) {
      setState(() {
        color = c.primary;
      });
    }
  }

  MaterialColor primaryWhite = const MaterialColor(
    0xFFFFFFFF,
    <int, Color>{
      50: Color(0xFFFFFFFF),
      100: Color(0xFFFFFFFF),
      200: Color(0xFFFFFFFF),
      300: Color(0xFFFFFFFF),
      400: Color(0xFFFFFFFF),
      500: Color(0xFFFFFFFF),
      600: Color(0xFFFFFFFF),
      700: Color(0xFFFFFFFF),
      800: Color(0xFFFFFFFF),
      900: Color(0xFFFFFFFF),
    },
  );

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: darkTheme(
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryWhite,
          primary: primaryWhite,
          brightness: Brightness.dark,
        ),
      ),
      child: (widget.videoId != null && fetchedSong == false)
          ? const Center(
              child: AdaptiveProgressRing(),
            )
          // ignore: deprecated_member_use
          : WillPopScope(
              onWillPop: () async {
                if (panelController.isAttached && panelController.isPanelOpen) {
                  await panelController.close();
                  return false;
                }
                return true;
              },
              child: AnnotatedRegion<SystemUiOverlayStyle>(
                value: const SystemUiOverlayStyle(
                  statusBarBrightness: Brightness.dark,
                  statusBarColor: Colors.transparent,
                  statusBarIconBrightness: Brightness.light,
                  systemNavigationBarColor: Colors.transparent,
                ),
                child: Container(
                  color: Colors.black,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeIn,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          (color ??
                                  Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerLow)
                              .withAlpha(200),
                          (color ??
                                  Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerLow)
                              .withAlpha(80),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Scaffold(
                      appBar: PreferredSize(
                        preferredSize: AppBar().preferredSize,
                        child: AppBar(
                          backgroundColor: Colors.transparent,
                          surfaceTintColor: Colors.transparent,
                          elevation: 0,
                          iconTheme: const IconThemeData(color: Colors.white),
                          leading: AdaptiveIconButton(
                            onPressed: () {
                              context.pop();
                            },
                            icon: Icon(AdaptiveIcons.chevron_down),
                          ),
                          actions: [
                            AdaptiveIconButton(
                              onPressed: () {
                                setState(() {
                                  showLyrics = !showLyrics;
                                });
                              },
                              icon: Icon(AdaptiveIcons.lyrics),
                            ),
                            if (MediaQuery.of(context).size.width >
                                    MediaQuery.of(context).size.height ||
                                Platform.isWindows)
                              AdaptiveIconButton(
                                onPressed: () {
                                  _key.currentState?.openEndDrawer();
                                },
                                icon: Icon(AdaptiveIcons.queue),
                              ),
                          ],
                        ),
                      ),
                      key: _key,
                      backgroundColor: Colors.transparent,
                      endDrawer: MediaQuery.of(context).size.width >
                                  MediaQuery.of(context).size.height ||
                              Platform.isWindows
                          ? SizedBox(
                              width:
                                  min(400, MediaQuery.of(context).size.width) -
                                      50,
                              child: const QueueList(),
                            )
                          : null,
                      body: SizedBox(
                        width: double.maxFinite,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            EdgeInsets padding = MediaQuery.of(context).padding;
                            double maxWidth = constraints.maxWidth -
                                padding.left -
                                padding.right;
                            double maxHeight = constraints.maxHeight -
                                padding.top -
                                padding.bottom;
                            if (maxWidth > maxHeight) {
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Artwork(
                                    setShowLyrics: setShowLyrics,
                                    showLyrics: showLyrics,
                                    width: maxWidth / 2.3,
                                    song: currentSong,
                                    onImageReady: updateBackgroundColor,
                                  ),
                                  NameAndControls(
                                    song: currentSong,
                                    width: maxWidth - (maxWidth / 2.3),
                                    height: maxHeight,
                                    isRow: true,
                                  )
                                ],
                              );
                            }
                            return Stack(
                              children: [
                                Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Artwork(
                                      setShowLyrics: setShowLyrics,
                                      showLyrics: showLyrics,
                                      width:
                                          min(maxWidth, maxHeight / 2.2) - 24,
                                      song: currentSong,
                                      onImageReady: updateBackgroundColor,
                                    ),
                                    NameAndControls(
                                      song: currentSong,
                                      width: maxWidth,
                                      height: maxHeight -
                                          min(maxWidth, maxHeight / 2.2) -
                                          24,
                                    )
                                  ],
                                ),
                                SlidingUpPanel(
                                  controller: panelController,
                                  color: Colors.transparent,
                                  padding: EdgeInsets.zero,
                                  margin: EdgeInsets.zero,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(20),
                                    topRight: Radius.circular(20),
                                  ),
                                  boxShadow: const [],
                                  minHeight: 50 +
                                      MediaQuery.of(context).padding.bottom,
                                  panel: ClipRRect(
                                    borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(20),
                                        topRight: Radius.circular(20)),
                                    child: Container(
                                      width: constraints.maxWidth,
                                      alignment: Alignment.center,
                                      decoration: const BoxDecoration(
                                        borderRadius: BorderRadius.only(
                                            topLeft: Radius.circular(20),
                                            topRight: Radius.circular(20)),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        mainAxisSize: MainAxisSize.max,
                                        children: [
                                          ClipRRect(
                                            child: BackdropFilter(
                                              filter: ImageFilter.blur(
                                                  sigmaX: 3, sigmaY: 3),
                                              child: Container(
                                                height: 50 +
                                                    MediaQuery.of(context)
                                                        .padding
                                                        .bottom,
                                                width: double.maxFinite,
                                                decoration: BoxDecoration(
                                                  color: Theme.of(context)
                                                      .scaffoldBackgroundColor
                                                      .withAlpha(70),
                                                  borderRadius:
                                                      const BorderRadius.only(
                                                          topLeft:
                                                              Radius.circular(
                                                                  20),
                                                          topRight:
                                                              Radius.circular(
                                                                  20)),
                                                ),
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.max,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Container(
                                                      height: 5,
                                                      width: 50,
                                                      decoration: BoxDecoration(
                                                        color: greyColor,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(20),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Text(
                                                      S.of(context).Next_Up,
                                                      style: textStyle(context,
                                                          bold: true),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                          const Expanded(child: QueueList())
                                        ],
                                      ),
                                    ),
                                  ),
                                )
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

class Artwork extends StatelessWidget {
  const Artwork(
      {this.song,
      required this.width,
      required this.showLyrics,
      required this.setShowLyrics,
      this.onImageReady,
      super.key});
  final double width;
  final MediaItem? song;
  final bool showLyrics;
  final Function setShowLyrics;
  final void Function(ImageProvider)? onImageReady;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: width,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: song == null
            ? Icon(
                Icons.music_note,
                size: width * 0.5,
              )
            : SafeArea(
                child: LayoutBuilder(builder: (context, constraints) {
                  return GestureDetector(
                    onTap: () {
                      setShowLyrics();
                    },
                    child: Center(
                      child: showLyrics
                          ? LyricsBox(
                              currentSong: song!, size: Size(width, width))
                          : Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(30),
                                    spreadRadius: 10,
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: SongThumbnail(
                                  song: song!.extras!,
                                  onImageReady: onImageReady,
                                ),
                              ),
                            ),
                    ),
                  );
                }),
              ),
      ),
    );
  }
}

class NameAndControls extends StatelessWidget {
  const NameAndControls(
      {this.song,
      required this.height,
      required this.width,
      this.isRow = false,
      super.key});
  final double width;
  final double height;
  final MediaItem? song;
  final bool isRow;

  @override
  Widget build(BuildContext context) {
    MediaPlayer mediaPlayer = context.watch<MediaPlayer>();
    return SizedBox(
      height: height,
      width: width,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                TextScroll(
                  song?.title ?? 'Title',
                  style: bigTextStyle(context, bold: true),
                  mode: TextScrollMode.endless,
                ),
                Text(
                  song?.artist ??
                      song?.album ??
                      song?.extras?['subtitle'] ??
                      '',
                  style: smallTextStyle(context),
                )
              ],
            ),
            Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ValueListenableBuilder(
                  valueListenable: mediaPlayer.progressBarState,
                  builder: (context, ProgressBarState value, child) {
                    return ProgressBar(
                      progress: value.current,
                      total: value.total,
                      buffered: value.buffered,
                      barHeight: 3,
                      thumbRadius: 5,
                      onSeek: (value) => mediaPlayer.player.seek(value),
                    );
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ValueListenableBuilder(
                      valueListenable: Hive.box('FAVOURITES').listenable(),
                      builder: (context, value, child) {
                        Map? item = value.get(song?.extras?['videoId']);
                        return AdaptiveIconButton(
                          icon: Icon(
                            item == null
                                ? AdaptiveIcons.heart
                                : AdaptiveIcons.heart_fill,
                            size: 30,
                          ),
                          onPressed: () async {
                            if (item == null) {
                              await Hive.box('FAVOURITES').put(
                                song!.extras!['videoId'],
                                {
                                  ...song!.extras!,
                                  'createdAt':
                                      DateTime.now().millisecondsSinceEpoch
                                },
                              );
                            } else {
                              await value.delete(song!.extras!['videoId']);
                            }
                          },
                        );
                      },
                    ),
                    AdaptiveIconButton(
                      onPressed: () {
                        mediaPlayer.player.seekToPrevious();
                      },
                      icon: Icon(
                        AdaptiveIcons.skip_previous,
                        size: 30,
                      ),
                    ),
                    const PlayButton(size: 40),
                    AdaptiveIconButton(
                      onPressed: () {
                        mediaPlayer.player.seekToNext();
                      },
                      icon: Icon(
                        AdaptiveIcons.skip_next,
                        size: 30,
                      ),
                    ),
                    ValueListenableBuilder(
                        valueListenable: mediaPlayer.loopMode,
                        builder: (context, value, child) {
                          return AdaptiveIconButton(
                            onPressed: () {
                              mediaPlayer.changeLoopMode();
                            },
                            isSelected: value != LoopMode.off,
                            icon: Icon(
                              value == LoopMode.off || value == LoopMode.all
                                  ? AdaptiveIcons.repeat_all
                                  : AdaptiveIcons.repeat_one,
                              size: 30,
                              color: value == LoopMode.off
                                  ? Colors.white.withOpacity(0.3)
                                  : null,
                            ),
                          );
                        }),
                  ],
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (song != null)
                  RepaintBoundary(
                    child: ValueListenableBuilder(
                      valueListenable: GetIt.I<DownloadManager>().downloads,
                      builder: (context, value, child) {
                        List<Map> elements = value
                            .where((item) => item['videoId'] == song!.id)
                            .toList();
                        Map? item = elements.isNotEmpty ? elements.first : null;
                        if (item != null) {
                          if (item['status'] == 'PROCESSING' ||
                              item['status'] == 'DOWNLOADING') {
                            return AdaptiveProgressRing(
                              value: item['status'] == 'DOWNLOADING'
                                  ? item['progress'] / 100
                                  : null,
                              color: Colors.white,
                              backgroundColor: Colors.black,
                            );
                          } else if (item['status'] == 'DOWNLOADED') {
                            return const Icon(Icons.download_done_outlined);
                          }
                        }
                        return AdaptiveIconButton(
                            onPressed: () {
                              GetIt.I<DownloadManager>()
                                  .downloadSong(song!.extras!);
                            },
                            icon: Icon(
                              AdaptiveIcons.download,
                              size: 30,
                            ));
                      },
                    ),
                  ),
                AdaptiveIconButton(
                    onPressed: () {
                      Modals.showPlayerOptionsModal(
                        context,
                        mediaPlayer.currentSongNotifier.value!.extras!,
                      );
                    },
                    icon: Icon(
                      AdaptiveIcons.more_vertical,
                      size: 30,
                    ))
              ],
            ),
            if (song != null && !isRow)
              SizedBox(height: 55 + MediaQuery.of(context).padding.bottom)
          ],
        ),
      ),
    );
  }
}
