import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:gyawun/core/extensions/string_extensions.dart';
import 'package:gyawun/core/utils/expressive_sheet.dart';
import 'package:gyawun/core/widgets/expressive_app_bar.dart';
import 'package:gyawun/core/widgets/expressive_list_group.dart';
import 'package:gyawun/core/widgets/expressive_list_tile.dart';
import 'package:gyawun/core/widgets/expressive_switch_list_tile.dart';
import 'package:gyawun/generated/l10n.dart';
import 'package:gyawun/screens/settings/widgets/color_icon.dart';
import 'package:gyawun/services/settings_manager.dart';
import 'package:gyawun/utils/bottom_modals.dart';

import 'cubit/ytmusic_cubit.dart';

class YTMusicPage extends StatelessWidget {
  const YTMusicPage({super.key});

  Future<void> _setLocation(
    BuildContext context,
    Map<String, String> location,
  ) async {
    {
      final selected = await ExpressiveSheet.showSelection(
        context,
        title: "Choose Country",
        options: context
            .read<YTMusicCubit>()
            .locations
            .map(
              (l) => ExpressiveSheetOption(
                value: l,
                label: l['name']!.trim(),
                selected: l == location,
              ),
            )
            .toList(),
      );
      if (selected == null) return;
      if (context.mounted) {
        context.read<YTMusicCubit>().setLocation(selected);
      }
    }
  }

  Future<void> _setLanguage(
    BuildContext context,
    Map<String, String> language,
  ) async {
    {
      final selected = await ExpressiveSheet.showSelection(
        context,
        title: "Choose Language",
        options: context
            .read<YTMusicCubit>()
            .languages
            .map(
              (l) => ExpressiveSheetOption(
                value: l,
                label: l['name']!.trim(),
                selected: l == language,
              ),
            )
            .toList(),
      );
      if (selected == null) return;
      if (context.mounted) {
        context.read<YTMusicCubit>().setLanguage(selected);
      }
    }
  }

  Future<void> _setStreamingQuality(
    BuildContext context,
    AudioQuality quality,
  ) async {
    {
      final selected = await ExpressiveSheet.showSelection(
        context,
        title: "Choose Streaming Quality",
        options: context
            .read<YTMusicCubit>()
            .audioQualities
            .map(
              (l) => ExpressiveSheetOption(
                value: l,
                label: l.name.capitalize(),
                selected: l == quality,
              ),
            )
            .toList(),
      );
      if (selected == null) return;
      if (context.mounted) {
        context.read<YTMusicCubit>().setStreamingQuality(selected);
      }
    }
  }

  Future<void> _setDownloadingQuality(
    BuildContext context,
    AudioQuality quality,
  ) async {
    {
      final selected = await ExpressiveSheet.showSelection(
        context,
        title: "Choose Downloading Quality",
        options: context
            .read<YTMusicCubit>()
            .audioQualities
            .map(
              (l) => ExpressiveSheetOption(
                value: l,
                label: l.name.capitalize(),
                selected: l == quality,
              ),
            )
            .toList(),
      );
      if (selected == null) return;
      if (context.mounted) {
        context.read<YTMusicCubit>().setDownloadQuality(selected);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => YTMusicCubit(),
      child: Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              ExpressiveAppBar(title: S.of(context).YTMusic, hasLeading: true),
            ];
          },
          body: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: BlocBuilder<YTMusicCubit, YTMusicState>(
                builder: (context, state) {
                  final cubit = context.read<YTMusicCubit>();

                  return ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    children: [
                      ExpressiveListGroup(
                        title: "General",
                        children: [
                          ExpressiveListTile(
                            title: Text(S.of(context).Country),
                            leading: SettingsColorIcon(
                              icon: FluentIcons.location_24_filled,
                            ),
                            subtitle: state.location['name'] != null
                                ? Text(state.location['name']!)
                                : null,
                            onTap: () => _setLocation(context, state.location),
                          ),
                          ExpressiveListTile(
                            title: Text(S.of(context).Language),
                            leading: SettingsColorIcon(
                              icon: FluentIcons.local_language_24_filled,
                            ),
                            subtitle: state.language['name'] != null
                                ? Text(state.language['name']!)
                                : null,
                            onTap: () => _setLanguage(context, state.language),
                          ),
                          ExpressiveSwitchListTile(
                            title: Text(S.of(context).Translate_Lyrics),
                            leading: SettingsColorIcon(
                              icon: FluentIcons.translate_24_filled,
                            ),
                            value: state.translateLyrics,
                            onChanged: cubit.setTranslateLyrics,
                          ),
                          ExpressiveSwitchListTile(
                            title: Text(S.of(context).Autofetch_Songs),
                            leading: SettingsColorIcon(
                              icon: FluentIcons
                                  .arrow_rotate_counterclockwise_24_filled,
                            ),
                            value: state.autofetchSongs,
                            onChanged: cubit.setAutofetchSongs,
                          ),
                        ],
                      ),
                      SizedBox(height: 24),
                      ExpressiveListGroup(
                        title: 'Playback & download',
                        children: [
                          ExpressiveListTile(
                            title: Text(S.of(context).Streaming_Quality),
                            leading: SettingsColorIcon(
                              icon: Icons.spatial_audio_rounded,
                            ),
                            subtitle: Text(
                              state.streamingQuality.name.capitalize(),
                            ),
                            onTap: () => _setStreamingQuality(
                              context,
                              state.streamingQuality,
                            ),
                          ),
                          ExpressiveListTile(
                            title: Text(S.of(context).DOwnload_Quality),
                            leading: SettingsColorIcon(
                              icon: FluentIcons.cloud_arrow_down_24_filled,
                            ),
                            subtitle: Text(
                              state.downloadQuality.name.capitalize(),
                            ),
                            onTap: () => _setDownloadingQuality(
                              context,
                              state.downloadQuality,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 24),

                      ExpressiveListGroup(
                        title: 'Privacy',
                        children: [
                          ExpressiveSwitchListTile(
                            title: Text(S.of(context).Personalised_Content),
                            leading: const SettingsColorIcon(
                              icon: Icons.recommend_rounded,
                            ),
                            value: state.personalisedContent,
                            onChanged: (v) async {
                              Modals.showCenterLoadingModal(context);
                              await cubit.setPersonalisedContent(v);
                              if (context.mounted) context.pop();
                            },
                          ),
                          ExpressiveListTile(
                            title: Text(S.of(context).Enter_Visitor_Id),
                            leading: const SettingsColorIcon(
                              icon: FluentIcons.edit_24_filled,
                            ),
                            onTap: () async {
                              final text = await Modals.showTextField(
                                context,
                                title: S.of(context).Enter_Visitor_Id,
                                hintText: S.of(context).Visitor_Id,
                              );
                              if (text != null) {
                                cubit.setVisitorId(text);
                              }
                            },
                          ),

                          ExpressiveListTile(
                            title: Text(S.of(context).Reset_Visitor_Id),
                            leading: const SettingsColorIcon(
                              icon: FluentIcons.key_reset_24_filled,
                            ),
                            subtitle: Text(state.visitorId),
                            trailing: state.visitorId.isEmpty
                                ? null
                                : IconButton(
                                    icon: const Icon(Icons.copy),
                                    onPressed: () {
                                      Clipboard.setData(
                                        ClipboardData(text: state.visitorId),
                                      );
                                    },
                                  ),
                            onTap: () async {
                              Modals.showCenterLoadingModal(context);
                              await cubit.resetVisitorId();
                              if (context.mounted) context.pop();
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
