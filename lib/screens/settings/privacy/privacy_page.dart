import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../generated/l10n.dart';
import '../widgets/setting_item.dart';
import '../../../../utils/bottom_modals.dart';
import '../../../../services/bottom_message.dart';

import 'cubit/privacy_cubit.dart';

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PrivacyCubit(),
      child: BlocListener<PrivacyCubit, PrivacyState>(
        listenWhen: (_, state) => state.lastAction != null,
        listener: (context, state) {
          final action = state.lastAction;
          if (action == null) return;

          if (action == PrivacyAction.playbackDeleted) {
            BottomMessage.showText(
              context,
              S.of(context).Playback_History_Deleted,
            );
          } else if (action == PrivacyAction.searchDeleted) {
            BottomMessage.showText(
              context,
              S.of(context).Search_History_Deleted,
            );
          }

          context.read<PrivacyCubit>().consumeAction();
        },
        child: const _PrivacyView(),
      ),
    );
  }
}

class _PrivacyView extends StatelessWidget {
  const _PrivacyView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Privacy"),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: BlocBuilder<PrivacyCubit, PrivacyState>(
            builder: (context, state) {
              final cubit = context.read<PrivacyCubit>();

              return ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  GroupTitle(title: "Playback"),

                  /// PLAYBACK HISTORY ENABLE
                  SettingSwitchTile(
                    title: S.of(context).Enable_Playback_History,
                    leading: const Icon(Icons.manage_history_rounded),
                    isFirst: true,
                    value: state.playbackHistory,
                    onChanged: cubit.togglePlaybackHistory,
                  ),

                  /// DELETE PLAYBACK HISTORY
                  SettingTile(
                    title: S.of(context).Delete_Playback_History,
                    leading: const Icon(Icons.playlist_remove_rounded),
                    isLast: true,
                    onTap: () async {
                      final confirm = await Modals.showConfirmBottomModal(
                        context,
                        message: S
                            .of(context)
                            .Delete_Playback_History_Confirm_Message,
                        isDanger: true,
                      );

                      if (confirm == true) {
                        cubit.clearPlaybackHistory();
                      }
                    },
                  ),

                  GroupTitle(title: "Search"),

                  /// SEARCH HISTORY ENABLE
                  SettingSwitchTile(
                    title: S.of(context).Enable_Search_History,
                    leading: const Icon(Icons.saved_search_rounded),
                    isFirst: true,
                    value: state.searchHistory,
                    onChanged: cubit.toggleSearchHistory,
                  ),

                  /// DELETE SEARCH HISTORY
                  SettingTile(
                    title: S.of(context).Delete_Search_History,
                    leading: const Icon(Icons.highlight_remove_sharp),
                    isLast: true,
                    onTap: () async {
                      final confirm = await Modals.showConfirmBottomModal(
                        context,
                        message:
                            S.of(context).Delete_Search_History_Confirm_Message,
                        isDanger: true,
                      );

                      if (confirm == true) {
                        cubit.clearSearchHistory();
                      }
                    },
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
