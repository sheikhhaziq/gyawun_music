import 'dart:io';
import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:duration_picker/duration_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:gyawun/utils/playlist_thumbnail.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../generated/l10n.dart';
import '../screens/settings_screen/player/equalizer_screen.dart';
import '../services/bottom_message.dart';
import '../services/download_manager.dart';
import '../services/library.dart';
import '../services/media_player.dart';
import '../services/settings_manager.dart';
import '../themes/colors.dart';
import '../themes/text_styles.dart';
import 'adaptive_widgets/adaptive_widgets.dart';
import 'check_update.dart';
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

  static Future showUpdateDialog(
          BuildContext context, UpdateInfo? updateInfo) =>
      showDialog(
        context: context,
        useRootNavigator: false,
        builder: (context) {
          return _updateDialog(context, updateInfo);
        },
      );
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
      builder: (context) => _textFieldBottomModal(context,
          title: title, hintText: hintText, doneText: doneText),
    );
  }

  static Future<T?> showSelection<T>(
      BuildContext context, List<SelectionItem> items) {
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

  static void showPlayerOptionsModal(
    BuildContext context,
    Map song,
  ) {
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
      BuildContext context, Map playlist) {
    showModalBottomSheet(
      useRootNavigator: false,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      isScrollControlled: true,
      context: context,
      builder: (context) => _downloadDetailsBottomModal(context, playlist),
    );
  }

  static Future showArtistsBottomModal(BuildContext context, List artists,
      {String? leading, bool shouldPop = false}) {
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
    String title = '';

    showModalBottomSheet(
      useRootNavigator: false,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      isScrollControlled: true,
      context: context,
      builder: (context) => _createPlaylistModal(title, context, item),
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

  static void showPlaylistRenameBottomModal(BuildContext context,
      {required String playlistId, String? name}) {
    showModalBottomSheet(
      useRootNavigator: false,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      isScrollControlled: true,
      context: context,
      builder: (context) => _playlistRenameBottomModal(context,
          name: name, playlistId: playlistId),
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
            builder: (context) => _confirmBottomModal(context,
                message: message,
                isDanger: isDanger,
                doneText: doneText,
                cancelText: cancelText)) ??
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
      child: Text(
        S.of(context).Confirm,
        style: bigTextStyle(context),
      ),
    ),
    actions: [
      AdaptiveButton(
        color: Platform.isAndroid
            ? Theme.of(context).colorScheme.primary.withAlpha(30)
            : null,
        onPressed: () {
          Navigator.pop(context, false);
        },
        child: Text(
          cancelText ?? S.of(context).No,
        ),
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
      )
    ],
    child: SingleChildScrollView(
      child: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    ),
  );
}

BottomModalLayout _playlistRenameBottomModal(BuildContext context,
    {String? name, required String playlistId}) {
  TextEditingController controller = TextEditingController();
  controller.text = name ?? '';
  return BottomModalLayout(
      title: Center(
        child: Text(
          S.of(context).Rename_Playlist,
          style: mediumTextStyle(context),
        ),
      ),
      actions: [
        AdaptiveFilledButton(
          onPressed: () async {
            String text = controller.text;
            context
                .read<LibraryService>()
                .renamePlaylist(
                    playlistId: playlistId,
                    title: text.trim().isNotEmpty ? text : null)
                .then((String message) {
              Navigator.pop(context);
              BottomMessage.showText(context, message);
            });
          },
          child: Text(S.of(context).Rename),
        )
      ],
      child: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16),
              child: Column(
                children: [
                  AdaptiveTextField(
                    controller: controller,
                    fillColor: greyColor,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 2, horizontal: 16),
                    hintText: S.of(context).Playlist_Name,
                    prefix: const Icon(Icons.title),
                  ),
                ],
              ),
            )
          ],
        ),
      ));
}

BottomModalLayout _artistsBottomModal(
    BuildContext context, List<dynamic> artists,
    {bool shouldPop = false}) {
  return BottomModalLayout(
      title: Center(
        child: Text(
          S.of(context).Artists,
          style: mediumTextStyle(context),
        ),
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
                          'endpoint':
                              artist['endpoint'].cast<String, dynamic>(),
                        },
                      );
                    } else {
                      Navigator.pop(context);
                      context.push(
                        '/browse',
                        extra: {
                          'endpoint':
                              artist['endpoint'].cast<String, dynamic>(),
                        },
                      );
                    }
                  }),
            ),
          ],
        ),
      ));
}

