import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:gyawun/core/extensions/string_extensions.dart';
import 'package:gyawun/core/utils/expressive_sheet.dart';
import 'package:gyawun/core/widgets/expressive_app_bar.dart';
import 'package:gyawun/core/widgets/expressive_list_group.dart';
import 'package:gyawun/core/widgets/expressive_list_tile.dart';
import 'package:gyawun/core/widgets/expressive_switch_list_tile.dart';
import 'package:gyawun/screens/settings/widgets/color_icon.dart';
import 'package:gyawun/services/settings_manager.dart';

import '../../../generated/l10n.dart';
import 'cubit/appearance_cubit.dart';

class AppearancePage extends StatelessWidget {
  const AppearancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AppearanceCubit(),
      child: Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              ExpressiveAppBar(
                title: S.of(context).Appearence,
                hasLeading: true,
              ),
            ];
          },
          body: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: BlocBuilder<AppearanceCubit, AppearanceState>(
                builder: (context, state) {
                  final s = state as AppearanceLoaded;

                  return ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    children: [
                      ExpressiveListGroup(
                        title: 'Theme',
                        children: [
                          ExpressiveListTile(
                            title: Text(S.of(context).Theme_Mode),
                            subtitle: Text(s.themeMode.name.capitalize()),
                            leading: SettingsColorIcon(
                              icon: FluentIcons.dark_theme_24_filled,
                            ),
                            onTap: () async {
                              final selected =
                                  await ExpressiveSheet.showSelection(
                                    context,
                                    title: "Choose Theme",
                                    options: [
                                      ExpressiveSheetOption(
                                        label: "System Default",
                                        icon: FluentIcons.system_24_filled,
                                        value: ThemeMode.system,
                                      ),
                                      ExpressiveSheetOption(
                                        label: "Light Mode",
                                        icon: FluentIcons.lightbulb_24_filled,
                                        value: ThemeMode.light,
                                      ),
                                      ExpressiveSheetOption(
                                        label: "Dark Mode",
                                        icon: FluentIcons.dark_theme_24_filled,
                                        value: ThemeMode.dark,
                                      ),
                                    ],
                                  );
                              if (selected == null) return;
                              if (context.mounted) {
                                context.read<AppearanceCubit>().setThemeMode(
                                  selected,
                                );
                              }
                            },
                          ),
                          ExpressiveListTile(
                            title: Text('Accent Color'),
                            leading: SettingsColorIcon(
                              icon: FluentIcons.color_24_filled,
                            ),
                            trailing: CircleAvatar(
                              radius: 20,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Row(
                                  children: [
                                    Container(
                                      color: s.accentColor ?? Colors.black,
                                      width: 20,
                                    ),
                                    Container(
                                      color: s.accentColor ?? Colors.white,
                                      width: 20,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            onTap: () async {
                              final selected =
                                  await ExpressiveSheet.showColorSelection(
                                    context,
                                    title: 'Select Accent Color',
                                  );
                              if (selected != null) {
                                GetIt.I<SettingsManager>().accentColor =
                                    selected;
                              }
                            },
                          ),
                          ExpressiveSwitchListTile(
                            title: Text('Amoled Black'),
                            leading: const SettingsColorIcon(
                              icon: FluentIcons.drop_24_filled,
                            ),
                            value: s.amoledBlack,
                            onChanged: (value) {
                              context.read<AppearanceCubit>().setAmoledBlack(
                                value,
                              );
                            },
                          ),

                          /// Dynamic colors
                          ExpressiveSwitchListTile(
                            title: Text(S.of(context).Dynamic_Colors),
                            leading: const SettingsColorIcon(
                              icon: FluentIcons.color_background_24_filled,
                            ),
                            value: s.dynamicColors,
                            onChanged: (value) {
                              context.read<AppearanceCubit>().setDynamicColors(
                                value,
                              );
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
