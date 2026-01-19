// import 'dart:io';

// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:get_it/get_it.dart';
// import 'package:gyawun/generated/l10n.dart';
// import 'package:gyawun/services/media_player.dart';
// import 'package:gyawun/themes/colors.dart';
// import 'package:gyawun/utils/adaptive_widgets/buttons.dart';
// import 'package:gyawun/utils/bottom_modals.dart';
// import 'package:gyawun/utils/extensions.dart';
// import 'package:gyawun/utils/playlist_thumbnail.dart';

// class DownloadPlaylistHeader extends StatelessWidget {
//   const DownloadPlaylistHeader({
//     super.key,
//     required this.playlist,
//     required this.imageType,
//   });

//   final Map playlist;
//   final String imageType;

//   Widget _buildImage(List songs, double maxWidth,
//       {bool isRound = false, bool isDark = false}) {
//     return (songs.isNotEmpty && imageType == "SONGS")
//         ? Container(
//             height: 200,
//             width: 200,
//             decoration: BoxDecoration(
//               color: greyColor,
//               borderRadius: BorderRadius.circular(3),
//             ),
//             child: Icon(
//               CupertinoIcons.music_note_list,
//               color: isDark ? Colors.white : Colors.black,
//             ),
//           )
//         : (songs.isNotEmpty && imageType == "ALBUM")
//             ? PlaylistThumbnail(playslist: [songs[0]], size: 225, radius: 8)
//             : PlaylistThumbnail(playslist: songs, size: 225, radius: 8);
//   }

//   Padding _buildContent(Map playlist, BuildContext context,
//       {bool isRow = false}) {
//     return Padding(
//       padding: const EdgeInsets.only(left: 8, top: 4),
//       child: Column(
//         crossAxisAlignment:
//             isRow ? CrossAxisAlignment.start : CrossAxisAlignment.center,
//         mainAxisAlignment:
//             isRow ? MainAxisAlignment.start : MainAxisAlignment.center,
//         children: [
//           if (playlist['songs'] != null)
//             Padding(
//               padding: const EdgeInsets.symmetric(vertical: 4),
//               child: Text(S.of(context).nSongs(playlist['songs'].length),
//                   maxLines: 2),
//             ),
//           Wrap(
//             spacing: 8,
//             runSpacing: 8,
//             alignment: WrapAlignment.center,
//             runAlignment: WrapAlignment.center,
//             crossAxisAlignment: WrapCrossAlignment.center,
//             children: [
//               if (playlist['songs'].isNotEmpty)
//                 AdaptiveFilledButton(
//                   onPressed: () {
//                     GetIt.I<MediaPlayer>().playAll(playlist['songs']);
//                   },
//                   padding:
//                       const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//                   shape: RoundedRectangleBorder(
//                     borderRadius:
//                         BorderRadius.circular(Platform.isWindows ? 8 : 35),
//                   ),
//                   color: context.isDarkMode ? Colors.white : Colors.black,
//                   child: Row(
//                     mainAxisSize: MainAxisSize.min,
//                     crossAxisAlignment: CrossAxisAlignment.center,
//                     children: [
//                       Icon(
//                         Icons.play_arrow,
//                         color: context.isDarkMode ? Colors.black : Colors.white,
//                         size: 24,
//                       ),
//                       const SizedBox(width: 8),
//                       const Text("Play All", style: TextStyle(fontSize: 18))
//                     ],
//                   ),
//                 ),
//               AdaptiveFilledButton(
//                 shape: const CircleBorder(),
//                 color: greyColor,
//                 padding: const EdgeInsets.all(14),
//                 onPressed: () {
//                   Modals.showDownloadDetailsBottomModal(context, playlist);
//                 },
//                 child: Icon(
//                   Icons.more_vert,
//                   size: 20,
//                   color: context.isDarkMode ? Colors.white : Colors.black,
//                 ),
//               )
//             ],
//           )
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return SizedBox(
//       width: double.maxFinite,
//       child: Card(
//         child: LayoutBuilder(builder: (context, constraints) {
//           return constraints.maxWidth > 600
//               ? Row(
//                   children: [
//                     if (playlist['songs'] != null)
//                       _buildImage(playlist['songs'], constraints.maxWidth,
//                           isRound: playlist['type'] == 'ARTIST',
//                           isDark: context.isDarkMode),
//                     const SizedBox(width: 4),
//                     Expanded(
//                         child: _buildContent(playlist, context, isRow: true)),
//                   ],
//                 )
//               : Column(
//                   children: [
//                     if (playlist['songs'] != null)
//                       _buildImage(playlist['songs'], constraints.maxWidth,
//                           isRound: playlist['type'] == 'ARTIST',
//                           isDark: context.isDarkMode),
//                     SizedBox(height: playlist['thumbnails'] != null ? 4 : 0),
//                     _buildContent(playlist, context),
//                   ],
//                 );
//         }),
//       ),
//     );
//   }
// }
