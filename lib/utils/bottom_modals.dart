import 'dart:io';
import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:duration_picker/duration_picker.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:gyawun/screens/settings/player/equalizer/equalizer_page.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import 'playlist_icon.dart';
import 'playlist_icons.dart';
import 'playlist_icon_widget.dart';
import '../generated/l10n.dart';
import '../screens/settings/widgets/color_icon.dart';
import '../services/bottom_message.dart';
import '../services/download_manager.dart';
import '../services/favourites_manager.dart';
import '../services/library.dart';
import '../services/media_player.dart';
import '../services/settings_manager.dart';
import '../utils/text_controller_builder.dart';
import '../utils/playlist_thumbnail.dart';
import '../themes/colors.dart';
import '../themes/text_styles.dart';
import 'adaptive_widgets/adaptive_widgets.dart';
import 'format_duration.dart';
import '../utils/extensions.dart';

class Modals {
  static Future showCenterLoadingModal(BuildContext context, {String? title}) {
    return showDialog(
      context: context,
      useRootNavigator: false,
      builder: (context) {
        return AlertDialog(
          title: Text(title ?? S.of(context).Progress),
          content: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [CircularProgressIndicator()],
          ),
        );
      },
    );
  }

  // static Future showUpdateDialog(
  //         BuildContext context, UpdateInfo? updateInfo) =>
  //     showDialog(
  //       context: context,
  //       useRootNavigator: false,
  //       builder: (context) {
  //         return _updateDialog(context, updateInfo);
  //       },
  //     );
  static Future<String?> showTextField(
    BuildContext context, {
    String? title,
    String? hintText,
    String? doneText,
  }) {
    return showModalBottomSheet<String?>(
      context: context,
      useRootNavigator: false,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _textFieldBottomModal(
        context,
        title: title,
        hintText: hintText,
        doneText: doneText,
      ),
    );
  }

  static Future<T?> showSelection<T>(
    BuildContext context,
    List<SelectionItem> items,
  ) {
    return showModalBottomSheet<T>(
      context: context,
      useRootNavigator: false,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _showSelection(context, items),
    );
  }

  static void showSongBottomModal(BuildContext context, Map song) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: false,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _songBottomModal(context, song),
    );
  }

  static void showPlayerOptionsModal(BuildContext context, Map song) {
    showModalBottomSheet(
      useRootNavigator: false,
      backgroundColor: Colors.transparent,
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (context) => _playerOptionsModal(context, song),
    );
  }

  static void showPlaylistBottomModal(BuildContext context, Map playlist) {
    showModalBottomSheet(
      useRootNavigator: false,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      isScrollControlled: true,
      context: context,
      builder: (context) => _playlistBottomModal(context, playlist),
    );
  }

  static void showFavouritesBottomModal(BuildContext context, Map playlist) {
    showModalBottomSheet(
      useRootNavigator: false,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      isScrollControlled: true,
      context: context,
      builder: (context) => _favouritesBottomModal(context, playlist),
    );
  }

  static void showDownloadBottomModal(BuildContext context) {
    showModalBottomSheet(
      useRootNavigator: false,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      isScrollControlled: true,
      context: context,
      builder: (context) => _downloadBottomModal(context),
    );
  }

  static void showDownloadDetailsBottomModal(
    BuildContext context,
    Map playlist,
  ) {
    showModalBottomSheet(
      useRootNavigator: false,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      isScrollControlled: true,
      context: context,
      builder: (context) => _downloadDetailsBottomModal(context, playlist),
    );
  }

  static Future showArtistsBottomModal(
    BuildContext context,
    List artists, {
    String? leading,
    bool shouldPop = false,
  }) {
    return showModalBottomSheet(
      useRootNavigator: false,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      isScrollControlled: true,
      context: context,
      builder: (context) =>
          _artistsBottomModal(context, artists, shouldPop: shouldPop),
    );
  }

  static void showCreateplaylistModal(BuildContext context, {Map? item}) {
    PlaylistIcon selectedIcon = PlaylistIcons.musicNoteList;
    showModalBottomSheet(
      useRootNavigator: false,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      isScrollControlled: true,
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return _createPlaylistModal(
              context,
              item,
              selectedIcon,
              (icon) => setState(() => selectedIcon = icon),
            );
          },
        );
      },
    );
  }

  static Future<PlaylistIcon?> showSelectPlaylistIconModal(
    BuildContext context, {
    Map? item,
  }) async {
    return await showModalBottomSheet(
      useRootNavigator: false,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      isScrollControlled: true,
      context: context,
      builder: (context) => _selectPlaylistIconModal(context),
    );
  }

  static void showImportplaylistModal(BuildContext context, {Map? item}) {
    showModalBottomSheet(
      useRootNavigator: false,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      isScrollControlled: true,
      context: context,
      builder: (context) => _importPlaylistModal(context),
    );
  }

  static void showEditPlaylistBottomModal(
    BuildContext context, {
    required String playlistId,
    required String iconId,
    String? name,
  }) {
    PlaylistIcon selectedIcon = PlaylistIcons.byId(iconId);
    showModalBottomSheet(
      useRootNavigator: false,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      isScrollControlled: true,
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return _editPlaylistBottomModal(
              context,
              playlistId: playlistId,
              name: name,
              selectedIcon: selectedIcon,
              onIconChanged: (icon) => setState(() => selectedIcon = icon),
            );
          },
        );
      },
    );
  }

  static void addToPlaylist(BuildContext context, Map item) {
    showModalBottomSheet(
      useRootNavigator: false,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      isScrollControlled: true,
      context: context,
      builder: (context) => _addToPlaylist(context, item),
    );
  }

  static Future<bool> showConfirmBottomModal(
    BuildContext context, {
    required String message,
    bool isDanger = false,
    String? doneText,
    String? cancelText,
  }) async {
    return await showModalBottomSheet(
          useRootNavigator: false,
          backgroundColor: Colors.transparent,
          useSafeArea: true,
          isScrollControlled: true,
          context: context,
          builder: (context) => _confirmBottomModal(
            context,
            message: message,
            isDanger: isDanger,
            doneText: doneText,
            cancelText: cancelText,
          ),
        ) ??
        false;
  }

  static void showAccentSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: false,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _accentSelector(context),
    );
  }
}

