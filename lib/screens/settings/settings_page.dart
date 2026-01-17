import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../generated/l10n.dart';
import '../../themes/text_styles.dart';
import '../../utils/adaptive_widgets/adaptive_widgets.dart';
import '../../utils/bottom_modals.dart';
import '../../utils/check_update.dart';
import 'widgets/color_icon.dart';
import 'widgets/setting_item.dart';
import 'cubit/settings_system_cubit.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SettingsSystemCubit()..load(),
      child: AdaptiveScaffold(
        appBar: AdaptiveAppBar(
          title: Text(
            S.of(context).Settings,
            style: mediumTextStyle(context, bold: false),
          ),
          automaticallyImplyLeading: false,
        ),
        body: BlocBuilder<SettingsSystemCubit, SettingsSystemState>(
          builder: (context, state) {
            final bool? batteryDisabled = state is SettingsSystemLoaded
                ? state.isBatteryOptimizationDisabled
                : null;

            return Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  children: [
                    if (Platform.isAndroid && batteryDisabled != true)
                      _BatteryWarningTile(),
                    GroupTitle(title: "General"),
                    SettingTile(
                      title: S.of(context).Appearence,
                      leading: const Icon(Icons.looks_rounded),
                      isFirst: true,
                      onTap: () => context.go('/settings/appearance'),
                    ),
                    SettingTile(
                      title: "Player",
                      leading: const Icon(Icons.play_arrow_rounded),
                      isLast: true,
                      onTap: () => context.go('/settings/player'),
                    ),
                    GroupTitle(title: "Services"),
                    SettingTile(
                      title: "Youtube Music",
                      leading: const Icon(Icons.play_circle_fill),
                      isFirst: true,
                      isLast: true,
                      onTap: () => context.go('/settings/services/ytmusic'),
                    ),
                    GroupTitle(title: "Storage & Privacy"),
                    SettingTile(
                      title: "Backup and storage",
                      leading: const Icon(
                        Icons.cloud_upload_rounded,
                      ),
                      isFirst: true,
                      onTap: () => context.go(
                        '/settings/backup_storage',
                      ),
                    ),
                    SettingTile(
                      title: "Privacy",
                      leading: const Icon(Icons.privacy_tip),
                      isLast: true,
                      onTap: () => context.go('/settings/privacy'),
                    ),
                    GroupTitle(title: "Updates & About"),
                    SettingTile(
                      title: S.of(context).About,
                      leading: const Icon(Icons.info_rounded),
                      isFirst: true,
                      onTap: () => context.go('/settings/about'),
                    ),
                    SettingTile(
                      title: S.of(context).Check_For_Update,
                      leading: const Icon(Icons.update_rounded),
                      onTap: () async {
                        Modals.showCenterLoadingModal(
                          context,
                        );
                        final info = await checkUpdate();
                        if (context.mounted) {
                          Navigator.pop(context);
                          Modals.showUpdateDialog(
                            context,
                            info,
                          );
                        }
                      },
                    ),
                    SettingTile(
                      leading: const Icon(Icons.money),
                      title: S.of(context).Donate,
                      isLast: true,
                      subtitle: S.of(context).Donate_Message,
                      onTap: () => showPaymentsModal(context),
                    ),
                  ],
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(25),
      ),
      leading: const ColorIcon(
        icon: Icons.battery_alert,
        color: Colors.red,
      ),
      title: Text(
        S.of(context).Battery_Optimisation_title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onErrorContainer,
        ),
      ),
      subtitle: Text(
        S.of(context).Battery_Optimisation_message,
        style: tinyTextStyle(context).copyWith(
          color: Theme.of(context)
              .colorScheme
              .onErrorContainer
              .withValues(alpha: 0.7),
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
    title: Text(
      S.of(context).Payment_Methods,
      style: mediumTextStyle(context),
    ),
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
            child: Image.asset('assets/images/upi.jpg', height: 30, width: 30)),
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
              SnackBar(
                content: Text(
                  "Copied UPI ID to clipboard!",
                ),
              ),
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
            child:
                Image.asset('assets/images/kofi.png', height: 30, width: 30)),
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
            child:
                Image.asset('assets/images/coffee.png', height: 30, width: 30)),
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