Widget _createPlaylistModal(
    String title, BuildContext context, Map<dynamic, dynamic>? item) {
  return BottomModalLayout(
    title: Center(
        child: Text(
      S.of(context).Create_Playlist,
      style: mediumTextStyle(context),
    )),
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
          context
              .read<LibraryService>()
              .createPlaylist(title, item: item)
              .then((String message) {
            Navigator.pop(context);
            BottomMessage.showText(context, message);
          });
        },
        child: Text(
          S.of(context).Create,
          style: TextStyle(
              color: context.isDarkMode ? Colors.black : Colors.white),
        ),
      )
    ],
    child: SingleChildScrollView(
      child: Column(
        children: [
          Column(
            children: [
              AdaptiveTextField(
                onChanged: (value) => title = value,
                fillColor: Platform.isAndroid ? greyColor : null,
                hintText: S.of(context).Playlist_Name,
                prefix: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Icon(Icons.title),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

Widget _importPlaylistModal(BuildContext context) {
  String title = '';
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
          String message =
              await GetIt.I<LibraryService>().importPlaylist(title);
          if (context.mounted) {
            Navigator.pop(context);
            Navigator.pop(context);
            BottomMessage.showText(context, message);
          }
        },
        child: Text(
          S.of(context).Import,
          style: TextStyle(
              color: context.isDarkMode ? Colors.black : Colors.white),
        ),
      )
    ],
    child: SingleChildScrollView(
      child: Column(
        children: [
          Column(
            children: [
              AdaptiveTextField(
                onChanged: (value) => title = value,
                keyboardType: TextInputType.url,
                hintText: 'https://music.youtube.com/playlist?list=',
                prefix: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Icon(Icons.title),
                ),
                fillColor: Platform.isWindows ? null : greyColor,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 2, horizontal: 16),
              ),
            ],
          ),
        ],
      ),
    ),
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
          icon: const Icon(
            Icons.playlist_add,
            size: 20,
          )),
    ),
    child: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...context.read<LibraryService>().userPlaylists.map((key, playlist) {
            return MapEntry(
              key,
              playlist['songs'].contains(item)
                  ? const SizedBox.shrink()
                  : AdaptiveListTile(
                      dense: true,
                      title: Text(playlist['title']),
                      leading: playlist['isPredefined'] == true
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(
                                  playlist['type'] == 'ARTIST' ? 50 : 3),
                              child: CachedNetworkImage(
                                imageUrl: playlist['thumbnails']
                                    .first['url']
                                    .replaceAll('w540-h225', 'w60-h60'),
                                height: 50,
                                width: 50,
                              ))
                          : (playlist['songs'] != null &&
                                  playlist['songs']?.length > 0)
                              ? PlaylistThumbnail(
                                  playslist: playlist['songs'], size: 50)
                              : Container(
                                  height: 50,
                                  width: 50,
                                  decoration: BoxDecoration(
                                    color: greyColor,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: Icon(
                                    CupertinoIcons.music_note_list,
                                    color: context.isDarkMode
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                      onTap: () async {
                        await context
                            .read<LibraryService>()
                            .addToPlaylist(item: item, key: key)
                            .then((String message) {
                          Navigator.pop(context);
                          BottomMessage.showText(context, message);
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

SizedBox _updateDialog(BuildContext context, UpdateInfo? updateInfo) {
  final f = DateFormat('MMMM dd, yyyy');

  return SizedBox(
    height: MediaQuery.of(context).size.height,
    width: MediaQuery.of(context).size.width,
    child: LayoutBuilder(builder: (context, constraints) {
      return AlertDialog(
        icon: Center(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: Colors.green.withAlpha(100),
                borderRadius: BorderRadius.circular(16)),
            child: const Icon(
              Icons.update_outlined,
              size: 70,
            ),
          ),
        ),
        scrollable: true,
        title: Column(
          children: [
            Text(updateInfo != null ? 'Update Available' : 'Update Info'),
            if (updateInfo != null)
              Text(
                '${updateInfo.name}\n${f.format(DateTime.parse(updateInfo.publishedAt))}',
                style: TextStyle(fontSize: 16, color: context.subtitleColor),
              )
          ],
        ),
        content: updateInfo != null
            ? SizedBox(
                width: constraints.maxWidth,
                height: constraints.maxHeight - 400,
                child: Markdown(
                  data: updateInfo.body,
                  shrinkWrap: true,
                  softLineBreak: true,
                  onTapLink: (text, href, title) {
                    if (href != null) {
                      launchUrl(Uri.parse(href),
                          mode: LaunchMode.platformDefault);
                    }
                  },
                ),
              )
            : const Center(
                child: Text("You are already up to date."),
              ),
        actions: [
          if (updateInfo != null)
            AdaptiveButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
          AdaptiveFilledButton(
            onPressed: () {
              Navigator.pop(context);
              if (updateInfo != null) {
                launchUrl(Uri.parse(updateInfo.downloadUrl),
                    mode: LaunchMode.externalApplication);
              }
            },
            child: Text(updateInfo != null ? 'Update' : 'Done'),
          ),
        ],
      );
    }),
  );
}

BottomModalLayout _textFieldBottomModal(BuildContext context,
    {String? title, String? hintText, String? doneText}) {
  String? text;
  return BottomModalLayout(
    title: (title != null)
        ? Center(
            child: Text(
              title,
              style: mediumTextStyle(context),
            ),
          )
        : null,
    actions: [
      AdaptiveFilledButton(
        onPressed: () async {
          Navigator.pop(context, text);
        },
        child: Text(doneText ?? S.of(context).Done),
      )
    ],
    child: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              children: [
                AdaptiveTextField(
                  onChanged: (value) => text = value,
                  fillColor: greyColor,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 2, horizontal: 16),
                  hintText: hintText,
                  prefix: const Icon(Icons.title),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
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
                            : GetIt.I<MediaPlayer>().player.volume),
                  ),
                  title: AdaptiveSlider(
                    label: (((progress.hasData && progress.data != null)
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
                    label: ((progress.hasData && progress.data != null)
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
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => const EqualizerScreen()));
            },
            trailing: Icon(AdaptiveIcons.chevron_right),
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
                shouldPop: true,
              );
            },
          ),
        if (song['album'] != null)
          AdaptiveListTile(
              dense: true,
              title: Text(S.of(context).Album,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              leading: Icon(AdaptiveIcons.album),
              trailing: Icon(AdaptiveIcons.chevron_right),
              onTap: () {
                context.go('/browse', extra: {
                  'endpoint': song['album']['endpoint'].cast<String, dynamic>(),
                });
              }),
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
                )).then(
              (duration) {
                if (duration != null) {
                  context.read<MediaPlayer>().setTimer(duration);
                }
              },
            );
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
              Uri.parse('https://music.youtube.com/watch?v=${song['videoId']}'),
            );
          },
        ),
      ],
    ),
  ));
}

