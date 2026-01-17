import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../generated/l10n.dart';
import '../widgets/setting_item.dart';
import '../../../utils/adaptive_widgets/adaptive_widgets.dart';
import '../../../utils/bottom_modals.dart';
import 'cubit/appearance_cubit.dart';

class AppearancePage extends StatelessWidget {
  const AppearancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AppearanceCubit(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(S.of(context).Appearence),
        ),
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
                    GroupTitle(title: "Theme"),

                    /// Theme mode
                    SettingTile(
                      title: S.of(context).Theme_Mode,
                      leading: const Icon(Icons.dark_mode),
                      isFirst: true,
                      trailing: AdaptiveDropdownButton<ThemeMode>(
                        value: s.themeMode,
                        items: ThemeMode.values
                            .map(
                              (e) => AdaptiveDropdownMenuItem(
                                value: e,
                                child: Text(
                                  e.name.toUpperCase(),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          context.read<AppearanceCubit>().setThemeMode(value);
                        },
                      ),
                    ),

                    /// Accent color
                    SettingTile(
                      title: "AccentColor",
                      leading: const Icon(Icons.colorize_rounded),
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
                      onTap: () => Modals.showAccentSelector(context),
                    ),

                    /// AMOLED
                    SettingSwitchTile(
                      title: 'Amoled Black',
                      leading: const Icon(
                        Icons.mode_night_outlined,
                      ),
                      value: s.amoledBlack,
                      onChanged: (value) {
                        context.read<AppearanceCubit>().setAmoledBlack(value);
                      },
                    ),

                    /// Dynamic colors
                    SettingSwitchTile(
                      title: S.of(context).Dynamic_Colors,
                      leading: const Icon(
                        Icons.color_lens_outlined,
                      ),
                      isLast: true,
                      value: s.dynamicColors,
                      onChanged: (value) {
                        context.read<AppearanceCubit>().setDynamicColors(value);
                      },
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
