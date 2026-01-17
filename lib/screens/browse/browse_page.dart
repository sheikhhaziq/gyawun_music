import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:expandable_text/expandable_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:gyawun/core/utils/service_locator.dart';
import 'package:gyawun/screens/browse/cubit/browse_cubit.dart';
import 'package:gyawun/core/widgets/section_item.dart';
import 'package:gyawun/utils/internet_guard.dart';
import 'package:loading_indicator_m3e/loading_indicator_m3e.dart';
import 'package:provider/provider.dart';

import '../../generated/l10n.dart';
import '../../services/bottom_message.dart';
import '../../services/library.dart';
import '../../services/media_player.dart';
import '../../themes/colors.dart';
import '../../utils/adaptive_widgets/adaptive_widgets.dart';
import '../../utils/bottom_modals.dart';
import '../../utils/enhanced_image.dart';
import '../../ytmusic/ytmusic.dart';
import '../../utils/extensions.dart';

class BrowsePage extends StatelessWidget {
  final Map<String, dynamic> endpoint;
  final bool isMore;
  const BrowsePage({
    super.key,
    required this.endpoint,
    this.isMore = false,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => BrowseCubit(sl(), endpoint: endpoint)..fetch(),
      child: _BrowsePage(
        endpoint: endpoint,
        isMore: isMore,
      ),
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
  YTMusic ytMusic = GetIt.I<YTMusic>();
  bool initialLoading = false;
  bool nextLoading = false;
  late Map header = {};
  late List<Map<String, dynamic>> sections = [];
  String? continuation;
  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
    fetchData();
  }

  @override
  void didUpdateWidget(covariant _BrowsePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.endpoint['browseId'] != widget.endpoint['browseId']) {
      fetchData();
    }
  }

  Future<void> fetchData() async {
    setState(() {
      initialLoading = true;
      nextLoading = false;
    });
    Map<String, dynamic> response =
        await ytMusic.browse(body: widget.endpoint, limit: 2);
    if (mounted) {
      setState(() {
        initialLoading = false;
        nextLoading = false;
        header = response['header'] ?? {};
        sections = response['sections'];
        continuation = response['continuation'];
      });
    }
  }

  Future<void> fetchNext() async {
    if (continuation == null) return;
    setState(() {
      nextLoading = true;
    });
    Map<String, dynamic> home =
        await ytMusic.browseContinuation(additionalParams: continuation!);
    List<Map<String, dynamic>>? secs =
        home['sections']?.cast<Map<String, dynamic>>();
    if (mounted) {
      setState(() {
        sections.addAll(secs ?? []);
        continuation = home['continuation'];
        nextLoading = false;
      });
    }
  }

