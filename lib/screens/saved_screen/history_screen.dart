import 'package:flutter/material.dart';
import 'package:flutter_swipe_action_cell/core/cell.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../generated/l10n.dart';
import '../../utils/adaptive_widgets/adaptive_widgets.dart';
import '../../utils/bottom_modals.dart';
import '../home_screen/section_item.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      appBar: AdaptiveAppBar(
        title: Text(S.of(context).History),
        centerTitle: true,
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1000),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: ValueListenableBuilder(
            valueListenable: Hive.box('SONG_HISTORY').listenable(),
            builder: (context, box, child) {
              List songs = box.values.toList();
              songs.sort((a, b) =>
                  (b['updatedAt'] ?? 0).compareTo((a['updatedAt'] ?? 0)));
              return ListView.builder(
                itemCount: songs.length,
                itemBuilder: (context, index) {
                  final song = songs[index];
                  return SwipeActionCell(
                    backgroundColor: Colors.transparent,
                    key: ObjectKey(song['videoId']),
                    trailingActions: <SwipeAction>[
                      SwipeAction(
                          title: S.of(context).Remove,
                          onTap: (CompletionHandler handler) async {
                            Modals.showConfirmBottomModal(
                              context,
                              message: S.of(context).Remove_Message,
                              isDanger: true,
                            ).then((bool confirm) async {
                              if (confirm) {
                                await box.delete(song['videoId']);
                              }
                            });
                          },
                          color: Colors.red),
                    ],
                    child: SongTile(song: song),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
