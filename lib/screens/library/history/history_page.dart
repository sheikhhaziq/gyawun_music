import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_swipe_action_cell/core/cell.dart';
import 'package:gyawun/core/widgets/song_tile.dart';
import 'package:gyawun/themes/text_styles.dart';

import '../../../../generated/l10n.dart';
import '../../../../utils/bottom_modals.dart';
import '../../../../utils/adaptive_widgets/adaptive_widgets.dart';
import 'cubit/history_cubit.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HistoryCubit()..load(),
      child: Scaffold(
        body: BlocBuilder<HistoryCubit, HistoryState>(
          builder: (context, state) {
            return switch (state) {
              HistoryLoading() => const Center(child: AdaptiveProgressRing()),
              HistoryError(:final message) => Center(child: Text(message)),
              HistoryLoaded(:final songs) => _HistoryBody(songs: songs),
            };
          },
        ),
      ),
    );
  }
}

class _HistoryBody extends StatelessWidget {
  const _HistoryBody({required this.songs});

  final List songs;

  @override
  Widget build(BuildContext context) {
    if (songs.isEmpty) {
      return Center(child: Text("No History Found"));
    }

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 1000),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                pinned: true,
                expandedHeight: 120,
                flexibleSpace: LayoutBuilder(
                  builder: (context, constraints) {
                    final maxHeight = 120.0;
                    final t = (constraints.maxHeight / (maxHeight + 30)).clamp(
                      0.0,
                      1.0,
                    );
                    final paddingLeft = lerpDouble(100, 16, t)!;

                    return FlexibleSpaceBar(
                      titlePadding: EdgeInsets.only(
                        left: paddingLeft,
                        bottom: 8,
                      ),
                      title: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            S.of(context).History,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textStyle(context).copyWith(fontSize: 16),
                          ),
                          SizedBox(height: 2),
                          Text(
                            S.of(context).nSongs(songs.length),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textStyle(context).copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ];
          },
          body: CustomScrollView(
            slivers: [
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final song = songs[index];
                  return Padding(
                    padding: const .symmetric(horizontal: 8, vertical: 4),
                    child: SwipeActionCell(
                      backgroundColor: Colors.transparent,
                      key: ObjectKey(song['videoId']),
                      trailingActions: [
                        SwipeAction(
                          title: S.of(context).Remove,
                          color: Colors.red,
                          onTap: (handler) async {
                            final confirm = await Modals.showConfirmBottomModal(
                              context,
                              message: S.of(context).Remove_Message,
                              isDanger: true,
                            );

                            if (confirm && context.mounted) {
                              context.read<HistoryCubit>().remove(
                                song['videoId'],
                              );
                            }
                          },
                        ),
                      ],
                      child: SongTile(song: song),
                    ),
                  );
                }, childCount: songs.length),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
