import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:gyawun/utils/internet_guard.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../generated/l10n.dart';
import '../../../services/media_player.dart';
import '../../../utils/adaptive_widgets/adaptive_widgets.dart';
import '../../../utils/bottom_modals.dart';
import '../../../ytmusic/ytmusic.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({this.endpoint, this.isMore = false, super.key});
  final Map<String, dynamic>? endpoint;
  final bool isMore;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late ScrollController _scrollController;
  TextEditingController? _textEditingController;
  FocusNode? _focusNode;
  bool initialLoading = false;
  bool nextLoading = false;
  List<Map<String, dynamic>> results = [];
  String? continuation;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
    _focusNode?.requestFocus();
    if (widget.endpoint != null) {
      search(widget.endpoint!);
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

  Future<void> onSubmit(String value) async {
    if (value.trim() == '') return;
    _focusNode?.unfocus();
    setState(() {
      initialLoading = true;
    });
    if (Hive.box('SETTINGS').get('SEARCH_HISTORY', defaultValue: true)) {
      await Hive.box('SEARCH_HISTORY').delete(value.toLowerCase());
      await Hive.box('SEARCH_HISTORY').put(value.toLowerCase(), value);
    }
    Map response = await GetIt.I<YTMusic>().search(value);
    if (response.isNotEmpty) {
      results = response['sections'];
      continuation = response['continuation'];
    }
    setState(() {
      initialLoading = false;
    });
  }

  Future<void> fetchNext() async {
    if (continuation == null) return;
    setState(() {
      nextLoading = true;
    });
    Map response = await GetIt.I<YTMusic>()
        .search('', endpoint: widget.endpoint, additionalParams: continuation!);
    results.addAll(response['sections']);
    continuation = response['continuation'];
    if (mounted) {
      setState(() {
        nextLoading = false;
      });
    }
  }

  Future<void> search(Map<String, dynamic> value,
      {String additionalParams = ''}) async {
    _textEditingController?.value = value['query'];
    setState(() {
      initialLoading = true;
    });
    Map response = await GetIt.I<YTMusic>()
        .search('', endpoint: value, additionalParams: additionalParams);
    results = response['sections'];
    continuation = response['continuation'];
    setState(() {
      initialLoading = false;
    });
  }

  Future<void> getSuggestions(String query) async {
    await GetIt.I<YTMusic>().getSearchSuggestions(query);
  }

  @override
  Widget build(BuildContext context) {
    return InternetGuard(
      onInternetLost: () {
        _focusNode?.unfocus();
      },
      onInternetRestored: () {
        if (widget.endpoint != null) {
          search(widget.endpoint!);
        } else {
          _focusNode?.requestFocus();
        }
      },
      child: AdaptiveScaffold(
        appBar: PreferredSize(
          preferredSize: const AdaptiveAppBar().preferredSize,
          child: LayoutBuilder(builder: (context, constraints) {
            return AdaptiveAppBar(
              title: widget.endpoint != null
                  ? Text(widget.endpoint!['query'])
                  : Material(
                      color: Colors.transparent,
                      child: Row(
                        children: [
                          Expanded(
                            child: TypeAheadField(
                              suggestionsCallback: (query) => GetIt.I<YTMusic>()
                                  .getSearchSuggestions(query),
                              builder: (context, controller, focusNode) {
                                _textEditingController = controller;
                                _focusNode = focusNode;
                                return AdaptiveTextField(
                                  focusNode: _focusNode,
                                  controller: _textEditingController,
                                  onSubmitted: onSubmit,
                                  onChanged: (value) {
                                    getSuggestions(value);
                                  },
                                  keyboardType: TextInputType.text,
                                  maxLines: 1,
                                  autofocus: true,
                                  textInputAction: TextInputAction.search,
                                  fillColor: Platform.isWindows
                                      ? null
                                      : Colors.grey.withValues(alpha: 0.3),
                                  contentPadding: const EdgeInsets.symmetric(
                                      vertical: 2, horizontal: 8),
                                  borderRadius: BorderRadius.circular(
                                      Platform.isWindows ? 4.0 : 35),
                                  hintText: S.of(context).Search_Gyawun,
                                  prefix: constraints.maxWidth > 400
                                      ? null
                                      : const AdaptiveBackButton(),
                                  suffix: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _textEditingController?.text = '';
                                      });
                                    },
                                    child: const Icon(CupertinoIcons.clear),
                                  ),
                                );
                              },
                              decorationBuilder: Platform.isWindows
                                  ? (context, child) {
                                      return Ink(
                                        padding: EdgeInsets.zero,
                                        decoration: BoxDecoration(
                                          color: AdaptiveTheme.of(context)
                                              .inactiveBackgroundColor,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: child,
                                      );
                                    }
                                  : null,
                              itemBuilder: (context, value) {
                                if (value['type'] == 'TEXT') {
                                  return AdaptiveListTile(
                                      leading: value['isHistory'] != null
                                          ? const Icon(Icons.history)
                                          : null,
                                      title: Text(value['query']),
                                      onTap: () {
                                        setState(() {
                                          _textEditingController?.text =
                                              value['query'];
                                        });
                                        onSubmit(value['query']);
                                      });
                                }
                                return SearchListTile(item: value);
                              },
                              onSelected: (value) => (),
                            ),
                          ),
                        ],
                      ),
                    ),
              automaticallyImplyLeading:
                  (constraints.maxWidth <= 400) ? false : true,
            );
          }),
        ),
        body: initialLoading
            ? const Center(child: AdaptiveProgressRing())
            : SingleChildScrollView(
                controller: _scrollController,
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 1000),
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      children: [
                        ...results.map((section) {
                          if (Platform.isWindows) {
                            return Center(
                              child: Adaptivecard(
                                borderRadius: BorderRadius.circular(8),
                                child: SearchSectionItem(
                                    section: section, isMore: widget.isMore),
                              ),
                            );
                          }
                          return SearchSectionItem(
                              section: section, isMore: widget.isMore);
                        }),
                        if (nextLoading)
                          const Center(child: AdaptiveProgressRing())
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

class SearchSectionItem extends StatelessWidget {
  const SearchSectionItem(
      {required this.section, this.isMore = false, super.key});
  final Map<String, dynamic> section;
  final bool isMore;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (section['title'] != null && !isMore)
          AdaptiveListTile(
            contentPadding:
                const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
            title: Text(
              section['title'],
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            trailing: section['trailing']?['text'] != null
                ? Padding(
                    padding: EdgeInsets.symmetric(
                        vertical: Platform.isAndroid ? 12 : 0),
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
                        )),
                  )
                : null,
          ),
        ...section['contents'].map((item) {
          return SearchListTile(item: item);
        })
      ],
    );
  }
}

class SearchListTile extends StatelessWidget {
  const SearchListTile({
    required this.item,
    super.key,
  });
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
          context.push(
            '/browse',
            extra: {
              'endpoint': item['endpoint'],
            },
          );
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
      title: Text(
        item['title'],
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
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
                  ['ARTIST', 'PROFILE'].contains(item['type']) ? 30 : 3),
              child: Image.network(
                item['thumbnails'].first['url'],
                width: 50,
              ))
          : null,
      trailing: item['videoId'] == null && item['endpoint'] != null
          ? const Icon(CupertinoIcons.chevron_right)
          : null,
    );
  }
}
