import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gyawun/screens/library/downloads/downloading/widgets/downloading_section_tile.dart';

import '../../../../../generated/l10n.dart';
import 'cubit/downloading_cubit.dart';
import 'widgets/downloading_song_tile.dart';

class DownloadingPage extends StatelessWidget {
  const DownloadingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DownloadingCubit()..load(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(S.of(context).Downloading),
          centerTitle: true,
        ),
        body: BlocBuilder<DownloadingCubit, DownloadingState>(
          builder: (context, state) {
            return switch (state) {
              DownloadingLoading() =>
                const Center(child: CircularProgressIndicator()),
              DownloadingError(:final message) => Center(child: Text(message)),
              DownloadingLoaded(
                :final downloading,
                :final queued,
              ) =>
                CustomScrollView(
                  slivers: [
                    if (downloading.isNotEmpty) ...[
                      SliverToBoxAdapter(
                        child: DownloadingSectionTile(
                          title: S.of(context).In_Progress,
                        ),
                      ),
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => DownloadingSongTile(
                            song: downloading[index],
                          ),
                          childCount: downloading.length,
                        ),
                      ),
                    ],
                    if (queued.isNotEmpty) ...[
                      SliverToBoxAdapter(
                        child: DownloadingSectionTile(
                          title: S.of(context).QueuedCount(queued.length),
                        ),
                      ),
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => DownloadingSongTile(
                            song: queued[index],
                          ),
                          childCount: queued.length,
                        ),
                      ),
                    ],
                  ],
                ),
            };
          },
        ),
      ),
    );
  }
}
