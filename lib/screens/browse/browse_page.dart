import 'package:cached_network_image/cached_network_image.dart';
import 'package:expandable_text/expandable_text.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:gyawun/core/widgets/internet_guard.dart';
import 'package:gyawun/core/utils/service_locator.dart';
import 'package:gyawun/screens/browse/cubit/browse_cubit.dart';
import 'package:gyawun/core/widgets/section_item.dart';
import 'package:loading_indicator_m3e/loading_indicator_m3e.dart';

import '../../generated/l10n.dart';
import '../../services/bottom_message.dart';
import '../../services/library.dart';
import '../../services/media_player.dart';
import '../../utils/bottom_modals.dart';
import '../../utils/enhanced_image.dart';
import '../../utils/extensions.dart';

class BrowsePage extends StatelessWidget {
  final Map<String, dynamic> endpoint;
  final bool isMore;
  const BrowsePage({super.key, required this.endpoint, this.isMore = false});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => BrowseCubit(sl(), endpoint: endpoint)..fetch(),
      child: _BrowsePage(endpoint: endpoint, isMore: isMore),
    );
  }
}

class _BrowsePage extends StatefulWidget {
  const _BrowsePage({required this.endpoint, this.isMore = false});
  final Map<String, dynamic> endpoint;
  final bool isMore;

  @override
  State<_BrowsePage> createState() => _BrowsePageState();
}

class _BrowsePageState extends State<_BrowsePage> {
  late ScrollController _scrollController;