BottomModalLayout _showSelection(
    BuildContext context, List<SelectionItem> items) {
  return BottomModalLayout(
    title: Center(
      child: Text(
        "Select",
        style: mediumTextStyle(context),
      ),
    ),
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
          onPressed: () => Share.shareUri(Uri.parse(
              'https://music.youtube.com/watch?v=${song['videoId']}')),
          icon: const Icon(CupertinoIcons.share)),
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
          ValueListenableBuilder(
            valueListenable: Hive.box('FAVOURITES').listenable(),
            builder: (context, value, child) {
              Map? item = value.get(song['videoId']);
              return AdaptiveListTile(
                dense: true,
                title: Text(item == null
                    ? S.of(context).Add_To_Favourites
                    : S.of(context).Remove_From_Favourites),
                leading: Icon(item == null
                    ? AdaptiveIcons.heart
                    : AdaptiveIcons.heart_fill),
                onTap: () async {
                  Navigator.pop(context);
                  if (item == null) {
                    await Hive.box('FAVOURITES').put(
                      song['videoId'],
                      {
                        ...song,
                        'createdAt': DateTime.now().millisecondsSinceEpoch
                      },
                    );
                  } else {
                    await value.delete(song['videoId']);
                  }
                },
              );
            },
          ),
          if (!['DOWNLOADING', 'DOWNLOADED'].contains(song['status']))
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
                Modals.showArtistsBottomModal(context, song['artists'],
                    leading: song['thumbnails'].first['url']);
              },
            ),
          if (song['album'] != null)
            AdaptiveListTile(
                dense: true,
                title: Text(S.of(context).Album,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                leading: Icon(AdaptiveIcons.album),
                trailing: Icon(AdaptiveIcons.chevron_right),
                onTap: () {
                  Navigator.pop(context);
                  context.push(
                    '/browse',
                    extra: {
                      'endpoint':
                          song['album']['endpoint'].cast<String, dynamic>(),
                    },
                  );
                }),
        ],
      ),
    ),
  );
}

