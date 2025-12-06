import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gyawun_music/core/di.dart';
import 'package:gyawun_music/core/utils/snackbar.dart';
import 'package:gyawun_music/features/library/widgets/library_tile.dart';
import 'package:gyawun_music/services/audio_service/media_player.dart';
import 'package:gyawun_shared/gyawun_shared.dart';
import 'package:library_manager/library_manager.dart';
import 'package:share_plus/share_plus.dart';
import 'package:ytmusic/yt_music_base.dart';

import 'modals.dart';

class ItemBottomLayout extends StatefulWidget {
  const ItemBottomLayout({super.key, required this.item});
  final SectionItem item;

  @override
  State<ItemBottomLayout> createState() => _ItemBottomLayoutState();
}

class _ItemBottomLayoutState extends State<ItemBottomLayout> {
  late final bool isPlayable;
  late final bool isHorizontal;
  late final SectionItem item;
  late bool isFavorite;

  @override
  void initState() {
    super.initState();
    item = widget.item;
    isPlayable = item is PlayableItem;
    isHorizontal = (item.type == SectionItemType.video || item.type == SectionItemType.episode);
    isFavorite = sl<LibraryManager>().isFavourite(item.id, item.provider);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            title: Text(
              item.title,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(fontSize: 16, fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            leading: item.thumbnails.isEmpty
                ? null
                : ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: CachedNetworkImage(
                      imageUrl: item.thumbnails.first.url,
                      height: 50,
                      width: isHorizontal ? 80 : 50,
                    ),
                  ),
            subtitle: item.subtitle != null && item.subtitle!.isNotEmpty
                ? Text(
                    item.subtitle!,
                    style: Theme.of(context).textTheme.labelLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                : null,
            trailing: isPlayable
                ? IconButton(
                    onPressed: () async {
                      if (item is PlayableItem) {
                        if (isFavorite) {
                          await sl<LibraryManager>().removeFavourite(item.id, item.provider);
                          isFavorite = false;
                        } else {
                          await sl<LibraryManager>().addFavourite(item as PlayableItem);
                          isFavorite = true;
                        }
                        setState(() {});
                      }
                    },
                    icon: Icon(
                      isFavorite ? FluentIcons.heart_24_filled : FluentIcons.heart_24_regular,
                    ),
                  )
                : null,
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TopIconButton(
                      icon: FluentIcons.play_24_filled,
                      label: "Play Next",
                      onTap: () {
                        if (item is PlayableItem) {
                          sl<MediaPlayer>().addNext(item as PlayableItem);
                          Navigator.pop(context);
                        }
                      },
                    ),
                    TopIconButton(
                      icon: FluentIcons.task_list_add_24_filled,
                      label: "Add to queue",
                      onTap: () {
                        if (item is PlayableItem) {
                          sl<MediaPlayer>().addToQueue(item as PlayableItem);
                          Navigator.pop(context);
                        }
                      },
                    ),
                    TopIconButton(
                      icon: FluentIcons.share_24_filled,
                      label: "Share",
                      onTap: () async {
                        // Your generated URL
                        final String url =
                            'https://music.youtube.com/${isPlayable ? 'watch?v' : 'playlist?list'}=${item.id}';

                        // 4. Call the instance method, just as you did,
                        //    but add the 'sharePositionOrigin' to the ShareParams.
                        await SharePlus.instance.share(
                          ShareParams(
                            text: url,
                            // THIS IS THE FIX:
                            // sharePositionOrigin: sharePositionOrigin,
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (item is PlayableItem &&
                    sl<LibraryManager>()
                        .getPlaylistsNotContainingItem(item.id, item.provider)
                        .isNotEmpty)
                  if (isPlayable)
                    ListTile(
                      title: Text(
                        "Add to Playlist",
                        style: Theme.of(
                          context,
                        ).textTheme.bodyLarge?.copyWith(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      leading: const Icon(FluentIcons.document_one_page_add_24_filled),
                      onTap: () async {
                        Navigator.pop(context);
                        await Modals.showAddToPlaylist(context, item as PlayableItem);
                      },
                    ),
                // if (isPlayable)
                //   ListTile(
                //     title: Text(
                //       "Download",
                //       style: Theme.of(
                //         context,
                //       ).textTheme.bodyLarge?.copyWith(fontSize: 16, fontWeight: FontWeight.w500),
                //     ),
                //     leading: const Icon(FluentIcons.cloud_arrow_down_24_filled),
                //     onTap: () {
                //       Navigator.pop(context);
                //       // Modals.addToPlaylist(context, song);
                //     },
                //   ),
                if (item.radioEndpoint != null)
                  ListTile(
                    title: Text(
                      "Start Radio",
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    leading: const Icon(FluentIcons.remix_add_24_filled),
                    onTap: () async {
                      Navigator.pop(context);
                      BottomSnackbar.showMessage(context, "Play starting");
                      final items = await sl<YTMusic>().getNextSongs(
                        body: item.radioEndpoint!.cast(),
                      );
                      final songs = items.whereType<PlayableItem>().toList();
                      await sl<MediaPlayer>().playSongs(songs);
                    },
                  ),
                if (item.shuffleEndpoint != null)
                  ListTile(
                    title: Text(
                      "Shuffle Play",
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    leading: const Icon(FluentIcons.arrow_shuffle_24_filled),
                    onTap: () async {
                      Navigator.pop(context);
                      Navigator.pop(context);
                      BottomSnackbar.showMessage(context, "Play starting");
                      final items = await sl<YTMusic>().getNextSongs(
                        body: item.shuffleEndpoint!.cast(),
                      );
                      final songs = items.whereType<PlayableItem>().toList();
                      await sl<MediaPlayer>().playSongs(songs);
                    },
                  ),

                if (item.artists.isNotEmpty)
                  ListTile(
                    title: Text(
                      "Artists",
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    leading: const Icon(FluentIcons.people_24_filled),
                    trailing: const Icon(FluentIcons.chevron_right_24_filled),
                    onTap: () {
                      Navigator.pop(context);
                      Modals.showArtistsBottomSheet(context, item.artists);
                    },
                  ),
                if (item is PlayableItem && (item as PlayableItem).album != null)
                  ListTile(
                    title: Text(
                      "Album",
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(fontSize: 16, fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    leading: const Icon(FluentIcons.radio_button_24_filled),
                    trailing: const Icon(FluentIcons.chevron_right_24_filled),
                    onTap: () {
                      Navigator.pop(context);
                      context.push(
                        '/ytmusic/album/${jsonEncode((item as PlayableItem).album!.endpoint)}',
                      );
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CreatePlaylistLayout extends StatefulWidget {
  const CreatePlaylistLayout({super.key});

  @override
  State<CreatePlaylistLayout> createState() => _CreatePlaylistLayoutState();
}

class _CreatePlaylistLayoutState extends State<CreatePlaylistLayout> {
  final controller = TextEditingController();
  final formKey = GlobalKey<FormState>();

  @override
  dispose() {
    super.dispose();
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: MediaQuery.of(context).viewInsets,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Create Playlist", style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),

              /// NAME FIELD
              TextFormField(
                controller: controller,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: "Playlist Name",
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Please enter a name";
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              /// ACTION BUTTONS
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(child: const Text("Cancel"), onPressed: () => Navigator.pop(context)),
                  const SizedBox(width: 8),
                  FilledButton(
                    child: const Text("Create"),
                    onPressed: () {
                      if (!formKey.currentState!.validate()) return;

                      final name = controller.text.trim();

                      Navigator.pop(context, name);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AddToPlaylistLayout extends StatefulWidget {
  const AddToPlaylistLayout({super.key, required this.item});
  final PlayableItem item;

  @override
  State<AddToPlaylistLayout> createState() => _AddToPlaylistLayoutState();
}

class _AddToPlaylistLayoutState extends State<AddToPlaylistLayout> {
  late final List<Playlist> playlists;

  @override
  initState() {
    super.initState();
    playlists = sl<LibraryManager>().getPlaylistsNotContainingItem(
      widget.item.id,
      widget.item.provider,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (playlists.isEmpty) const Text("No Playlist"),
          ...playlists.indexed.map(
            (playlist) => LibraryTile(
              title: playlist.$2.name,
              isFirst: playlist.$1 == 0,
              isLast: playlist.$1 == playlists.length - 1,
              onTap: () async {
                await sl<LibraryManager>().addSongToPlaylist(
                  playlistId: playlist.$2.id,
                  item: widget.item,
                );
                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ModalLayouts {
  // static Widget itemBottomLayout(BuildContext context, SectionItem item) {

  //   return
  // }

  static Widget artistsBottomLayout(BuildContext context, List<Artist> artists) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final artist in artists) ...[
              ListTile(
                title: Text(artist.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                leading: const Icon(Icons.album),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/ytmusic/artist/${jsonEncode(artist.endpoint)}');
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class TopIconButton extends StatelessWidget {
  const TopIconButton({super.key, required this.icon, required this.label, this.onTap});
  final IconData icon;
  final String label;
  final void Function()? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceBright,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Icon(icon),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