  String? continuation;
  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
  }

  // @override
  // void didUpdateWidget(covariant _BrowsePage oldWidget) {
  //   super.didUpdateWidget(oldWidget);
  //   if (oldWidget.endpoint['browseId'] != widget.endpoint['browseId']) {
  //     fetchData();
  //   }
  // }

  Future<void> _scrollListener() async {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      await context.read<BrowseCubit>().fetchNext();
    }
  }

  @override
  Widget build(BuildContext context) {
    return InternetGuard(
      onConnectivityRestored: context.read<BrowseCubit>().fetch,
      child: BlocBuilder<BrowseCubit, BrowseState>(
        builder: (context, state) {
          switch (state) {
            case BrowseLoading():
              return Center(child: LoadingIndicatorM3E());
            case BrowseError():
              return Center(child: Text(state.message ?? ''));
            case BrowseSuccess():
              final isAddedToLibrary =
                  context.watch<LibraryService>().getPlaylist(
                    state.header['playlistId'],
                  ) !=
                  null;
              return Scaffold(
                appBar: AppBar(
                  title: state.header['title'] != null
                      ? Text(state.header['title'])
                      : null,
                  actionsPadding: .only(right: 8),
                  actions: [
                    if (state.header['privacy'] != 'PRIVATE' &&
                        state.header['playlistId'] != 'LM')
                      IconButton(
                        icon: Icon(
                          isAddedToLibrary
                              ? Icons.bookmark_added
                              : Icons.bookmark_add_outlined,
                          
                        ),
                        onPressed: () {
                          context
                              .read<LibraryService>()
                              .addToOrRemoveFromLibrary({
                                'endpoint': widget.endpoint,
                                ...state.header,
                              })
                              .then((String message) {
                                if (context.mounted) {
                                  BottomMessage.showText(context, message);
                                }
                              });
                        },
                      ),
                  ],
                ),
                body: SingleChildScrollView(
                  controller: _scrollController,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.only(
                        left: 8,
                        right: 8,
                        bottom: 8,
                      ),
                      constraints: const BoxConstraints(maxWidth: 1000),
                      child: Column(
                        children: [
                          if (state.header['thumbnails'] != null)
                            HeaderWidget(
                              header: {
                                'endpoint': widget.endpoint,
                                ...state.header,
                              },
                            ),
                          const SizedBox(height: 8),
                          ...state.sections.indexed.map((sec) {
                            return SectionItem(
                              section: sec.$2,
                              isMore:
                                  widget.isMore ||
                                  state.sections.length == 1 ||
                                  sec.$1 == 0,
                            );
                          }),
                          if (!state.loadingMore && state.continuation != null)
                            const SizedBox(height: 64),
                          if (state.loadingMore)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(8.0),
                                child: ExpressiveLoadingIndicator(),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
          }
        },
      ),
    );
  }
}

class HeaderWidget extends StatefulWidget {
  const HeaderWidget({super.key, required this.header});

  final Map<String, dynamic> header;

  @override
  State<HeaderWidget> createState() => _HeaderWidgetState();
}

class _HeaderWidgetState extends State<HeaderWidget> {
  // late bool isAddedToLibrary;

  @override
  initState() {
    super.initState();
  }

  Widget _buildImage(
    BuildContext context,
    List thumbnails,
    double maxWidth, {
    bool isRound = false,
  }) {
    return isRound
        ? CircleAvatar(
            backgroundImage: CachedNetworkImageProvider(
              getEnhancedImage(
                thumbnails.first['url'],
                dp: MediaQuery.of(context).devicePixelRatio,
                width: 250,
              ),
            ),
            radius: 125,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          )
        : ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: getEnhancedImage(
                thumbnails.last['url'],
                dp: MediaQuery.of(context).devicePixelRatio,
                width: 250,
              ),
              filterQuality: FilterQuality.high,
              width: 250,
              height: 250,
            ),
          );
  }

  Padding _buildContent(
    Map header,
    BuildContext context, {
    bool isRow = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        crossAxisAlignment: isRow
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        mainAxisAlignment: isRow
            ? MainAxisAlignment.start
            : MainAxisAlignment.center,
        children: [
          if (header['subtitle'] != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(header['subtitle'] ?? '', maxLines: 2),
            ),
          if (header['secondSubtitle'] != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(header['secondSubtitle']),
            ),
          if (header['description'] != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: ExpandableText(
                header['description'].split('\n')[0],
                expandText: S.of(context).Show_More,
                collapseText: S.of(context).Show_Less,
                maxLines: isRow ? 3 : 2,
                style: TextStyle(color: context.subtitleColor),
                textAlign: TextAlign.center,
              ),
            ),
          if (header['playlistId'] != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Wrap(
                spacing: 4,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                runAlignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (header['videoId'] != null || header['playlistId'] != null)
                    FilledButton.icon(
                      style: const ButtonStyle(
                        padding: WidgetStatePropertyAll(
                          .symmetric(horizontal: 24, vertical: 16),
                        ),
                        shape: WidgetStatePropertyAll(
                          RoundedRectangleBorder(
                            borderRadius: .only(
                              topLeft: .circular(24),
                              bottomLeft: .circular(24),
                              topRight: .circular(8),
                              bottomRight: .circular(8),
                            ),
                          ),
                        ),
                      ),
                      onPressed: () async {
                        BottomMessage.showText(
                          context,
                          S.of(context).Songs_Will_Start_Playing_Soon,
                        );
                        await GetIt.I<MediaPlayer>().startPlaylistSongs(
                          Map.from(header),
                        );
                      },
                      label: const Text('Play All'),
                      icon: const Icon(FluentIcons.play_24_filled),
                    ),

                  FilledButton(
                    style: const ButtonStyle(
                      padding: WidgetStatePropertyAll(
                          .symmetric(horizontal: 8, vertical: 16),
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
                    child: const Icon(Icons.more_vert,size: 20,),
                    onPressed: () {
                      Modals.showPlaylistBottomModal(context, header);
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.maxFinite,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return constraints.maxWidth > 600
              ? Row(
                  children: [
                    if (widget.header['thumbnails'] != null)
                      _buildImage(
                        context,
                        widget.header['thumbnails'],
                        constraints.maxWidth,
                        isRound: widget.header['type'] == 'ARTIST',
                      ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: _buildContent(widget.header, context, isRow: true),
                    ),
                  ],
                )
              : Column(
                  children: [
                    if (widget.header['thumbnails'] != null)
                      _buildImage(
                        context,
                        widget.header['thumbnails'],
                        constraints.maxWidth,
                        isRound: widget.header['type'] == 'ARTIST',
                      ),
                    SizedBox(
                      height: widget.header['thumbnails'] != null ? 4 : 0,
                    ),
                    _buildContent(widget.header, context),
                  ],
                );
        },
      ),
    );
  }
}
