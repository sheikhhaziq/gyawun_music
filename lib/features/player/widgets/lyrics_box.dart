import 'package:flutter/material.dart';
import 'package:flutter_lyric/lyrics_reader.dart';
import 'package:get_it/get_it.dart';
import 'package:gyawun/services/lyrics.dart';
import 'package:gyawun/services/media_player.dart';
import 'package:hive/hive.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:gyawun/services/settings_manager.dart';
import 'package:loading_indicator_m3e/loading_indicator_m3e.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

Box _box = Hive.box('SETTINGS');

class LyricsBox extends StatefulWidget {
  const LyricsBox({required this.currentSong, required this.size, super.key});
  final MediaItem currentSong;
  final Size size;

  @override
  State<LyricsBox> createState() => _LyricsBoxState();
}

class _LyricsBoxState extends State<LyricsBox> {
  Future<Map>? _fetchLyricsFuture;
  bool _lyricsLoaded = false;

  @override
  void initState() {
    super.initState();
    _initFetchLyrics();
    _initWakelock();
  }

  void _initFetchLyrics() {
    GetIt.I<MediaPlayer>().progressBarState.addListener(_progressListener);

    if (GetIt.I<MediaPlayer>().progressBarState.value.total.inSeconds > 0) {
      _fetchLyrics();
    }
  }

  void _progressListener() {
    if (GetIt.I<MediaPlayer>().progressBarState.value.total.inSeconds > 0) {
      _fetchLyrics();
      GetIt.I<MediaPlayer>().progressBarState.removeListener(_progressListener);
    }
  }

  void _initWakelock() {
    GetIt.I<MediaPlayer>().buttonState.addListener(_updateWakelock);
  }

  void _updateWakelock() {
    if (!mounted) return;
    final isPlaying =
        GetIt.I<MediaPlayer>().buttonState.value == ButtonState.playing;
    if (isPlaying && _lyricsLoaded) {
      WakelockPlus.enable();
    } else {
      WakelockPlus.disable();
    }
  }

  @override
  void didUpdateWidget(covariant LyricsBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentSong != oldWidget.currentSong) {
      _initFetchLyrics();
    }
  }

  void _fetchLyrics() {
    if (context.mounted) {
      setState(() {
        _fetchLyricsFuture = GetIt.I<Lyrics>().getLyrics(
          videoId: widget.currentSong.id,
          title: widget.currentSong.title,
          artist: widget.currentSong.artist,
          album: widget.currentSong.album,
          durationInSeconds:
              GetIt.I<MediaPlayer>().progressBarState.value.total.inSeconds,
          translation: _box.get('TRANSLATE_LYRICS', defaultValue: false)
              ? context.read<SettingsManager>().language['value']!
              : null,
        );
        _lyricsLoaded = false;
        _fetchLyricsFuture!.then((lyrics) {
          _lyricsLoaded =
              lyrics['syncedLyrics'] != null || lyrics['plainLyrics'] != null;
          _updateWakelock();
        }).catchError((_) {
          _lyricsLoaded = false;
          _updateWakelock();
        });
      });
    }
  }

  @override
  void dispose() {
    GetIt.I<MediaPlayer>().progressBarState.removeListener(_progressListener);
    GetIt.I<MediaPlayer>().buttonState.removeListener(_updateWakelock);
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ValueListenableBuilder(
          valueListenable: GetIt.I<MediaPlayer>().progressBarState,
          builder: (context, progress, child) {
            return progress.total.inSeconds > 0 && _fetchLyricsFuture != null
                ? FutureBuilder(
                    future: _fetchLyricsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        if (snapshot.data == null) {
                          return const Text('No Lyrics');
                        }
                        if (snapshot.data!['success'] == false) {
                          return const Text('No Lyrics');
                        }
                        Map lyrics = snapshot.data!;
                        return ValueListenableBuilder(
                          valueListenable:
                              GetIt.I<MediaPlayer>().progressBarState,
                          builder: (context, progress, child) {
                            return LyricsReader(
                              padding: EdgeInsets.zero,
                              position: progress.current.inMilliseconds,
                              playing:
                                  context.watch<MediaPlayer>().player.playing,
                              lyricUi: UINetease(
                                highlight: false,
                                defaultSize: 19,
                              ),
                              model: LyricsModelBuilder.create()
                                  .bindLyricToMain(lyrics['syncedLyrics'])
                                  .bindLyricToExt(lyrics['transLyrics'])
                                  .getModel(),
                              emptyBuilder: () => SingleChildScrollView(
                                child: Center(
                                  child: Text(
                                    lyrics['plainLyrics'] ?? "No Lyrics",
                                    style: UINetease(
                                      highlight: false,
                                      defaultSize: 19,
                                    ).getOtherMainTextStyle(),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                              size: widget.size,
                            );
                          },
                        );
                      }
                      if (snapshot.hasError) {
                        return const Text('No Lyrics');
                      }
                      return const ExpressiveLoadingIndicator();
                    },
                  )
                : const ExpressiveLoadingIndicator();
          },
        ),
      ),
    );
  }
}
