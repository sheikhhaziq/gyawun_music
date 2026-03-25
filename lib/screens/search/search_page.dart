import 'dart:io';

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:gyawun/core/widgets/internet_guard.dart';
import 'package:gyawun/core/utils/service_locator.dart';
import 'package:gyawun/screens/search/cubit/search_cubit.dart';
import 'package:loading_indicator_m3e/loading_indicator_m3e.dart';

import '../../../generated/l10n.dart';
import '../../../services/media_player.dart';
import '../../../utils/adaptive_widgets/adaptive_widgets.dart';
import '../../../utils/bottom_modals.dart';
import '../../core/widgets/tiles/section_list_tile.dart';

class SearchPage extends StatelessWidget {
  const SearchPage({super.key, this.endpoint, this.isMore = false});
  final Map<String, dynamic>? endpoint;
  final bool isMore;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SearchCubit(sl(), endpoint: endpoint),
      child: _SearchPage(title: endpoint?['query'], isMore: isMore),
    );
  }
}

class _SearchPage extends StatefulWidget {
  const _SearchPage({this.title, this.isMore = false});
  final String? title;
  final bool isMore;

  @override
  State<_SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<_SearchPage> with WidgetsBindingObserver {
  late ScrollController _scrollController;
  final TextEditingController _textEditingController = TextEditingController();
  final SuggestionsController _suggestionsController = SuggestionsController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
    WidgetsBinding.instance.addObserver(this);
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    _textEditingController.dispose();
    _suggestionsController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    if (_focusNode.hasFocus) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _suggestionsController.resize();
        }
      });
    }
  }

  Future<void> _scrollListener() async {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      await context.read<SearchCubit>().fetchNext();
    }
  }

  Future<void> onSubmit(String query) async {
    if (query.trim() == '') return;
    _focusNode.unfocus();
    await context.read<SearchCubit>().search(query);
  }

  @override
  Widget build(BuildContext context) {
    return InternetGuard(
      onConnectivityRestored: () {
        if (_textEditingController.text.isNotEmpty) {
          context.read<SearchCubit>().search(_textEditingController.text);
        }
      },
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const AdaptiveAppBar().preferredSize,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return AdaptiveAppBar(
                title: widget.title != null
                    ? Text(widget.title!)
                    : Material(
                        color: Colors.transparent,
                        child: Row(
                          children: [
                            Expanded(
                              child: TypeAheadField(
                                focusNode: _focusNode,
                                controller: _textEditingController,
                                suggestionsController: _suggestionsController,
                                suggestionsCallback: (query) => context
                                    .read<SearchCubit>()
                                    .getSuggestions(query),
                                loadingBuilder: (context) => Container(
                                  height: 60,
                                  alignment: Alignment.center,
                                  child: ExpressiveLoadingIndicator(),
                                ),
                                builder: (context, controller, focusNode) {
                                  return AdaptiveTextField(
                                    focusNode: focusNode,
                                    controller: controller,
                                    onSubmitted: onSubmit,
                                    keyboardType: TextInputType.text,
                                    maxLines: 1,
                                    autofocus: true,
                                    textInputAction: TextInputAction.search,
                                    fillColor: Theme.of(
                                      context,
                                    ).colorScheme.surfaceContainer,
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 2,
                                      horizontal: 8,
                                    ),
                                    borderRadius: BorderRadius.circular(
                                      Platform.isWindows ? 4.0 : 35,
                                    ),
                                    hintText: S.of(context).Search_Gyawun,
                                    prefix: constraints.maxWidth > 400
                                        ? null
                                        : const AdaptiveBackButton(),
                                    suffix: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _textEditingController.text = '';
                                        });
                                      },
                                      child: const Icon(
                                        FluentIcons.dismiss_24_filled,
                                      ),
                                    ),
                                  );
                                },
                                decorationBuilder: (context, child) {
                                  if (Platform.isWindows) {
                                    return Ink(
                                      padding: EdgeInsets.zero,
                                      decoration: BoxDecoration(
                                        color: AdaptiveTheme.of(
                                          context,
                                        ).inactiveBackgroundColor,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: child,
                                    );
                                  } else {
                                    return Material(
                                      elevation: 5,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.surfaceContainerLowest,
                                      borderRadius: BorderRadius.circular(10),
                                      child: child,
                                    );
                                  }
                                },
                                itemBuilder: (context, value) {
                                  if (value['type'] == 'TEXT') {
                                    return AdaptiveListTile(
                                      leading: value['isHistory'] != null
                                          ? const Icon(Icons.history)
                                          : null,
                                      title: Text(value['query']),
                                      onTap: () {
                                        setState(() {
                                          _textEditingController.text =
                                              value['query'];
                                        });
                                        onSubmit(value['query']);
                                      },
                                    );
                                  }
                                  return _SearchListTile(item: value);
                                },
                                onSelected: (value) => (),
                                hideOnEmpty: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                automaticallyImplyLeading: (constraints.maxWidth <= 400)
                    ? false
                    : true,
              );
            },
          ),
        ),
        body: BlocBuilder<SearchCubit, SearchState>(
          builder: (context, state) {
            switch (state) {
              case SearchInitial():
                return SizedBox.shrink();
              case SearchLoading():
                return Center(child: LoadingIndicatorM3E());
              case SearchError():
                return Center(child: Text(state.message ?? ''));
              case SearchSuccess():
                return SingleChildScrollView(
                  controller: _scrollController,
                  child: Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 1000),
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        children: [
                          ...state.sections.asMap().entries.map((entry) {
                            int index = entry.key;
                            var section = entry.value;
                            if (Platform.isWindows) {
                              return Center(
                                child: Adaptivecard(
                                  borderRadius: BorderRadius.circular(8),
                                  child: _SearchSectionItem(
                                    section: section,
                                    isFirst: index == 0,
                                    isMore: widget.isMore,
                                  ),
                                ),
                              );
                            }
                            return _SearchSectionItem(
                              section: section,
                              isFirst: index == 0,
                              isMore: widget.isMore,
                            );
                          }),
                          if (state.loadingMore)
                            const Center(child: ExpressiveLoadingIndicator()),
                        ],
                      ),
                    ),
                  ),
                );
            }
          },
        ),
      ),
    );
  }
}

