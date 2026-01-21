import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gyawun/core/widgets/expressive_app_bar.dart';
import 'package:gyawun/core/widgets/expressive_list_group.dart';
import 'package:gyawun/core/widgets/expressive_list_tile.dart';
import 'package:gyawun/core/widgets/expressive_switch_list_tile.dart';
import 'package:gyawun/screens/settings/widgets/color_icon.dart';

import '../../../../generated/l10n.dart';
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
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [ExpressiveAppBar(title: "Privacy", hasLeading: true)];
        },
        body: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: BlocBuilder<PrivacyCubit, PrivacyState>(
              builder: (context, state) {
                final cubit = context.read<PrivacyCubit>();

                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    ExpressiveListGroup(
                      title: "Playback",
                      children: [
                        ExpressiveSwitchListTile(
                          title: Text(S.of(context).Enable_Playback_History),
                          leading: const SettingsColorIcon(
                            icon: Icons.play_arrow_rounded,
                          ),
                          value: state.playbackHistory,
                          onChanged: cubit.togglePlaybackHistory,
                        ),

                        ExpressiveListTile(
                          title: Text(S.of(context).Delete_Playback_History),
                          leading: const SettingsColorIcon(
                            icon: FluentIcons.history_dismiss_24_filled,
                          ),
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
                      ],
                    ),
                    SizedBox(height: 24),
                    ExpressiveListGroup(
                      title: "Search",
                      children: [
                        ExpressiveSwitchListTile(
                          title: Text(S.of(context).Enable_Search_History),
                          leading: const SettingsColorIcon(
                            icon: Icons.saved_search_rounded,
                          ),
                          value: state.searchHistory,
                          onChanged: cubit.toggleSearchHistory,
                        ),

                        ExpressiveListTile(
                          title: Text(S.of(context).Delete_Search_History),
                          leading: const SettingsColorIcon(
                            icon: Icons.manage_search_rounded,
                          ),
                          onTap: () async {
                            final confirm = await Modals.showConfirmBottomModal(
                              context,
                              message: S
                                  .of(context)
                                  .Delete_Search_History_Confirm_Message,
                              isDanger: true,
                            );

                            if (confirm == true) {
                              cubit.clearSearchHistory();
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
