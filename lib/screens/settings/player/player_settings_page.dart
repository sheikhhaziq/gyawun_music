import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:gyawun/core/widgets/expressive_app_bar.dart';
import 'package:gyawun/core/widgets/expressive_list_group.dart';
import 'package:gyawun/core/widgets/expressive_list_tile.dart';
import 'package:gyawun/core/widgets/expressive_switch_list_tile.dart';
import 'package:gyawun/screens/settings/widgets/color_icon.dart';

import '../../../generated/l10n.dart';
import 'cubit/player_settings_cubit.dart';

class PlayerSettingsPage extends StatelessWidget {
  const PlayerSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PlayerSettingsCubit(),
      child: Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [ExpressiveAppBar(title: "Player", hasLeading: true)];
          },
          body: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: BlocBuilder<PlayerSettingsCubit, PlayerSettingsState>(
                builder: (context, state) {
                  final s = state as PlayerSettingsLoaded;

                  return ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    children: [
                      ExpressiveListGroup(
                        children: [
                          ExpressiveListTile(
                            title: Text(S.of(context).Loudness_And_Equalizer),
                            leading: SettingsColorIcon(
                              icon: Icons.equalizer_rounded,
                            ),
                            trailing: Icon(FluentIcons.chevron_right_24_filled),
                            onTap: () =>
                                context.go('/settings/player/equalizer'),
                          ),
                          ExpressiveSwitchListTile(
                            title: Text(S.of(context).Skip_Silence),
                            leading: SettingsColorIcon(
                              icon: FluentIcons.fast_forward_24_filled,
                            ),
                            value: s.skipSilence,
                            onChanged: (value) {
                              context
                                  .read<PlayerSettingsCubit>()
                                  .setSkipSilence(value);
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
      ),
    );
  }
}