class _SearchSectionItem extends StatelessWidget {
  const _SearchSectionItem({
    required this.section,
    this.isFirst = false,
    this.isMore = false,
  });
  final Map<String, dynamic> section;
  final bool isFirst;
  final bool isMore;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        children: [
          if (!isMore)
            AdaptiveListTile(
              contentPadding: const EdgeInsets.symmetric(
                vertical: 4,
                horizontal: 4,
              ),
              title: Text(
                section['title'] ?? isFirst
                    ? S().Top_Results
                    : S().Other_Results,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
              trailing: section['trailing']?['text'] != null
                  ? Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: Platform.isAndroid ? 12 : 0,
                      ),
                      child: AdaptiveOutlinedButton(
                        onPressed: () {
                          context.push(
                            '/search',
                            extra: {
                              'endpoint': section['trailing']['endpoint'],
                              'isMore': true,
                            },
                          );
                        },
                        child: Text(
                          section['trailing']['text'],
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    )
                  : null,
            ),
          ...section['contents'].asMap().entries.map((entry) {
            int index = entry.key;
            var item = entry.value;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 1, horizontal: 4),
              child: SectionListTile(
                item: item,
                isFirst: index == 0,
                isLast: index == section['contents'].length - 1,
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}

class _SearchListTile extends StatelessWidget {
  const _SearchListTile({required this.item});
  final Map item;
  @override
  Widget build(BuildContext context) {
    return AdaptiveListTile(
      onSecondaryTap: () {
        if (item['videoId'] != null) {
          Modals.showSongBottomModal(context, item);
        } else if (item['endpoint'] != null) {
          Modals.showPlaylistBottomModal(context, item);
        }
      },
      onTap: () async {
        if (item['videoId'] != null) {
          await GetIt.I<MediaPlayer>().playSong(Map.from(item));
        } else if (item['endpoint'] != null && item['videoId'] == null) {
          context.push('/browse', extra: {'endpoint': item['endpoint']});
        }
      },
      onLongPress: () {
        if (item['videoId'] != null) {
          Modals.showSongBottomModal(context, item);
        } else if (item['endpoint'] != null) {
          Modals.showPlaylistBottomModal(context, item);
        }
      },
      dense: false,
      title: Text(item['title'], maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: item['subtitle'] != null
          ? Text(
              item['subtitle'],
              maxLines: 1,
              style: TextStyle(color: Colors.grey.withValues(alpha: 0.9)),
              overflow: TextOverflow.ellipsis,
            )
          : null,
      leading: item['thumbnails'] != null && item['thumbnails'].isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(
                ['ARTIST', 'PROFILE'].contains(item['type']) ? 30 : 3,
              ),
              child: Image.network(item['thumbnails'].first['url'], width: 50),
            )
          : null,
      trailing: item['videoId'] == null && item['endpoint'] != null
          ? const Icon(CupertinoIcons.chevron_right)
          : null,
    );
  }
}