BottomModalLayout _confirmBottomModal(
  BuildContext context, {
  required String message,
  bool isDanger = false,
  String? doneText,
  String? cancelText,
}) {
  return BottomModalLayout(
    title: Center(
      child: Text(S.of(context).Confirm, style: bigTextStyle(context)),
    ),
    actions: [
      AdaptiveButton(
        color: Platform.isAndroid
            ? Theme.of(context).colorScheme.primary.withAlpha(30)
            : null,
        onPressed: () {
          Navigator.pop(context, false);
        },
        child: Text(cancelText ?? S.of(context).No),
      ),
      const SizedBox(width: 16),
      AdaptiveFilledButton(
        onPressed: () {
          Navigator.pop(context, true);
        },
        color: isDanger ? Colors.red : Theme.of(context).colorScheme.primary,
        child: Text(
          doneText ?? S.of(context).Yes,
          style: TextStyle(color: isDanger ? Colors.white : null),
        ),
      ),
    ],
    child: SingleChildScrollView(
      child: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [Text(message, textAlign: TextAlign.center)],
        ),
      ),
    ),
  );
}

Widget _editPlaylistBottomModal(
  BuildContext context, {
  String? name,
  required String playlistId,
  required PlaylistIcon selectedIcon,
  required Function(PlaylistIcon) onIconChanged,
}) {
  return TextControllerBuilder(
    initialText: name,
    builder: (context, controller) {
      final bool blockInput = context.isKeyboardSpaceLimited;
      return BottomModalLayout(
        title: Center(
          child: Text(
            S.of(context).Edit_Playlist,
            style: mediumTextStyle(context),
          ),
        ),
        actions: [
          AdaptiveFilledButton(
            onPressed: () async {
              String text = controller.text;
              context
                  .read<LibraryService>()
                  .editPlaylist(
                    playlistId: playlistId,
                    iconId: selectedIcon.toId(),
                    title: text.trim().isNotEmpty ? text : null,
                  )
                  .then((String message) {
                    if (context.mounted) {
                      Navigator.pop(context);
                      BottomMessage.showText(context, message);
                    }
                  });
            },
            child: Text(S.of(context).Edit),
          ),
        ],
        child: Row(
          spacing: 10,
          children: [
            GestureDetector(
              onTap: () async {
                final icon = await Modals.showSelectPlaylistIconModal(context);
                if (icon != null) {
                  onIconChanged(icon);
                }
              },
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: Theme.of(context).colorScheme.primaryContainer,
                    ),
                    child: PlaylistIconWidget(data: selectedIcon, size: 36),
                  ),
                  Positioned(
                    right: -4,
                    bottom: -4,
                    child: CircleAvatar(
                      radius: 10,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: Icon(
                        Icons.edit,
                        size: 15,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: AdaptiveTextField(
                controller: controller,
                fillColor: Platform.isAndroid ? greyColor : null,
                hintText: S.of(context).Playlist_Name,
                readOnly: blockInput,
                onTap: () {
                  if (blockInput) {
                    FocusScope.of(context).unfocus();
                    BottomMessage.showText(
                      context,
                      S.of(context).Rotate_Device,
                    );
                  }
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}

BottomModalLayout _artistsBottomModal(
  BuildContext context,
  List<dynamic> artists, {
  bool shouldPop = false,
}) {
  return BottomModalLayout(
    title: Center(
      child: Text(S.of(context).Artists, style: mediumTextStyle(context)),
    ),
    child: SingleChildScrollView(
      child: Column(
        children: [
          ...artists.map(
            (artist) => AdaptiveListTile(
              dense: true,
              title: Text(
                artist['name'],
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              leading: Icon(AdaptiveIcons.person),
              trailing: Icon(AdaptiveIcons.chevron_right),
              onTap: () {
                if (shouldPop) {
                  context.go(
                    '/browse',
                    extra: {
                      'endpoint': artist['endpoint'].cast<String, dynamic>(),
                    },
                  );
                } else {
                  Navigator.pop(context);
                  context.push(
                    '/browse',
                    extra: {
                      'endpoint': artist['endpoint'].cast<String, dynamic>(),
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _createPlaylistModal(
  BuildContext context,
  Map<dynamic, dynamic>? item,
  PlaylistIcon selectedIcon,
  Function(PlaylistIcon) onIconChanged,
) {
  return TextControllerBuilder(
    builder: (context, controller) {
      final bool blockInput = context.isKeyboardSpaceLimited;
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: BottomModalLayout(
          title: Text(
            S.of(context).Create_Playlist,
            style: mediumTextStyle(context),
          ),
          actions: [
            AdaptiveButton(
              onPressed: () => Navigator.pop(context),
              child: Text(S.of(context).Cancel),
            ),
            AdaptiveFilledButton(
              color: Theme.of(context).colorScheme.primary,
              onPressed: () async {
                final message = await context
                    .read<LibraryService>()
                    .createPlaylist(
                      controller.text,
                      selectedIcon.toId(),
                      item: item,
                    );
                if (!context.mounted) return;
                Navigator.pop(context);
                BottomMessage.showText(context, message);
              },
              child: Text(
                S.of(context).Create,
                style: TextStyle(
                  color: context.isDarkMode ? Colors.black : Colors.white,
                ),
              ),
            ),
          ],
          child: Row(
            spacing: 10,
            children: [
              GestureDetector(
                onTap: () async {
                  final icon = await Modals.showSelectPlaylistIconModal(
                    context,
                  );
                  if (icon != null) {
                    onIconChanged(icon);
                  }
                },
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        color: Theme.of(context).colorScheme.primaryContainer,
                      ),
                      child: PlaylistIconWidget(data: selectedIcon, size: 36),
                    ),
                    Positioned(
                      right: -4,
                      bottom: -4,
                      child: CircleAvatar(
                        radius: 10,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: Icon(
                          Icons.edit,
                          size: 15,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: AdaptiveTextField(
                  controller: controller,
                  fillColor: Platform.isAndroid ? greyColor : null,
                  hintText: S.of(context).Playlist_Name,
                  readOnly: blockInput,
                  onTap: () {
                    if (blockInput) {
                      FocusScope.of(context).unfocus();
                      BottomMessage.showText(
                        context,
                        S.of(context).Rotate_Device,
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Widget _selectPlaylistIconModal(BuildContext context) {
  return BottomModalLayout(
    title: Text(
      S.of(context).Select_Playlist_Icon,
      style: mediumTextStyle(context),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        shrinkWrap: true,
        itemCount: PlaylistIcons.values.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
        ),
        itemBuilder: (context, index) {
          final icon = PlaylistIcons.values[index];
          return GestureDetector(
            onTap: () => Navigator.pop(context, icon),
            child: Center(child: PlaylistIconWidget(data: icon, size: 36)),
          );
        },
      ),
    ),
  );
}

Widget _importPlaylistModal(BuildContext context) {
  final bool blockInput = context.isKeyboardSpaceLimited;
  return TextControllerBuilder(
    builder: (context, controller) {
      return BottomModalLayout(
        title: Center(
          child: Text(
            S.of(context).Import_Playlist,
            style: mediumTextStyle(context),
          ),
        ),
        actions: [
          AdaptiveButton(
            onPressed: () async {
              Navigator.pop(context);
            },
            child: Text(S.of(context).Cancel),
          ),
          AdaptiveFilledButton(
            color: Theme.of(context).colorScheme.primary,
            onPressed: () async {
              Modals.showCenterLoadingModal(context);
              String message = await GetIt.I<LibraryService>().importPlaylist(
                controller.text,
              );
              if (context.mounted) {
                Navigator.pop(context);
                Navigator.pop(context);
                BottomMessage.showText(context, message);
              }
            },
            child: Text(
              S.of(context).Import,
              style: TextStyle(
                color: context.isDarkMode ? Colors.black : Colors.white,
              ),
            ),
          ),
        ],
        child: SingleChildScrollView(
          child: Column(
            children: [
              Column(
                children: [
                  AdaptiveTextField(
                    controller: controller,
                    keyboardType: TextInputType.url,
                    hintText: 'https://music.youtube.com/playlist?list=',
                    prefix: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: Icon(Icons.title),
                    ),
                    fillColor: Platform.isWindows ? null : greyColor,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 2,
                      horizontal: 16,
                    ),
                    readOnly: blockInput,
                    onTap: () {
                      if (blockInput) {
                        FocusScope.of(context).unfocus();
                        BottomMessage.showText(
                          context,
                          S.of(context).Rotate_Device,
                        );
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

BottomModalLayout _addToPlaylist(BuildContext context, Map item) {
  return BottomModalLayout(
    title: AdaptiveListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        S.of(context).Add_To_Playlist,
        style: mediumTextStyle(context),
      ),
      trailing: AdaptiveIconButton(
        onPressed: () {
          Navigator.pop(context);
          Modals.showCreateplaylistModal(context, item: item);
        },
        icon: const Icon(Icons.playlist_add, size: 20),
      ),
    ),
    child: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...context.read<LibraryService>().userPlaylists.map((key, playlist) {
            return MapEntry(
              key,
              playlist['songs']
                      .map((song) => song["videoId"])
                      .contains(item["videoId"])
                  ? const SizedBox.shrink()
                  : AdaptiveListTile(
                      dense: true,
                      title: Text(playlist['title']),
                      leading: playlist['isPredefined'] == true
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(
                                playlist['type'] == 'ARTIST' ? 50 : 3,
                              ),
                              child: CachedNetworkImage(
                                imageUrl: playlist['thumbnails'].first['url']
                                    .replaceAll('w540-h225', 'w60-h60'),
                                height: 50,
                                width: 50,
                              ),
                            )
                          : Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: PlaylistIconWidget(
                                data: PlaylistIcons.byId(playlist['iconId']),
                                size: 30,
                              ),
                            ),
                      onTap: () async {
                        await context
                            .read<LibraryService>()
                            .addToPlaylist(item: item, key: key)
                            .then((String message) {
                              if (context.mounted) {
                                Navigator.pop(context);
                                BottomMessage.showText(context, message);
                              }
                            });
                      },
                    ),
            );
          }).values,
        ],
      ),
    ),
  );
}

// SizedBox _updateDialog(BuildContext context, UpdateInfo? updateInfo) {
//   final f = DateFormat('MMMM dd, yyyy');

//   return SizedBox(
//     height: MediaQuery.of(context).size.height,
//     width: MediaQuery.of(context).size.width,
//     child: LayoutBuilder(builder: (context, constraints) {
//       return AlertDialog(
//         icon: Center(
//           child: Container(
//             padding: const EdgeInsets.all(16),
//             decoration: BoxDecoration(
//                 color: Colors.green.withAlpha(100),
//                 borderRadius: BorderRadius.circular(16)),
//             child: const Icon(
//               Icons.update_outlined,
//               size: 70,
//             ),
//           ),
//         ),
//         scrollable: true,
//         title: Column(
//           children: [
//             Text(updateInfo != null ? 'Update Available' : 'Update Info'),
//             if (updateInfo != null)
//               Text(
//                 '${updateInfo.name}\n${f.format(DateTime.parse(updateInfo.publishedAt))}',
//                 style: TextStyle(fontSize: 16, color: context.subtitleColor),
//               )
//           ],
//         ),
//         content: updateInfo != null
//             ? SizedBox(
//                 width: constraints.maxWidth,
//                 height: constraints.maxHeight - 400,
//                 child: Markdown(
//                   data: updateInfo.body,
//                   shrinkWrap: true,
//                   softLineBreak: true,
//                   onTapLink: (text, href, title) {
//                     if (href != null) {
//                       launchUrl(Uri.parse(href),
//                           mode: LaunchMode.platformDefault);
//                     }
//                   },
//                 ),
//               )
//             : const Center(
//                 child: Text("You are already up to date."),
//               ),
//         actions: [
//           if (updateInfo != null)
//             AdaptiveButton(
//               onPressed: () {
//                 Navigator.pop(context);
//               },
//               child: const Text('Cancel'),
//             ),
//           AdaptiveFilledButton(
//             onPressed: () {
//               Navigator.pop(context);
//               if (updateInfo != null) {
//                 launchUrl(Uri.parse(updateInfo.downloadUrl),
//                     mode: LaunchMode.externalApplication);
//               }
//             },
//             child: Text(updateInfo != null ? 'Update' : 'Done'),
//           ),
//         ],
//       );
//     }),
//   );
// }

Widget _textFieldBottomModal(
  BuildContext context, {
  String? title,
  String? hintText,
  String? doneText,
}) {
  final bool blockInput = context.isKeyboardSpaceLimited;
  return TextControllerBuilder(
    builder: (context, controller) {
      return BottomModalLayout(
        title: (title != null)
            ? Center(child: Text(title, style: mediumTextStyle(context)))
            : null,
        actions: [
          AdaptiveFilledButton(
            onPressed: () async {
              Navigator.pop(context, controller.text);
            },
            child: Text(doneText ?? S.of(context).Done),
          ),
        ],
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                child: Column(
                  children: [
                    AdaptiveTextField(
                      controller: controller,
                      fillColor: greyColor,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 2,
                        horizontal: 16,
                      ),
                      hintText: hintText,
                      prefix: const Icon(Icons.title),
                      readOnly: blockInput,
                      onTap: () {
                        if (blockInput) {
                          FocusScope.of(context).unfocus();
                          BottomMessage.showText(
                            context,
                            S.of(context).Rotate_Device,
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

BottomModalLayout _playerOptionsModal(BuildContext context, Map song) {
  return BottomModalLayout(
    child: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            children: [
              StreamBuilder(
                stream: GetIt.I<MediaPlayer>().player.volumeStream,
                builder: (context, progress) {
                  return AdaptiveListTile(
                    dense: true,
                    leading: Icon(
                      AdaptiveIcons.volume(
                        (progress.hasData && progress.data != null)
                            ? progress.data!
                            : GetIt.I<MediaPlayer>().player.volume,
                      ),
                    ),
                    title: AdaptiveSlider(
                      label:
                          (((progress.hasData && progress.data != null)
                                      ? progress.data!
                                      : GetIt.I<MediaPlayer>().player.volume) *
                                  100)
                              .toStringAsFixed(1),
                      value: (progress.hasData && progress.data != null)
                          ? progress.data!
                          : GetIt.I<MediaPlayer>().player.volume,
                      onChanged: (volume) {
                        GetIt.I<MediaPlayer>().player.setVolume(volume);
                      },
                    ),
                  );
                },
              ),
              StreamBuilder(
                stream: GetIt.I<MediaPlayer>().player.speedStream,
                builder: (context, progress) {
                  return AdaptiveListTile(
                    dense: true,
                    leading: const Icon(Icons.speed),
                    title: AdaptiveSlider(
                      max: 2,
                      min: 0.25,
                      divisions: 7,
                      label:
                          ((progress.hasData && progress.data != null)
                                  ? progress.data!
                                  : GetIt.I<MediaPlayer>().player.speed)
                              .toString(),
                      value: (progress.hasData && progress.data != null)
                          ? progress.data!
                          : GetIt.I<MediaPlayer>().player.speed,
                      onChanged: (speed) {
                        GetIt.I<MediaPlayer>().player.setSpeed(speed);
                      },
                    ),
                  );
                },
              ),
            ],
          ),
          if (Platform.isAndroid)
            AdaptiveListTile(
              dense: true,
              title: Text(S.of(context).Equalizer),
              leading: Icon(AdaptiveIcons.equalizer),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const EqualizerPage(),
                  ),
                );
              },
              trailing: Icon(Icons.chevron_right),
            ),
          if (song['artists'] != null)
            AdaptiveListTile(
              dense: true,
              title: Text(S.of(context).Artists),
              leading: Icon(AdaptiveIcons.people),
              trailing: Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pop(context);
                Modals.showArtistsBottomModal(
                  context,
                  song['artists'],
                  leading: song['thumbnails'].first['url'],
                  shouldPop: true,
                );
              },
            ),
          if (song['album'] != null)
            AdaptiveListTile(
              dense: true,
              title: Text(
                S.of(context).Album,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              leading: Icon(AdaptiveIcons.album),
              trailing: Icon(Icons.chevron_right),
              onTap: () {
                context.go(
                  '/browse',
                  extra: {
                    'endpoint': song['album']['endpoint']
                        .cast<String, dynamic>(),
                  },
                );
              },
            ),
          AdaptiveListTile(
            dense: true,
            title: Text(S.of(context).Add_To_Playlist),
            leading: Icon(AdaptiveIcons.library_add),
            onTap: () {
              Navigator.pop(context);
              Modals.addToPlaylist(context, song);
            },
          ),
          AdaptiveListTile(
            dense: true,
            leading: Icon(AdaptiveIcons.timer),
            title: Text(S.of(context).Sleep_Timer),
            onTap: () {
              showDurationPicker(
                context: context,
                initialTime: const Duration(minutes: 30),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: AdaptiveTheme.of(context).inactiveBackgroundColor,
                ),
              ).then((duration) {
                if (duration != null) {
                  if (context.mounted) {
                    context.read<MediaPlayer>().setTimer(duration);
                  }
                }
              });
            },
            trailing: ValueListenableBuilder(
              valueListenable: GetIt.I<MediaPlayer>().timerDuration,
              builder: (context, value, child) {
                return value == null
                    ? const SizedBox.shrink()
                    : TextButton.icon(
                        onPressed: () {
                          GetIt.I<MediaPlayer>().cancelTimer();
                        },
                        label: Text(formatDuration(value)),
                        icon: const Icon(CupertinoIcons.clear),
                        iconAlignment: IconAlignment.end,
                      );
              },
            ),
          ),
          AdaptiveListTile(
            dense: true,
            title: const Text('Share'),
            leading: Icon(AdaptiveIcons.share),
            onTap: () {
              Navigator.pop(context);
              Share.shareUri(
                Uri.parse(
                  'https://music.youtube.com/watch?v=${song['videoId']}',
                ),
              );
            },
          ),
        ],
      ),
    ),
  );
}

BottomModalLayout _showSelection(
  BuildContext context,
  List<SelectionItem> items,
) {
  return BottomModalLayout(
    title: Center(child: Text("Select", style: mediumTextStyle(context))),
    child: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...items.map(
            (item) => AdaptiveListTile(
              dense: true,
              title: Text(item.title),
              onTap: () {
                Navigator.pop(context, item.data);
              },
            ),
          ),
        ],
      ),
    ),
  );
}

BottomModalLayout _songBottomModal(BuildContext context, Map song) {
  return BottomModalLayout(
    title: AdaptiveListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(song['title'], maxLines: 1, overflow: TextOverflow.ellipsis),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: CachedNetworkImage(
          imageUrl: song['thumbnails'].first['url'],
          height: 50,
          width: song['type'] == 'VIDEO' ? 80 : 50,
        ),
      ),
      subtitle: song['subtitle'] != null
          ? Text(song['subtitle'], maxLines: 1, overflow: TextOverflow.ellipsis)
          : null,
      trailing: IconButton(
        onPressed: () => Share.shareUri(
          Uri.parse('https://music.youtube.com/watch?v=${song['videoId']}'),
        ),
        icon: const Icon(CupertinoIcons.share),
      ),
    ),
    child: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AdaptiveListTile(
            dense: true,
            title: Text(S.of(context).Play_Next),
            leading: Icon(AdaptiveIcons.playlist_play),
            onTap: () async {
              Navigator.pop(context);
              await GetIt.I<MediaPlayer>().playNext(Map.from(song));
            },
          ),
          AdaptiveListTile(
            dense: true,
            title: Text(S.of(context).Add_To_Queue),
            leading: Icon(AdaptiveIcons.queue_add),
            onTap: () async {
              Navigator.pop(context);
              await GetIt.I<MediaPlayer>().addToQueue(Map.from(song));
            },
          ),
          ListenableBuilder(
            listenable: GetIt.I<FavouritesManager>().listenable,
            builder: (context, child) {
              bool isFavorite = GetIt.I<FavouritesManager>().isFavourite(song);
              return AdaptiveListTile(
                dense: true,
                title: Text(
                  !isFavorite
                      ? S.of(context).Add_To_Favourites
                      : S.of(context).Remove_From_Favourites,
                ),
                leading: Icon(
                  !isFavorite ? AdaptiveIcons.heart : AdaptiveIcons.heart_fill,
                ),
                onTap: () async {
                  Navigator.pop(context);
                  GetIt.I<FavouritesManager>().addOrRemove(song);
                },
              );
            },
          ),
          AdaptiveListTile(
            dense: true,
            title: Text(S.of(context).Download),
            leading: Icon(AdaptiveIcons.download),
            onTap: () {
              Navigator.pop(context);
              BottomMessage.showText(context, S.of(context).Download_Started);
              GetIt.I<DownloadManager>().downloadSong(song);
            },
          ),
          AdaptiveListTile(
            dense: true,
            title: Text(S.of(context).Add_To_Playlist),
            leading: Icon(AdaptiveIcons.library_add),
            onTap: () {
              Navigator.pop(context);
              Modals.addToPlaylist(context, song);
            },
          ),
          AdaptiveListTile(
            dense: true,
            title: Text(S.of(context).Start_Radio),
            leading: Icon(AdaptiveIcons.radio),
            onTap: () {
              Navigator.pop(context);
              GetIt.I<MediaPlayer>().startRelated(Map.from(song), radio: true);
            },
          ),
          if (song['artists'] != null)
            AdaptiveListTile(
              dense: true,
              title: Text(S.of(context).Artists),
              leading: Icon(AdaptiveIcons.people),
              trailing: Icon(AdaptiveIcons.chevron_right),
              onTap: () {
                Navigator.pop(context);
                Modals.showArtistsBottomModal(
                  context,
                  song['artists'],
                  leading: song['thumbnails'].first['url'],
                );
              },
            ),
          if (song['album'] != null)
            AdaptiveListTile(
              dense: true,
              title: Text(
                S.of(context).Album,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              leading: Icon(AdaptiveIcons.album),
              trailing: Icon(AdaptiveIcons.chevron_right),
              onTap: () {
                Navigator.pop(context);
                context.push(
                  '/browse',
                  extra: {
                    'endpoint': song['album']['endpoint']
                        .cast<String, dynamic>(),
                  },
                );
              },
            ),
        ],
      ),
    ),
  );
}

BottomModalLayout _playlistBottomModal(BuildContext context, Map playlist) {
  return BottomModalLayout(
    title: AdaptiveListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        playlist['title'],
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      leading: (playlist['isPredefined'] != false)
          ? ClipRRect(
              borderRadius: BorderRadius.circular(
                playlist['type'] == 'ARTIST' ? 30 : 8,
              ),
              child: CachedNetworkImage(
                imageUrl: playlist['thumbnails'].first['url'].replaceAll(
                  'w540-h225',
                  'w60-h60',
                ),
                height: 40,
                width: 40,
              ),
            )
          : Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: PlaylistIconWidget(
                data: PlaylistIcons.byId(playlist['iconId']),
                size: 30,
              ),
            ),
      subtitle: playlist['subtitle'] != null
          ? Text(
              playlist['subtitle'],
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      trailing: playlist['isPredefined'] != false
          ? IconButton(
              onPressed: () => Share.shareUri(
                Uri.parse(
                  playlist['type'] == 'ARTIST'
                      ? 'https://music.youtube.com/channel/${playlist['endpoint']['browseId']}'
                      : 'https://music.youtube.com/playlist?list=${playlist['playlistId']}',
                ),
              ),
              icon: const Icon(CupertinoIcons.share),
            )
          : null,
    ),
    child: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AdaptiveListTile(
            dense: true,
            title: Text(S.of(context).Play_Next),
            leading: Icon(AdaptiveIcons.playlist_play),
            onTap: () async {
              Navigator.pop(context);
              await GetIt.I<MediaPlayer>().playNext(Map.from(playlist));
            },
          ),
          AdaptiveListTile(
            dense: true,
            title: Text(S.of(context).Add_To_Queue),
            leading: Icon(AdaptiveIcons.queue_add),
            onTap: () async {
              Navigator.pop(context);
              await GetIt.I<MediaPlayer>().addToQueue(Map.from(playlist));
            },
          ),
          AdaptiveListTile(
            dense: true,
            title: Text(S.of(context).Download),
            leading: Icon(AdaptiveIcons.download),
            onTap: () async {
              Navigator.pop(context);
              BottomMessage.showText(context, S.of(context).Download_Started);
              GetIt.I<DownloadManager>().downloadPlaylist(playlist);
            },
          ),
          if (playlist['isPredefined'] == false)
            AdaptiveListTile(
              dense: true,
              leading: const Icon(Icons.edit),
              title: Text(S.of(context).Edit),
              onTap: () {
                Navigator.pop(context);
                Modals.showEditPlaylistBottomModal(
                  context,
                  playlistId: playlist['playlistId'],
                  name: playlist['title'],
                  iconId: playlist['iconId'],
                );
              },
            ),
          AdaptiveListTile(
            dense: true,
            title: Text(
              context.watch<LibraryService>().getPlaylist(
                        playlist['playlistId'] ??
                            playlist['endpoint']['browseId'],
                      ) ==
                      null
                  ? S.of(context).Add_To_Library
                  : S.of(context).Remove_From_Library,
            ),
            leading: Icon(
              context.watch<LibraryService>().getPlaylist(
                        playlist['playlistId'] ??
                            playlist['endpoint']['browseId'],
                      ) ==
                      null
                  ? AdaptiveIcons.library_add
                  : AdaptiveIcons.library_add_check,
            ),
            onTap: () async {
              if (context.read<LibraryService>().getPlaylist(
                    playlist['playlistId'],
                  ) ==
                  null) {
                final String message = await GetIt.I<LibraryService>()
                    .addToOrRemoveFromLibrary(playlist);
                if (!context.mounted) return;
                BottomMessage.showText(context, message);
              } else {
                final bool confirm = await Modals.showConfirmBottomModal(
                  context,
                  message: S.of(context).Delete_Item_Message,
                  isDanger: true,
                );
                if (confirm != true) return;
                final String message = await GetIt.I<LibraryService>()
                    .addToOrRemoveFromLibrary(playlist);
                if (!context.mounted) return;
                BottomMessage.showText(context, message);
              }
              Navigator.pop(context);
            },
          ),
          if (playlist['playlistId'] != null && playlist['type'] == 'ARTIST')
            AdaptiveListTile(
              dense: true,
              title: Text(S.of(context).Start_Radio),
              leading: Icon(AdaptiveIcons.radio),
              onTap: () async {
                Navigator.pop(context);
                BottomMessage.showText(
                  context,
                  S.of(context).Songs_Will_Start_Playing_Soon,
                );
                await GetIt.I<MediaPlayer>().startRelated(
                  Map.from(playlist),
                  radio: true,
                  isArtist: playlist['type'] == 'ARTIST',
                );
              },
            ),
          if (playlist['artists'] != null && playlist['artists'].isNotEmpty)
            AdaptiveListTile(
              dense: true,
              title: Text(S.of(context).Artists),
              leading: Icon(AdaptiveIcons.people),
              trailing: Icon(AdaptiveIcons.chevron_right),
              onTap: () {
                Navigator.pop(context);
                Modals.showArtistsBottomModal(
                  context,
                  playlist['artists'],
                  leading: playlist['thumbnails'].first['url'],
                );
              },
            ),
          if (playlist['album'] != null)
            AdaptiveListTile(
              dense: true,
              title: Text(
                S.of(context).Album,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              leading: Icon(AdaptiveIcons.album),
              trailing: Icon(AdaptiveIcons.chevron_right),
              onTap: () => context.push(
                '/browse',
                extra: {'endpoint': playlist['album']['endpoint']},
              ),
            ),
        ],
      ),
    ),
  );
}

BottomModalLayout _favouritesBottomModal(BuildContext context, Map playlist) {
  return BottomModalLayout(
    title: AdaptiveListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        S.of(context).Favourites,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      leading: ColorIcon(
        icon: FluentIcons.heart_24_filled,
        color: Theme.of(context).colorScheme.primaryContainer,
        size: 30,
      ),
    ),
    child: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AdaptiveListTile(
            dense: true,
            title: Text(S.of(context).Play_Next),
            leading: Icon(AdaptiveIcons.playlist_play),
            onTap: () async {
              Navigator.pop(context);
              await GetIt.I<MediaPlayer>().playNext(Map.from(playlist));
            },
          ),
          AdaptiveListTile(
            dense: true,
            title: Text(S.of(context).Add_To_Queue),
            leading: Icon(AdaptiveIcons.queue_add),
            onTap: () async {
              Navigator.pop(context);
              await GetIt.I<MediaPlayer>().addToQueue(Map.from(playlist));
            },
          ),
          AdaptiveListTile(
            dense: true,
            title: Text(S.of(context).Download),
            leading: Icon(AdaptiveIcons.download),
            onTap: () async {
              Navigator.pop(context);
              BottomMessage.showText(context, S.of(context).Download_Started);
              GetIt.I<DownloadManager>().downloadPlaylist(playlist);
            },
          ),
        ],
      ),
    ),
  );
}

BottomModalLayout _downloadBottomModal(BuildContext context) {
  return BottomModalLayout(
    title: AdaptiveListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        S.of(context).Downloads,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      leading: ColorIcon(
        icon: FluentIcons.cloud_arrow_down_24_filled,
        color: Theme.of(context).colorScheme.primaryContainer,
        size: 30,
      ),
    ),
    child: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AdaptiveListTile(
            dense: true,
            title: Text(S.of(context).Downloading),
            leading: Icon(AdaptiveIcons.downloading),
            onTap: () async {
              context.push('/library/downloads/downloading');
              Navigator.pop(context);
            },
          ),
          AdaptiveListTile(
            dense: true,
            title: Text(S.of(context).Restore_Missing_Songs),
            leading: Icon(AdaptiveIcons.sync),
            onTap: () async {
              Navigator.pop(context);
              BottomMessage.showText(
                context,
                S.of(context).Restoring_Missing_Songs,
              );
              GetIt.I<DownloadManager>().restoreDownloads();
            },
          ),
          AdaptiveListTile(
            dense: true,
            title: Text(S.of(context).Delete_All_Songs),
            leading: Icon(AdaptiveIcons.delete),
            onTap: () async {
              bool shouldDelete = await Modals.showConfirmBottomModal(
                context,
                message: S.of(context).Confirm_Delete_All_Message,
                isDanger: true,
                doneText: S.of(context).Yes,
                cancelText: S.of(context).No,
              );
              if (shouldDelete) {
                if (context.mounted) {
                  Navigator.pop(context);
                  BottomMessage.showText(context, S.of(context).Deleting_Songs);
                }
                await GetIt.I<DownloadManager>().deleteAllSongs();
              }
            },
          ),
        ],
      ),
    ),
  );
}

BottomModalLayout _downloadDetailsBottomModal(
  BuildContext context,
  Map playlist,
) {
  return BottomModalLayout(
    title: AdaptiveListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        playlist['title'],
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      leading:
          (playlist['songs']?.length > 0 &&
              playlist['id'] != DownloadManager.songsPlaylistId &&
              playlist['id'] != FavouritesManager.playlistId)
          ? (playlist['type'] == "ALBUM")
                ? PlaylistThumbnail(
                    playlist: [playlist['songs'][0]],
                    size: 50,
                    radius: 8,
                  )
                : PlaylistThumbnail(
                    playlist: playlist['songs'],
                    size: 50,
                    radius: 8,
                  )
          : Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                playlist['id'] == FavouritesManager.playlistId
                    ? AdaptiveIcons.heart_fill
                    : CupertinoIcons.music_note_list,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
      subtitle: playlist['subtitle'] != null
          ? Text(
              playlist['subtitle'],
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : null,
    ),
    child: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AdaptiveListTile(
            dense: true,
            title: Text(S.of(context).Play_Next),
            leading: Icon(AdaptiveIcons.playlist_play),
            onTap: () async {
              Navigator.pop(context);
              final plst = {
                ...playlist,
                'songs': GetIt.I<DownloadManager>().getDownloadedSongs(
                  playlist['id'],
                ),
              };
              await GetIt.I<MediaPlayer>().playNext(Map.from(plst));
            },
          ),
          AdaptiveListTile(
            dense: true,
            title: Text(S.of(context).Add_To_Queue),
            leading: Icon(AdaptiveIcons.queue_add),
            onTap: () async {
              Navigator.pop(context);
              final plst = {
                ...playlist,
                'songs': GetIt.I<DownloadManager>().getDownloadedSongs(
                  playlist['id'],
                ),
              };
              await GetIt.I<MediaPlayer>().addToQueue(Map.from(plst));
            },
          ),
          AdaptiveListTile(
            dense: true,
            title: Text(S.of(context).Restore_Missing_Songs),
            leading: Icon(Icons.restore),
            onTap: () async {
              Navigator.pop(context);
              BottomMessage.showText(
                context,
                S.of(context).Restoring_Missing_Songs,
              );
              GetIt.I<DownloadManager>().restoreDownloads(
                songs: playlist['songs'],
              );
            },
          ),
          AdaptiveListTile(
            dense: true,
            title: Text(S.of(context).Delete_All_Songs),
            leading: Icon(AdaptiveIcons.delete),
            onTap: () async {
              Modals.showConfirmBottomModal(
                context,
                message: S.of(context).Confirm_Delete_All_Message,
                isDanger: true,
              ).then((bool confirm) async {
                if (confirm) {
                  if (context.mounted) {
                    Navigator.pop(context);

                    BottomMessage.showText(
                      context,
                      S.of(context).Deleting_Songs,
                    );
                  }
                  for (var song in playlist['songs']) {
                    await GetIt.I<DownloadManager>().deleteSong(
                      key: song['videoId'],
                      playlistId: playlist['id'],
                    );
                  }
                }
              });
            },
          ),
        ],
      ),
    ),
  );
}

BottomModalLayout _accentSelector(BuildContext context) {
  Color? accentColor = GetIt.I<SettingsManager>().accentColor;
  return BottomModalLayout(
    title: Center(child: Text('Select Color', style: mediumTextStyle(context))),
    actions: [
      AdaptiveButton(
        onPressed: () {
          Navigator.pop(context);
          GetIt.I<SettingsManager>().accentColor = null;
        },
        child: const Text('Reset'),
      ),
      AdaptiveFilledButton(
        child: Text(S.of(context).Done),
        onPressed: () => Navigator.pop(context),
      ),
    ],
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ColorPicker(
          pickerColor: accentColor ?? Colors.white,
          onColorChanged: (color) {
            GetIt.I<SettingsManager>().accentColor = color;
          },
          labelTypes: const [],
          portraitOnly: true,
          colorPickerWidth: min(300, MediaQuery.of(context).size.width - 32),
          pickerAreaHeightPercent: 0.7,
          enableAlpha: false,
          displayThumbColor: false,
          paletteType: PaletteType.hueWheel,
        ),
      ],
    ),
  );
}

class BottomModalLayout extends StatelessWidget {
  const BottomModalLayout({
    required this.child,
    this.title,
    this.actions,
    super.key,
  });
  final Widget child;
  final Widget? title;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.maxFinite,
      constraints: const BoxConstraints(maxWidth: 600),
      child: Material(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
          bottomLeft: Radius.circular(0),
          bottomRight: Radius.circular(0),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                if (title != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 0,
                    ),
                    child: title!,
                  ),
                Flexible(
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: child,
                  ),
                ),
                if (actions != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: actions!,
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

class SelectionItem<T> {
  final String title;
  final IconData? icon;
  final T data;

  SelectionItem({required this.title, this.icon, required this.data});
}
