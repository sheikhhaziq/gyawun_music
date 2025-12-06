import 'package:expressive_refresh/expressive_refresh.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gyawun_music/core/di.dart';
import 'package:gyawun_music/core/utils/item_click_handler.dart';
import 'package:gyawun_music/core/widgets/bottom_playing_padding.dart';
import 'package:gyawun_music/core/widgets/carousel_card.dart';
import 'package:gyawun_music/core/widgets/section_widget.dart';
import 'package:gyawun_music/core/widgets/tiles/chip_tile.dart';
import 'package:gyawun_shared/gyawun_shared.dart';
import 'package:library_manager/library_manager.dart';
import 'package:ytmusic/ytmusic.dart';

import 'cubit/home_cubit.dart';

class YTHomeScreen extends StatelessWidget {
  const YTHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(create: (_) => HomeCubit(sl<YTMusic>()), child: const YTHomeScreenView());
  }
}

class YTHomeScreenView extends StatefulWidget {
  const YTHomeScreenView({super.key});

  @override
  State<YTHomeScreenView> createState() => _YTHomeScreenViewState();
}

class _YTHomeScreenViewState extends State<YTHomeScreenView> {
  final ScrollController _scrollController = ScrollController();

  late List<PlayableItem> recentlyPlayed;

  void scrollListener() {
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 200) {
      context.read<HomeCubit>().loadMore();
    }
  }

  @override
  void initState() {
    super.initState();
    recentlyPlayed = sl<LibraryManager>().getRecentlyPlayed(size: 10);
    context.read<HomeCubit>().fetchData();
    _scrollController.addListener(scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> refreshPage() async {
    recentlyPlayed = sl<LibraryManager>().getRecentlyPlayed(size: 10);
    await context.read<HomeCubit>().refreshdata();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, homeState) {
        if (homeState is HomeLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (homeState is HomeError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Error: ${homeState.message}'),
                FilledButton.icon(
                  onPressed: () {
                    context.read<HomeCubit>().fetchData();
                  },
                  label: const Text('Refresh'),
                  icon: const Icon(FluentIcons.arrow_clockwise_24_filled),
                ),
              ],
            ),
          );
        }
        if (homeState is HomeSuccess) {
          final homePage = homeState.data;
          return ExpressiveRefreshIndicator(
            onRefresh: refreshPage,
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: SizedBox(
                      height: 32,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        scrollDirection: Axis.horizontal,
                        itemCount: homePage.chips.length,
                        separatorBuilder: (context, index) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final chip = homePage.chips[index];
                          return ChipTile(chip: chip);
                        },
                      ),
                    ),
                  ),
                ),
                if (recentlyPlayed.length >= 5)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    sliver: SliverToBoxAdapter(
                      child: Text(
                        'Recently Played',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                if (recentlyPlayed.length >= 5)
                  SliverToBoxAdapter(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 300),
                      child: CarouselView(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        itemSnapping: true,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemExtent: 300,
                        onTap: (index) {
                          onSectionItemTap(context, recentlyPlayed[index]);
                        },
                        children: recentlyPlayed.map((item) => CarouselCard(item: item)).toList(),
                      ),
                    ),
                  ),
                SectionsWidget(sections: homePage.sections),
                if (homeState.loadingMore)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),
                const SliverToBoxAdapter(child: BottomPlayingPadding()),
              ],
            ),
          );
        }
        return const SizedBox();
      },
    );
  }
}
