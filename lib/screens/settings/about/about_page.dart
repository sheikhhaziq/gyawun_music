import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app_config.dart';
import '../../../generated/l10n.dart';
import '../../../themes/colors.dart';
import '../../../utils/adaptive_widgets/adaptive_widgets.dart';
import '../widgets/color_icon.dart';
import '../widgets/setting_item.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  void _open(String url) {
    launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      appBar: AdaptiveAppBar(
        title: Text(S.of(context).About),
        centerTitle: true,
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              /// APP ICON
              Center(
                child: Image.asset(
                  'assets/images/icon.png',
                  height: 100,
                  width: 100,
                  errorBuilder: (_, __, ___) => Container(
                    height: 100,
                    width: 100,
                    decoration: BoxDecoration(
                      color: darkGreyColor.withAlpha(50),
                      borderRadius: BorderRadius.circular(50),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              /// APP INFO
              SettingTile(
                leading: const Icon(Icons.title),
                title: 'Gyawun Music',
                isFirst: true,
              ),
              SettingTile(
                leading: const Icon(Icons.new_releases),
                title: S.of(context).Version,
                subtitle: appConfig.codeName,
              ),

              /// DEVELOPER
              SettingTile(
                leading: const Icon(CupertinoIcons.person),
                title: S.of(context).Developer,
                subtitle: S.of(context).Sheikh_Haziq,
                trailing: Icon(AdaptiveIcons.chevron_right),
                onTap: () => _open('https://github.com/sheikhhaziq'),
              ),

              /// ORGANIZATION
              SettingTile(
                leading: const ColorIcon(color: null, icon: Icons.other_houses),
                title: S.of(context).Organisation,
                subtitle: S.of(context).Jhelum_Corp,
                trailing: Icon(AdaptiveIcons.chevron_right),
                onTap: () => _open('https://jhelumcorp.github.io'),
              ),

              /// LINKS
              SettingTile(
                leading: const ColorIcon(color: null, icon: Icons.link),
                title: 'Website',
                trailing: Icon(AdaptiveIcons.chevron_right),
                onTap: () => _open('https://gyawunmusic.vercel.app'),
              ),
              SettingTile(
                leading:
                    const ColorIcon(color: null, icon: Icons.telegram_outlined),
                title: S.of(context).Telegram,
                trailing: Icon(AdaptiveIcons.chevron_right),
                onTap: () => _open('https://t.me/jhelumcorp'),
              ),
              SettingTile(
                leading:
                    const ColorIcon(color: null, icon: CupertinoIcons.person_3),
                title: S.of(context).Contributors,
                trailing: Icon(AdaptiveIcons.chevron_right),
                onTap: () => _open(
                  'https://github.com/jhelumcorp/gyawun/contributors',
                ),
              ),
              SettingTile(
                leading: const ColorIcon(color: null, icon: Icons.code),
                title: S.of(context).Source_Code,
                trailing: Icon(AdaptiveIcons.chevron_right),
                onTap: () => _open('https://github.com/jhelumcorp/gyawun'),
              ),
              SettingTile(
                leading: const ColorIcon(color: null, icon: Icons.bug_report),
                title: S.of(context).Bug_Report,
                trailing: Icon(AdaptiveIcons.chevron_right),
                onTap: () => _open(
                  'https://github.com/jhelumcorp/gyawun/issues/new'
                  '?labels=bug&template=bug_report.yaml',
                ),
              ),
              SettingTile(
                leading: const ColorIcon(color: null, icon: Icons.request_page),
                title: S.of(context).Feature_Request,
                isLast: true,
                trailing: Icon(AdaptiveIcons.chevron_right),
                onTap: () => _open(
                  'https://github.com/jhelumcorp/gyawun/issues/new'
                  '?labels=enhancement&template=feature_request.yaml',
                ),
              ),

              const SizedBox(height: 16),

              /// FOOTER
              Center(
                child: Text(
                  S.of(context).Made_In_Kashmir,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