BottomModalLayout _playlistBottomModal(BuildContext context, Map playlist) {
  return BottomModalLayout(
    title: AdaptiveListTile(
      contentPadding: EdgeInsets.zero,
      title:
          Text(playlist['title'], maxLines: 1, overflow: TextOverflow.ellipsis),
      leading: playlist['isPredefined'] != false ||
              (playlist['songs'] != null && playlist['songs']?.length > 0)
          ? ClipRRect(
              borderRadius:
                  BorderRadius.circular(playlist['type'] == 'ARTIST' ? 50 : 10),
              child: CachedNetworkImage(
                imageUrl: playlist['thumbnails']?.isNotEmpty == true
                    ? playlist['thumbnails'].first['url']
                    : playlist['isPredefined'] == true
                        ? playlist['thumbnails']
                            .first['url']
                            .replaceAll('w540-h225', 'w60-h60')
                        : playlist['songs'].first['thumbnails'].first['url'],
                height: 50,
                width: 50,
              ),
            )
          : Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                color: greyColor,
                borderRadius: BorderRadius.circular(
                    playlist['type'] == 'ARTIST' ? 50 : 10),
              ),
              child: Icon(
                CupertinoIcons.music_note_list,
                color: context.isDarkMode ? Colors.white : Colors.black,
              ),
            ),
      subtitle: playlist['subtitle'] != null
          ? Text(playlist['subtitle'],
              maxLines: 1, overflow: TextOverflow.ellipsis)
          : null,
      trailing: playlist['isPredefined'] != false
          ? IconButton(
              onPressed: () => Share.shareUri(Uri.parse(playlist['type'] ==
                      'ARTIST'
                  ? 'https://music.youtube.com/channel/${playlist['endpoint']['browseId']}'
                  : 'https://music.youtube.com/playlist?list=${playlist['playlistId']}')),
              icon: const Icon(CupertinoIcons.share))
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
              GetIt.I<MediaPlayer>().player.play();
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
              leading: const Icon(Icons.title),
              title: Text(S.of(context).Rename),
              onTap: () {
                Navigator.pop(context);
                Modals.showPlaylistRenameBottomModal(context,
                    playlistId: playlist['playlistId'],
                    name: playlist['title']);
              },
            ),
          AdaptiveListTile(
            dense: true,
            title: Text(
              context.watch<LibraryService>().getPlaylist(
                          playlist['playlistId'] ??
                              playlist['endpoint']['browseId']) ==
                      null
                  ? S.of(context).Add_To_Library
                  : S.of(context).Remove_From_Library,
            ),
            leading: Icon(context.watch<LibraryService>().getPlaylist(
                        playlist['playlistId'] ??
                            playlist['endpoint']['browseId']) ==
                    null
                ? AdaptiveIcons.library_add
                : AdaptiveIcons.library_add_check),
            onTap: () {
              Navigator.pop(context);
              if (context
                      .read<LibraryService>()
                      .getPlaylist(playlist['playlistId']) ==
                  null) {
                GetIt.I<LibraryService>()
                    .addToOrRemoveFromLibrary(playlist)
                    .then((String message) {
                  BottomMessage.showText(context, message);
                });
              } else {
                Modals.showConfirmBottomModal(
                  context,
                  message: S.of(context).Delete_Item_Message,
                  isDanger: true,
                ).then((bool confirm) {
                  if (confirm) {
                    GetIt.I<LibraryService>()
                        .addToOrRemoveFromLibrary(playlist)
                        .then((String message) {
                      BottomMessage.showText(context, message);
                    });
                  }
                });
              }
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
                    context, S.of(context).Songs_Will_Start_Playing_Soon);
                await GetIt.I<MediaPlayer>().startRelated(Map.from(playlist),
                    radio: true, isArtist: playlist['type'] == 'ARTIST');
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
                Modals.showArtistsBottomModal(context, playlist['artists'],
                    leading: playlist['thumbnails'].first['url']);
              },
            ),
          if (playlist['album'] != null)
            AdaptiveListTile(
              dense: true,
              title: Text(S.of(context).Album,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              leading: Icon(AdaptiveIcons.album),
              trailing: Icon(AdaptiveIcons.chevron_right),
              onTap: () => context.push(
                '/browse',
                extra: {
                  'endpoint': playlist['album']['endpoint'],
                },
              ),
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
      title: Text(S.of(context).Downloads,
          maxLines: 1, overflow: TextOverflow.ellipsis),
      leading: Container(
        height: 50,
        width: 50,
        decoration: BoxDecoration(
          color: greyColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          AdaptiveIcons.download,
          color: context.isDarkMode ? Colors.white : Colors.black,
        ),
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
              context.push('/saved/downloads/downloading');
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
                  context, S.of(context).Restoring_Missing_Songs);
              GetIt.I<DownloadManager>().restoreDownloads();
            },
          ),
          AdaptiveListTile(
            dense: true,
            title: Text(S.of(context).Delete_All_Songs),
            leading: Icon(AdaptiveIcons.delete),
            onTap: () async {
              bool shouldDelete = await Modals.showConfirmBottomModal(context,
                  message: S.of(context).Confirm_Delete_All_Message,
                  isDanger: true,
                  doneText: S.of(context).Yes,
                  cancelText: S.of(context).No);
              if (shouldDelete) {
                Navigator.pop(context);
                BottomMessage.showText(context, S.of(context).Deleting_Songs);
                List songs = Hive.box('DOWNLOADS').values.toList();
                for (var song in songs) {
                  await Hive.box('DOWNLOADS').delete(song['videoId']);
                  if (song.containsKey('path')) {
                    String path = song['path'];
                    try {
                      File(path).delete();
                    } catch (e) {
                      debugPrint(e.toString());
                    }
                  }
                }
              }
            },
          ),
        ],
      ),
    ),
  );
}

