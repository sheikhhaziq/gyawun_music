import 'dart:math';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gyawun_music/core/di.dart';
import 'package:gyawun_music/features/player/widgets/add_to_playlist.dart';
import 'package:gyawun_music/features/player/widgets/audio_progress_bar.dart';
import 'package:gyawun_music/features/player/widgets/favourite_button.dart';
import 'package:gyawun_music/features/player/widgets/loop_button.dart';
import 'package:gyawun_music/features/player/widgets/next_button.dart';
import 'package:gyawun_music/features/player/widgets/play_button.dart';
import 'package:gyawun_music/features/player/widgets/player_subtitle.dart';
import 'package:gyawun_music/features/player/widgets/player_thumbnail.dart';
import 'package:gyawun_music/features/player/widgets/player_title.dart';
import 'package:gyawun_music/features/player/widgets/previous_button.dart';
import 'package:gyawun_music/features/player/widgets/queue_button.dart';
import 'package:gyawun_music/features/player/widgets/shuffle_button.dart';
import 'package:gyawun_music/features/player/widgets/timer_button.dart';
import 'package:gyawun_music/services/audio_service/media_player.dart';
import 'package:gyawun_music/services/settings/cubits/appearance_settings_cubit.dart';
import 'package:gyawun_music/services/settings/settings_service.dart';
import 'package:gyawun_music/services/settings/states/app_appearance_state.dart';
import 'package:gyawun_shared/gyawun_shared.dart';

import '../../core/widgets/marquee.dart';

class PlayerScreen extends StatelessWidget {
  const PlayerScreen({super.key, this.showBackButton = true});
  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      body: StreamBuilder<PlayableItem?>(
        stream: sl<MediaPlayer>().currentItemStream,
        builder: (context, asyncSnapshot) {
          if (!asyncSnapshot.hasData || asyncSnapshot.data == null) {
            return const SizedBox.shrink();
          }
          final item = asyncSnapshot.data!;
          return Stack(
            fit: StackFit.expand,
            children: [
              _BackgroundBlurLayer(item.thumbnails),

              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      AppBar(
                        leading: showBackButton
                            ? IconButton(
                                icon: const Icon(FluentIcons.arrow_down_24_filled),
                                onPressed: () => Navigator.pop(context),
                              )
                            : null,
                        backgroundColor: Colors.transparent,
                      ),

                      // Thumbnail
                      SizedBox(
                        width: min(400, size.width) * 0.8,
                        height: min(400, size.width) * 0.8,
                        child: Center(
                          child: PlayerThumbnail(
                            thumbnails: item.thumbnails,
                            width: min(400, size.width) * 0.8,
                            borderRadius: 16,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      MarqueeWidget(child: PlayerTitle(title: item.title)),
                      PlayerSubtitle(
                        subtitle:
                            item.subtitle ?? item.artists.map((artist) => artist.name).join(', '),
                      ),
                      const SizedBox(height: 16),

                      const Column(
                        children: [
                          AudioProgressBar(),
                          SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              ShuffleButton(iconSize: 24),
                              PreviousButton(iconSize: 30),
                              PlayButton(iconSize: 40, padding: EdgeInsets.all(16), isFilled: true),
                              NextButton(iconSize: 30),
                              LoopButton(iconSize: 24),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const TimerButton(),
                          const QueueButton(),
                          AddToPlaylist(item: item),
                          FavouriteButton(item: item),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BackgroundBlurLayer extends StatefulWidget {
  const _BackgroundBlurLayer(this.thumbnails);
  final List<Thumbnail> thumbnails;

  @override
  State<_BackgroundBlurLayer> createState() => _BackgroundBlurLayerState();
}

class _BackgroundBlurLayerState extends State<_BackgroundBlurLayer> {
  final appearanceCubit = sl<SettingsService>().appearance;
  late String? url;

  @override
  void initState() {
    super.initState();
    if (widget.thumbnails.isEmpty) {
      url = null;
      return;
    }
    url = widget.thumbnails.first.url.contains('w60-h60')
        ? widget.thumbnails.first.url.replaceAll('w60-h60', 'w500-h500')
        : widget.thumbnails.last.url;
  }

  @override
  void didUpdateWidget(covariant _BackgroundBlurLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.thumbnails == widget.thumbnails) {
      return;
    }
    if (widget.thumbnails.isEmpty) {
      url = null;
      return;
    }
    url = widget.thumbnails.first.url.contains('w60-h60')
        ? widget.thumbnails.first.url.replaceAll('w60-h60', 'w500-h500')
        : widget.thumbnails.last.url;
  }

  @override
  Widget build(BuildContext context) {
    // BlocBuilder only wraps what needs to rebuild
    return BlocBuilder<AppearanceSettingsCubit, AppAppearanceState>(
      bloc: appearanceCubit,
      buildWhen: (prev, curr) => prev.enableNewPlayer != curr.enableNewPlayer,
      builder: (context, state) {
        if (!state.enableNewPlayer) return const SizedBox.shrink();
        if (url == null) return const SizedBox.shrink();

        return Positioned.fill(
          child: RepaintBoundary(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 700),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) =>
                  FadeTransition(opacity: animation, child: child),
              child: _BlurredImage(key: ValueKey(url), url: url!),
            ),
          ),
        );
      },
    );
  }
}

/// Optimized blurred image widget
class _BlurredImage extends StatelessWidget {
  const _BlurredImage({super.key, required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(image: CachedNetworkImageProvider(url), fit: BoxFit.cover),
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20, tileMode: TileMode.clamp),
          child: Container(color: Colors.black.withValues(alpha: 0.28)),
        ),
      ),
    );
  }
}
