import 'dart:ui';

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gyawun/themes/text_styles.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../generated/l10n.dart';
import '../../../themes/colors.dart';
import '../widgets/color_icon.dart';
import '../widgets/setting_item.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  String? _version;

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;

    setState(() {
      // Example: 2.0.16-beta.3 or 2.0.16
      _version = info.version;
    });
  }

  void _open(String url) {
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              pinned: true,
              expandedHeight: 120,
              flexibleSpace: LayoutBuilder(
                builder: (context, constraints) {
                  final maxHeight = 120.0;
                  final t = (constraints.maxHeight / (maxHeight + 30)).clamp(
                    0.0,
                    1.0,
                  );
                  final paddingLeft = lerpDouble(100, 16, t)!;

                  return FlexibleSpaceBar(
                    titlePadding: EdgeInsets.only(
                      left: paddingLeft,
                      bottom: 12,
                    ),
                    title: Text(
                      S.of(context).About,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textStyle(context).copyWith(fontSize: 24),
                    ),
                  );
                },
              ),
            ),
          ];
        },
        body: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                /// APP ICON
                Center(
                  child: Column(
                    children: [
                      Image.asset(
                        'assets/images/icon.png',
                        height: 100,
                        width: 100,
                        errorBuilder: (_, _, _) => Container(
                          height: 100,
                          width: 100,
                          decoration: BoxDecoration(
                            color: darkGreyColor.withAlpha(50),
                            borderRadius: BorderRadius.circular(50),
                          ),
                        ),
                      ),
                      Text(
                        'Gyawun Music',
                        style: textStyle(
                          context,
                        ).copyWith(fontSize: 20, fontWeight: .w700),
                      ),
                      SizedBox(height: 8),
                      if (_version != null)
                        Container(
                          padding: .symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            borderRadius: .circular(24),
                            color: Theme.of(
                              context,
                            ).colorScheme.tertiaryContainer,
                          ),
                          child: Text(
                            'Version $_version',
                            style: textStyle(context).copyWith(
                              color: Theme.of(
                                context,
                              ).colorScheme.onTertiaryContainer,
                              fontWeight: .w600,
                              fontSize: 18,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                /// DEVELOPER
                SettingTile(
                  isFirst: true,
                  leading: const Icon(CupertinoIcons.person),
                  title: S.of(context).Developer,
                  subtitle: S.of(context).Sheikh_Haziq,
                  trailing: Icon(FluentIcons.chevron_right_24_filled),
                  onTap: () => _open('https://github.com/sheikhhaziq'),
                ),

                /// LINKS
                SettingTile(
                  leading: const ColorIcon(color: null, icon: Icons.link),
                  title: 'Website',
                  trailing: Icon(FluentIcons.chevron_right_24_filled),
                  onTap: () => _open('https://gyawunmusic.vercel.app'),
                ),
                SettingTile(
                  leading: const ColorIcon(
                    color: null,
                    icon: Icons.telegram_outlined,
                  ),
                  title: S.of(context).Telegram,
                  trailing: Icon(FluentIcons.chevron_right_24_filled),
                  onTap: () => _open('https://t.me/jhelumcorp'),
                ),
                SettingTile(
                  leading: const ColorIcon(
                    color: null,
                    icon: CupertinoIcons.person_3,
                  ),
                  title: S.of(context).Contributors,
                  trailing: Icon(FluentIcons.chevron_right_24_filled),
                  onTap: () => _open(
                    'https://github.com/jhelumcorp/gyawun/contributors',
                  ),
                ),
                SettingTile(
                  leading: const ColorIcon(color: null, icon: Icons.code),
                  title: S.of(context).Source_Code,
                  trailing: Icon(FluentIcons.chevron_right_24_filled),
                  onTap: () => _open('https://github.com/jhelumcorp/gyawun'),
                ),
                SettingTile(
                  leading: const ColorIcon(color: null, icon: Icons.bug_report),
                  title: S.of(context).Bug_Report,
                  trailing: Icon(FluentIcons.chevron_right_24_filled),
                  onTap: () => _open(
                    'https://github.com/sheikhhaziq/gyawun_music/issues/new?template=bug_report.yml',
                  ),
                ),
                SettingTile(
                  leading: const ColorIcon(
                    color: null,
                    icon: Icons.request_page,
                  ),
                  title: S.of(context).Feature_Request,
                  isLast: true,
                  trailing: Icon(FluentIcons.chevron_right_24_filled),
                  onTap: () => _open(
                    'https://github.com/sheikhhaziq/gyawun_music/discussions',
                  ),
                ),

                const SizedBox(height: 16),

                /// FOOTER
                Center(
                  child: Text(
                    S.of(context).Made_In_Kashmir,
                    style: textStyle(context).copyWith(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
