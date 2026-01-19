// import 'package:expandable_text/expandable_text.dart';
// import 'package:flutter/material.dart';
// import 'package:get_it/get_it.dart';
// import 'package:gyawun/generated/l10n.dart';
// import 'package:gyawun/services/download_manager.dart';
// import 'package:gyawun/services/media_player.dart';
// import 'package:gyawun/utils/adaptive_widgets/listtile.dart';
// import 'package:gyawun/utils/bottom_modals.dart';
// import 'package:gyawun/utils/extensions.dart';
// import 'package:gyawun/utils/song_thumbnail.dart';

// class DownloadedSongTile extends StatelessWidget {
//   const DownloadedSongTile({required this.song, super.key});
//   final Map song;

//   @override
//   Widget build(BuildContext context) {
//     double height =
//         (song['aspectRatio'] != null ? 50 / song['aspectRatio'] : 50)
//             .toDouble();
//     return AdaptiveListTile(
//       onTap: () async {
//         if (song['videoId'] != null && song['status'] == 'DOWNLOADED') {
//           await GetIt.I<MediaPlayer>().playSong(Map.from(song));
//         }
//       },
//       onSecondaryTap: () {
//         if (song['videoId'] != null && song['status'] == 'DOWNLOADED') {
//           Modals.showSongBottomModal(context, song);
//         }
//       },
//       onLongPress: () {
//         if (song['videoId'] != null && song['status'] == 'DOWNLOADED') {
//           Modals.showSongBottomModal(context, song);
//         }
//       },
//       title: Text(song['title'] ?? "", maxLines: 1),
//       leading: ClipRRect(
//         borderRadius: BorderRadius.circular(3),
//         child: SongThumbnail(
//           song: song,
//           height: height,
//           width: 50,
//           fit: BoxFit.cover,
//         ),
//       ),
//       subtitle: Text(
//         song['status'] == 'DELETED'
//             ? S.of(context).FileNotFound
//             : song['status'] == 'DOWNLOADING'
//                 ? S.of(context).Downloading
//                 : song['status'] == 'QUEUED'
//                     ? S.of(context).Queued
//                     : _buildSubtitle(song),
//         maxLines: 1,
//         style: TextStyle(
//           color: song['status'] == 'DELETED'
//               ? Colors.red
//               : song['status'] == 'DOWNLOADING'
//                   ? Theme.of(context).colorScheme.primary
//                   : song['status'] == 'QUEUED'
//                       ? Theme.of(context)
//                           .colorScheme
//                           .primary
//                           .withValues(alpha: 0.5)
//                       : Colors.grey.withAlpha(250),
//         ),
//         overflow: TextOverflow.ellipsis,
//       ),
//       trailing: song['status'] == 'DELETED'
//           ? IconButton(
//               onPressed: () {
//                 GetIt.I<DownloadManager>().downloadSong(song);
//               },
//               icon: const Icon(Icons.refresh))
//           : null,
//       description: song['type'] == 'EPISODE' && song['description'] != null
//           ? ExpandableText(
//               song['description'].split('\n')?[0] ?? '',
//               expandText: S.of(context).Show_More,
//               collapseText: S.of(context).Show_Less,
//               maxLines: 3,
//               style: TextStyle(color: context.subtitleColor),
//             )
//           : null,
//     );
//   }

//   String _buildSubtitle(Map item) {
//     List sub = [];
//     if (sub.isEmpty && item['artists'] != null) {
//       for (Map artist in item['artists']) {
//         sub.add(artist['name']);
//       }
//     }
//     if (sub.isEmpty && item['album'] != null) {
//       sub.add(item['album']['name']);
//     }
//     String s = sub.join(' · ');
//     return item['subtitle'] ?? s;
//   }
// }