  Future<void> _scrollListener() async {
    if (initialLoading || nextLoading || continuation == null) {
      return;
    }

    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      await fetchNext();
    }
  }

  @override
  Widget build(BuildContext context) {
    return InternetGuard(
      onInternetRestored: fetchData,
      child: Scaffold(
        appBar: AppBar(
          title: header['title'] != null ? Text(header['title']) : null,
          centerTitle: true,
        ),

        body: BlocBuilder<BrowseCubit, BrowseState>(
          builder: (context, state) {
            switch (state) {
              case BrowseLoading():
                return Center(
                  child: LoadingIndicatorM3E(),
                );
              case BrowseError():
                return Center(
                  child: Text(state.message ?? ''),
                );
              case BrowseSuccess():
                return SingleChildScrollView(
                  controller: _scrollController,
                  child: Center(
                    child: Container(
                      padding:
                          const EdgeInsets.only(left: 8, right: 8, bottom: 8),
                      constraints: const BoxConstraints(maxWidth: 1000),
                      child: Column(
                        children: [
                          if (state.header['thumbnails'] != null)
                            HeaderWidget(
                              header: {'endpoint': widget.endpoint, ...header},
                            ),
                          const SizedBox(height: 8),
                          ...state.sections.indexed.map((sec) {
                            return SectionItem(
                                section: sec.$2,
                                isMore: widget.isMore ||
                                    sections.length == 1 ||
                                    sec.$1 == 0);
                          }),
                          if (!state.loadingMore && state.continuation != null)
                            const SizedBox(height: 64),
                          if (state.loadingMore)
                            const Center(
                              child: Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: ExpressiveLoadingIndicator()),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
            }
          },
        ),
        // body: initialLoading
        //     ? const Center(child: AdaptiveProgressRing())
        //     : SingleChildScrollView(
        //         controller: _scrollController,
        //         child: Center(
        //           child: Container(
        //             padding:
        //                 const EdgeInsets.only(left: 8, right: 8, bottom: 8),
        //             constraints: const BoxConstraints(maxWidth: 1000),
        //             child: Column(
        //               children: [
        //                 if (header['thumbnails'] != null)
        //                   HeaderWidget(
        //                     header: {'endpoint': widget.endpoint, ...header},
        //                   ),
        //                 const SizedBox(height: 8),
        //                 ...sections.indexed.map((sec) {
        //                   return SectionItem(
        //                       section: sec.$2,
        //                       isMore: widget.isMore ||
        //                           sections.length == 1 ||
        //                           sec.$1 == 0);
        //                 }),
        //                 if (!nextLoading && continuation != null)
        //                   const SizedBox(height: 64),
        //                 if (nextLoading)
        //                   const Center(
        //                     child: Padding(
        //                         padding: EdgeInsets.all(8.0),
        //                         child: AdaptiveProgressRing()),
        //                   ),
        //               ],
        //             ),
        //           ),
        //         ),
        //       ),
      ),
    );
  }
}

class HeaderWidget extends StatefulWidget {
  const HeaderWidget({
    super.key,
    required this.header,
  });

  final Map<String, dynamic> header;

  @override
  State<HeaderWidget> createState() => _HeaderWidgetState();
}

class _HeaderWidgetState extends State<HeaderWidget> {
  late bool isAddedToLibrary;

  @override
  initState() {
    super.initState();
  }

  Widget _buildImage(BuildContext context, List thumbnails, double maxWidth,
      {bool isRound = false}) {
    return isRound
        ? CircleAvatar(
            backgroundImage: CachedNetworkImageProvider(
              getEnhancedImage(thumbnails.first['url'],
                  dp: MediaQuery.of(context).devicePixelRatio, width: 250),
            ),
            radius: 125,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          )
        : ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: getEnhancedImage(thumbnails.last['url'],
                  dp: MediaQuery.of(context).devicePixelRatio, width: 250),
              filterQuality: FilterQuality.high,
              width: 250,
              height: 250,
            ),
          );
  }

  Padding _buildContent(Map header, BuildContext context,
      {bool isRow = false}) {
    if (widget.header['playlistId'] != null) {
      isAddedToLibrary = context
              .watch<LibraryService>()
              .getPlaylist(widget.header['playlistId']) !=
          null;
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        crossAxisAlignment:
            isRow ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        mainAxisAlignment:
            isRow ? MainAxisAlignment.start : MainAxisAlignment.center,
        children: [
          if (header['subtitle'] != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                header['subtitle'] ?? '',
                maxLines: 2,
              ),
            ),
          if (header['secondSubtitle'] != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                header['secondSubtitle'],
              ),
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
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                runAlignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (header['privacy'] != 'PRIVATE' &&
                      header['playlistId'] != 'LM')
                    AdaptiveFilledButton(
                      shape: const CircleBorder(),
                      color: greyColor,
                      padding: const EdgeInsets.all(14),
                      onPressed: () => context
                          .read<LibraryService>()
                          .addToOrRemoveFromLibrary(header)
                          .then((String message) {
                        BottomMessage.showText(context, message);
                      }),
                      child: Icon(
                        isAddedToLibrary
                            ? AdaptiveIcons.library_add_check
                            : AdaptiveIcons.library_add,
                        size: 20,
                        color: context.isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                  if (header['videoId'] != null || header['playlistId'] != null)
                    AdaptiveFilledButton(
                      onPressed: () async {
                        BottomMessage.showText(context,
                            S.of(context).Songs_Will_Start_Playing_Soon);
                        await GetIt.I<MediaPlayer>()
                            .startPlaylistSongs(Map.from(header));
                      },
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(Platform.isWindows ? 8 : 35),
                      ),
                      color: context.isDarkMode ? Colors.white : Colors.black,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(
                            AdaptiveIcons.play,
                            color: context.isDarkMode
                                ? Colors.black
                                : Colors.white,
                            size: 26,
                          ),
                          const SizedBox(width: 8),
                          const Text("Play All", style: TextStyle(fontSize: 18))
                        ],
                      ),
                    ),
                  AdaptiveFilledButton(
                    shape: const CircleBorder(),
                    color: greyColor,
                    padding: const EdgeInsets.all(14),
                    onPressed: () {
                      Modals.showPlaylistBottomModal(context, header);
                    },
                    child: Icon(
                      AdaptiveIcons.more_vertical,
                      size: 20,
                      color: context.isDarkMode ? Colors.white : Colors.black,
                    ),
                  )
                ],
              ),
            )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.maxFinite,
      child: Adaptivecard(
        // margin: const EdgeInsets.all(16),
        child: LayoutBuilder(builder: (context, constraints) {
          return constraints.maxWidth > 600
              ? Row(
                  children: [
                    if (widget.header['thumbnails'] != null)
                      _buildImage(context, widget.header['thumbnails'],
                          constraints.maxWidth,
                          isRound: widget.header['type'] == 'ARTIST'),
                    const SizedBox(width: 4),
                    Expanded(
                        child:
                            _buildContent(widget.header, context, isRow: true)),
                  ],
                )
              : Column(
                  children: [
                    if (widget.header['thumbnails'] != null)
                      _buildImage(context, widget.header['thumbnails'],
                          constraints.maxWidth,
                          isRound: widget.header['type'] == 'ARTIST'),
                    SizedBox(
                        height: widget.header['thumbnails'] != null ? 4 : 0),
                    _buildContent(widget.header, context),
                  ],
                );
        }),
      ),
    );
  }
}
