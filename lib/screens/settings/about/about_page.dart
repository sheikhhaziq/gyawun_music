import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:gyawun/core/widgets/expressive_app_bar.dart';
import 'package:gyawun/core/widgets/expressive_list_group.dart';
import 'package:gyawun/core/widgets/expressive_list_tile.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../generated/l10n.dart';
import '../widgets/color_icon.dart';

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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            ExpressiveAppBar(title: S.of(context).About, hasLeading: true),
          ];
        },
        body: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                Center(
                  child: Column(
                    children: [
                      Container(
                        height: 100,
                        width: 100,
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.shadow.withValues(alpha: 0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Image.asset(
                          'assets/images/icon.png',
                          height: 100,
                          width: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Icon(
                            Icons.music_note_rounded,
                            size: 48,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Gyawun Music',
                        style: textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_version != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: colorScheme.tertiaryContainer,
                          ),
                          child: Text(
                            'Version $_version',
                            style: textTheme.labelLarge?.copyWith(
                              color: colorScheme.onTertiaryContainer,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                ExpressiveListGroup(
                  title: "About",
                  children: [
                    ExpressiveListTile(
                      leading: const SettingsColorIcon(icon: Icons.person),
                      title: const Text("Developer"),
                      subtitle: const Text("Sheikh Haziq"),
                      trailing: const Icon(FluentIcons.chevron_right_24_filled),
                      onTap: () => _open('https://github.com/sheikhhaziq'),
                    ),
                    ExpressiveListTile(
                      leading: const SettingsColorIcon(icon: Icons.link),
                      title: const Text("Website"),
                      trailing: const Icon(FluentIcons.chevron_right_24_filled),
                      onTap: () => _open('https://gyawunmusic.vercel.app'),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                ExpressiveListGroup(
                  title: "Community",
                  children: [
                    ExpressiveListTile(
                      leading: const SettingsColorIcon(icon: Icons.people),
                      title: const Text("Contributors"),
                      trailing: const Icon(FluentIcons.chevron_right_24_filled),
                      onTap: () => _open(
                        'https://github.com/jhelumcorp/gyawun/contributors',
                      ),
                    ),
                    ExpressiveListTile(
                      leading: const SettingsColorIcon(icon: Icons.send),
                      title: const Text("Telegram"),
                      trailing: const Icon(FluentIcons.chevron_right_24_filled),
                      onTap: () => _open('https://t.me/jhelumcorp'),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                ExpressiveListGroup(
                  title: "Development",
                  children: [
                    ExpressiveListTile(
                      leading: const SettingsColorIcon(icon: Icons.code),
                      title: const Text("Source Code"),
                      trailing: const Icon(FluentIcons.chevron_right_24_filled),
                      onTap: () =>
                          _open('https://github.com/jhelumcorp/gyawun'),
                    ),
                    ExpressiveListTile(
                      leading: const SettingsColorIcon(icon: Icons.bug_report),
                      title: const Text("Bug Report"),
                      trailing: const Icon(FluentIcons.chevron_right_24_filled),
                      onTap: () => _open(
                        'https://github.com/sheikhhaziq/gyawun_music/issues/new?template=bug_report.yml',
                      ),
                    ),
                    ExpressiveListTile(
                      leading: const SettingsColorIcon(icon: Icons.description),
                      title: const Text("Feature Request"),
                      trailing: const Icon(FluentIcons.chevron_right_24_filled),
                      onTap: () => _open(
                        'https://github.com/sheikhhaziq/gyawun_music/discussions',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
