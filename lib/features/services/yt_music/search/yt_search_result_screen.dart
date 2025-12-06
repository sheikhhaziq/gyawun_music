import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gyawun_music/core/widgets/bottom_playing_padding.dart';
import 'package:gyawun_music/core/widgets/section_single_column.dart';
import 'package:gyawun_music/core/widgets/tiles/chip_tile.dart';

import 'cubit/search_cubit.dart';

class YTSearchResultView extends StatefulWidget {
  const YTSearchResultView({super.key});

  @override
  State<StatefulWidget> createState() => _YTSearchResultViewState();
}

class _YTSearchResultViewState extends State<YTSearchResultView> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SearchCubit, SearchState>(
      builder: (context, state) {
        if (state is SearchLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is SearchError) {
          return Center(child: Text('Error: ${state.message}'));
        }
        if (state is SearchSuccess) {
          final searchState = state.data;
          return CustomScrollView(
            slivers: [
              if (searchState.chips.isNotEmpty)
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 32,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      itemCount: searchState.chips.length,
                      separatorBuilder: (context, index) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final chip = searchState.chips[index];
                        return ChipTile(chip: chip);
                      },
                    ),
                  ),
                ),
              for (final section in searchState.sections) ...[
                SectionSingleColumn(items: section.items),
              ],
              const SliverToBoxAdapter(child: BottomPlayingPadding()),
            ],
          );
        }

        return const SizedBox();
      },
    );
  }
}