BottomModalLayout _downloadDetailsBottomModal(
    BuildContext context, Map playlist) {
  return BottomModalLayout(
    title: AdaptiveListTile(
      contentPadding: EdgeInsets.zero,
      title:
          Text(playlist['title'], maxLines: 1, overflow: TextOverflow.ellipsis),
      leading: (playlist['songs']?.length > 0)
          ? (playlist['type'] == "ALBUM")
              ? PlaylistThumbnail(
                  playslist: [playlist['songs'][0]], size: 50, radius: 8)
              : PlaylistThumbnail(
                  playslist: playlist['songs'], size: 50, radius: 8)
          : Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                color: greyColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                CupertinoIcons.music_note_list,
                color: context.isDarkMode ? Colors.white : Colors.black,
              ),
            ),
      subtitle: playlist['subtitle'] != null
          ? Text(playlist['subtitle'],
              maxLines: 1, overflow: TextOverflow.ellipsis)
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
              GetIt.I<MediaPlayer>().player.play();
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
            title: Text(S.of(context).Restore_Missing_Songs),
            leading: Icon(Icons.restore),
            onTap: () async {
              Navigator.pop(context);
              BottomMessage.showText(
                  context, S.of(context).Restoring_Missing_Songs);
              GetIt.I<DownloadManager>()
                  .restoreDownloads(songs: playlist['songs']);
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
              ).then(
                (bool confirm) async {
                  if (confirm) {
                    Navigator.pop(context);
                    BottomMessage.showText(
                        context, S.of(context).Deleting_Songs);
                    for (var song in playlist['songs']) {
                      await GetIt.I<DownloadManager>().deleteSong(
                        key: song['videoId'],
                        path: song['path'],
                        playlistId: playlist['id'],
                      );
                    }
                  }
                },
              );
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
    title: Center(
      child: Text('Select Color', style: mediumTextStyle(context)),
    ),
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
                if (title != null)
                  Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 0),
                      child: title!),
                child,
                if (actions != null)
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: actions!,
                    ),
                  )
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
