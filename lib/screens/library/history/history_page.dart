import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_swipe_action_cell/core/cell.dart';

import '../../../../generated/l10n.dart';
import '../../../../utils/bottom_modals.dart';
import '../../../../utils/adaptive_widgets/adaptive_widgets.dart';
import 'cubit/history_cubit.dart';
import '../../../../core/widgets/section_item.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HistoryCubit()..load(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(S.of(context).History),
          centerTitle: true,
        ),
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
      return Center(
        child: Text("No History Found"),
      );
    }

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 1000),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: ListView.builder(
          itemCount: songs.length,
          itemBuilder: (context, index) {
            final song = songs[index];

            return SwipeActionCell(
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
                      context.read<HistoryCubit>().remove(song['videoId']);
                    }
                  },
                ),
              ],
              child: SongTile(song: song),
            );
          },
        ),
      ),
    );
  }
}
