import 'dart:io';

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:gyawun/core/widgets/expressive_app_bar.dart';
import 'package:gyawun/core/widgets/expressive_list_group.dart';
import 'package:gyawun/core/widgets/expressive_list_tile.dart';
import 'package:gyawun/services/update_service/update_service.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../generated/l10n.dart';
import '../../themes/text_styles.dart';
import '../../utils/adaptive_widgets/adaptive_widgets.dart';
import '../../utils/bottom_modals.dart';
import 'widgets/color_icon.dart';
import 'cubit/settings_system_cubit.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SettingsSystemCubit()..load(),
      child: AdaptiveScaffold(
        body: BlocBuilder<SettingsSystemCubit, SettingsSystemState>(
          builder: (context, state) {
            final bool? batteryDisabled = state is SettingsSystemLoaded
                ? state.isBatteryOptimizationDisabled
                : null;

            return Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: NestedScrollView(
                  headerSliverBuilder: (context, innerBoxIsScrolled) {
                    return [ExpressiveAppBar(title: S.of(context).Settings)];
                  },
                  body: ListView(
                    padding: .symmetric(horizontal: 16, vertical: 8),
                    children: [
                      if (Platform.isAndroid && batteryDisabled != true)
                        _BatteryWarningTile(),
                      if (Platform.isAndroid && batteryDisabled != true)
                        SizedBox(height: 24),
                      ExpressiveListGroup(
                        title: "General",
                        children: [
                          ExpressiveListTile(
                            leading: SettingsColorIcon(
                              icon: FluentIcons.color_background_24_filled,
                              color: const Color.fromARGB(155, 183, 86, 118),
                            ),
                            title: Text(S.of(context).Appearence),
                            subtitle: Text('Themes, layout, and visual style'),
                            onTap: () => context.go('/settings/appearance'),
                            trailing: const Icon(
                              FluentIcons.chevron_right_24_filled,
                            ),
                          ),
                          ExpressiveListTile(
                            leading: SettingsColorIcon(
                              icon: FluentIcons.play_24_filled,
                              color: const Color.fromARGB(155, 70, 92, 141),
                            ),
                            title: Text('Player'),
                            subtitle: Text('Audio effects & playback'),
                            onTap: () => context.go('/settings/player'),
                            trailing: const Icon(
                              FluentIcons.chevron_right_24_filled,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 24),

                      ExpressiveListGroup(
                        title: "Services",
                        children: [
                          ExpressiveListTile(
                            leading: SettingsColorIcon(
                              icon: Icons.play_circle_fill,
                              color: const Color.fromARGB(155, 181, 54, 54),
                            ),
                            title: Text('Youtube Music'),
                            subtitle: Text(
                              'Content region, language, audio quality',
                            ),
                            onTap: () =>
                                context.go('/settings/services/ytmusic'),
                            trailing: const Icon(
                              FluentIcons.chevron_right_24_filled,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 24),

                      ExpressiveListGroup(
                        title: "Storage & Privacy",
                        children: [
                          ExpressiveListTile(
                            leading: SettingsColorIcon(
                              icon: FluentIcons.storage_24_filled,
                              color: const Color.fromARGB(155, 130, 146, 66),
                            ),
                            title: Text('Backup and storage'),
                            subtitle: Text('App folder, backup, and restore'),
                            onTap: () => context.go('/settings/backup_storage'),
                            trailing: const Icon(
                              FluentIcons.chevron_right_24_filled,
                            ),
                          ),
                          ExpressiveListTile(
                            leading: SettingsColorIcon(
                              icon: FluentIcons.shield_keyhole_24_filled,
                              color: const Color.fromARGB(155, 46, 115, 76),
                            ),
                            title: Text('Privacy'),
                            subtitle: Text('Playback & search history'),
                            onTap: () => context.go('/settings/privacy'),
                            trailing: const Icon(
                              FluentIcons.chevron_right_24_filled,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 24),

                      ExpressiveListGroup(
                        title: "Updates & About",
                        children: [
                          ExpressiveListTile(
                            leading: SettingsColorIcon(
                              icon: FluentIcons.info_24_filled,
                              color: const Color.fromARGB(155, 115, 84, 46),
                            ),
                            title: Text(S.of(context).About),
                            subtitle: Text('App info, support & links'),
                            onTap: () => context.go('/settings/about'),
                            trailing: const Icon(
                              FluentIcons.chevron_right_24_filled,
                            ),
                          ),
                          ExpressiveListTile(
                            leading: SettingsColorIcon(
                              icon: FluentIcons.arrow_circle_up_24_filled,
                              color: const Color.fromARGB(155, 115, 46, 62),
                            ),
                            title: Text(S.of(context).Check_For_Update),
                            subtitle: Text('Check GitHub for releases'),
                            onTap: () => UpdateService.manualCheck(context),
                            trailing: const Icon(
                              FluentIcons.chevron_right_24_filled,
                            ),
                          ),
                          ExpressiveListTile(
                            leading: SettingsColorIcon(
                              icon: FluentIcons.money_24_filled,
                              color: const Color.fromARGB(155, 46, 100, 115),
                            ),
                            title: Text(S.of(context).Donate),
                            subtitle: Text(S.of(context).Donate_Message),
                            onTap: () => showPaymentsModal(context),
                            trailing: const Icon(
                              FluentIcons.chevron_right_24_filled,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _BatteryWarningTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListTile(
      tileColor: Theme.of(context).colorScheme.errorContainer.withAlpha(200),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      leading: const ColorIcon(icon: Icons.battery_alert, color: Colors.red),
      title: Text(
        S.of(context).Battery_Optimisation_title,
        style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
      ),
      subtitle: Text(
        S.of(context).Battery_Optimisation_message,
        style: tinyTextStyle(context).copyWith(
          color: Theme.of(
            context,
          ).colorScheme.onErrorContainer.withValues(alpha: 0.7),
        ),
      ),
      onTap: () {
        context.read<SettingsSystemCubit>().requestBatteryOptimizationIgnore();
      },
    );
  }
}

void showPaymentsModal(BuildContext context) {
  Widget title = AdaptiveListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(S.of(context).Payment_Methods, style: mediumTextStyle(context)),
    leading: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          height: 40,
          width: 40,
          child: ColorIcon(color: Colors.accents[14], icon: Icons.money),
        ),
      ],
    ),
  );
  Widget child = Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      AdaptiveListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Image.asset('assets/images/upi.jpg', height: 30, width: 30),
        ),
        title: Text(
          S.of(context).Pay_With_UPI,
          style: subtitleTextStyle(context),
        ),
        onTap: () async {
          Navigator.pop(context);
          await Clipboard.setData(
            const ClipboardData(text: 'sheikhhaziq76@okaxis'),
          );
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Copied UPI ID to clipboard!")),
            );
          }
        },
      ),
      AdaptiveListTile(
        leading: Container(
          decoration: BoxDecoration(
            color: const Color.fromRGBO(19, 195, 255, 1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Image.asset('assets/images/kofi.png', height: 30, width: 30),
        ),
        title: Text(
          S.of(context).Support_Me_On_Kofi,
          style: subtitleTextStyle(context),
        ),
        onTap: () async {
          Navigator.pop(context);
          await launchUrl(
            Uri.parse('https://ko-fi.com/sheikhhaziq'),
            mode: LaunchMode.externalApplication,
          );
        },
      ),
      AdaptiveListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Image.asset('assets/images/coffee.png', height: 30, width: 30),
        ),
        title: Text(
          S.of(context).Buy_Me_A_Coffee,
          style: subtitleTextStyle(context),
        ),
        onTap: () async {
          Navigator.pop(context);
          await launchUrl(
            Uri.parse('https://buymeacoffee.com/sheikhhaziq'),
            mode: LaunchMode.externalApplication,
          );
        },
      ),
    ],
  );

  showModalBottomSheet(
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    context: context,
    builder: (context) => BottomModalLayout(title: title, child: child),
  );
}
