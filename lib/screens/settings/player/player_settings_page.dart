import 'dart:io';

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../generated/l10n.dart';
import '../widgets/setting_item.dart';
import 'cubit/player_settings_cubit.dart';

class PlayerSettingsPage extends StatelessWidget {
  const PlayerSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PlayerSettingsCubit(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Player"),
        ),
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
                    /// Equalizer
                    SettingTile(
                      title: S.of(context).Loudness_And_Equalizer,
                      leading: const Icon(Icons.equalizer_rounded),
                      isFirst: true,
                      isLast: !Platform.isAndroid,
                      onTap: () {
                        context.go(
                          '/settings/player/equalizer',
                        );
                      },
                    ),

                    /// Skip silence
                    if (!Platform.isWindows)
                      SettingSwitchTile(
                        title: S.of(context).Skip_Silence,
                        leading: const Icon(
FluentIcons.fast_forward_24_filled                        ),
                        value: s.skipSilence,
                        onChanged: (value) {
                          context
                              .read<PlayerSettingsCubit>()
                              .setSkipSilence(value);
                        },
                        isFirst: !Platform.isAndroid,
                        isLast: true,
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
