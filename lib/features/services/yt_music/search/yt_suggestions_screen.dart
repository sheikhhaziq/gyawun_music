import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gyawun_music/core/di.dart';
import 'package:gyawun_music/core/widgets/tiles/section_column_title.dart';
import 'package:gyawun_music/features/services/yt_music/search/cubit/suggestion_cubit.dart';
import 'package:gyawun_music/features/settings/widgets/setting_tile.dart';
import 'package:library_manager/library_manager.dart';
import 'package:ytmusic/ytmusic.dart';

class YTSuggestionsScreen extends StatelessWidget {
  const YTSuggestionsScreen({super.key, this.query});
  final String? query;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SuggestionCubit(sl<YTMusic>())..fetchSuggestions(query),
      child: YTSuggestionsPage(query: query),
    );
  }
}

class YTSuggestionsPage extends StatefulWidget {
  const YTSuggestionsPage({super.key, this.query});
  final String? query;

  @override
  State<YTSuggestionsPage> createState() => _YTSuggestionsPageState();
}

class _YTSuggestionsPageState extends State<YTSuggestionsPage> {
  String? query;
  late TextEditingController controller;
  final libraryManager = sl<LibraryManager>();

  @override
  void initState() {
    super.initState();
    query = widget.query;
    controller = TextEditingController(text: widget.query);
  }

  @override
  void dispose() {
    super.dispose();
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Hero(
          tag: "searchBar",
          child: SearchBar(
            elevation: const WidgetStatePropertyAll(0),
            controller: controller,
            autoFocus: true,
            hintText: 'songs, artists, albums...',
            onChanged: (value) {
              setState(() {
                query = value.isEmpty ? null : value;
              });
              if (value.isNotEmpty) {
                context.read<SuggestionCubit>().fetchSuggestions(value);
              }
            },
            leading: IconButton(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            trailing: query == null
                ? null
                : [
                    IconButton(
                      onPressed: () {
                        query = null;
                        controller.text = '';
                        setState(() {});
                      },
                      icon: const Icon(FluentIcons.dismiss_24_filled),
                    ),
                  ],
            onSubmitted: (value) {
              if (value.isNotEmpty) {
                libraryManager.addSearchQuery(value);
              }
              Navigator.pop(context, value);
            },
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: query == null || query!.isEmpty ? _buildSearchHistory() : _buildSuggestions(),
      ),
    );
  }

  Widget _buildSearchHistory() {
    final searchItems = libraryManager.getSearchHistory(page: 0, size: 50);
    if (searchItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              FluentIcons.search_48_regular,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No search history',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return _AnimatedHistoryList(initialHistory: searchItems);
  }

  Widget _buildSuggestions() {
    return BlocBuilder<SuggestionCubit, SuggestionState>(
      builder: (context, state) {
        if (state is SuggestionLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is SuggestionError) {
          return Center(child: Text('Error: ${state.message}'));
        }
        if (state is SuggestionSuccess) {
          return CustomScrollView(
            slivers: [
              if (state.data.sectionItems.isNotEmpty)
                SliverList.separated(
                  itemCount: state.data.sectionItems.length,
                  itemBuilder: (context, index) {
                    final item = state.data.sectionItems[index];
                    return SectionColumnTile(
                      item: item,
                      isFirst: state.data.sectionItems.indexOf(item) == 0,
                      isLast:
                          state.data.sectionItems.indexOf(item) ==
                          state.data.sectionItems.length - 1,
                    );
                  },
                  separatorBuilder: (context, index) => const SizedBox(height: 2),
                ),
              if (state.data.textItems.isNotEmpty)
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
              if (state.data.textItems.isNotEmpty)
                SliverList.separated(
                  itemCount: state.data.textItems.length,
                  itemBuilder: (context, index) {
                    final item = state.data.textItems[index];
                    return SettingTile(
                      title: item,
                      leading: const Icon(FluentIcons.search_24_regular),
                      isFirst: state.data.textItems.indexOf(item) == 0,
                      isLast: state.data.textItems.indexOf(item) == state.data.textItems.length - 1,
                      onTap: () {
                        libraryManager.addSearchQuery(item);
                        Navigator.pop(context, item);
                      },
                    );
                  },
                  separatorBuilder: (context, index) => const SizedBox(height: 2),
                ),
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _AnimatedHistoryList extends StatefulWidget {
  const _AnimatedHistoryList({required this.initialHistory});
  final List<SearchHistoryItem> initialHistory;

  @override
  State<_AnimatedHistoryList> createState() => _AnimatedHistoryListState();
}

class _AnimatedHistoryListState extends State<_AnimatedHistoryList> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey();
  late List<SearchHistoryItem> _items;
  final libraryManager = sl<LibraryManager>();

  @override
  void initState() {
    super.initState();
    _items = List.of(widget.initialHistory);

    // animate items in
    Future.delayed(Duration.zero, () {
      for (int i = 0; i < _items.length; i++) {
        _listKey.currentState?.insertItem(i);
      }
    });
  }

  void _removeItem(int index) async {
    final removedItem = _items[index];

    // Remove visually first
    _listKey.currentState?.removeItem(
      index,
      (context, animation) => SizeTransition(
        sizeFactor: animation,
        axisAlignment: 0.0,
        child: FadeTransition(
          opacity: animation,
          child: SettingTile(
            title: removedItem.query,
            leading: const Icon(FluentIcons.history_24_regular),
          ),
        ),
      ),
      duration: const Duration(milliseconds: 250),
    );

    // Remove from list
    _items.removeAt(index);

    // Remove from DB
    await libraryManager.deleteSearchQuery(removedItem.id);
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent searches',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                TextButton(
                  onPressed: () async {
                    for (int i = _items.length - 1; i >= 0; i--) {
                      _removeItem(i);
                    }
                    await libraryManager.clearSearchHistoryAll();
                  },
                  child: const Text('Clear all'),
                ),
              ],
            ),
          ),
        ),

        // AnimatedList inside Sliver
        SliverToBoxAdapter(
          child: AnimatedList(
            key: _listKey,
            initialItemCount: 0,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index, animation) {
              final item = _items[index];

              return SizeTransition(
                sizeFactor: animation,
                child: SettingTile(
                  title: item.query,
                  leading: const Icon(FluentIcons.history_24_regular),
                  trailing: IconButton(
                    icon: const Icon(FluentIcons.dismiss_24_regular),
                    onPressed: () => _removeItem(index),
                  ),
                  onTap: () {
                    libraryManager.addSearchQuery(item.query);
                    Navigator.pop(context, item.query);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
