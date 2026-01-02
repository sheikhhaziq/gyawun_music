import 'dart:core';

import '../helpers.dart';

Map<String, dynamic> handlePageHeader(Map<String, dynamic> header,
    {Map? editHeader}) {
  List? subruns = nav(header, ['subtitle', 'runs']) ??
      nav(header, ['straplineTextOne', 'runs']);
  List? secondSubruns = nav(header, ['secondSubtitle', 'runs']);
  Map<String, dynamic> result = {
    'title': nav(header, ['title', 'runs', 0, 'text']),
    'subtitle': subruns?.map((run) => run['text']).join('') ??
        nav(header, [
          'subscriptionButton',
          'subscribeButtonRenderer',
          'longSubscriberCountText',
          'runs',
          0,
          'text'
        ]),
    'secondSubtitle': secondSubruns?.map((run) => run['text']).join(''),
    'type': nav(header, ['subscriptionButton']) != null ? 'ARTIST' : null,
    'thumbnails': nav(header, [
          'thumbnail',
          'croppedSquareThumbnailRenderer',
          'thumbnail',
          'thumbnails'
        ]) ??
        nav(header, [
          'thumbnail',
          'musicThumbnailRenderer',
          'thumbnail',
          'thumbnails'
        ]) ??
        nav(header, [
          'foregroundThumbnail',
          'musicThumbnailRenderer',
          'thumbnail',
          'thumbnails'
        ]),
    'description': nav(header, ['description', 'runs', 0, 'text']) ??
        nav(header, [
          'description',
          'musicDescriptionShelfRenderer',
          'description',
          'runs',
          0,
          'text'
        ]),
    'playlistId': nav(header, [
      'playButton',
      'buttonRenderer',
      'navigationEndpoint',
      'watchEndpoint',
      'playlistId'
    ])?.replaceAll('RDAMPL', ''),
    'playlistRadioId': nav(header, [
      'startRadioButton',
      'buttonRenderer',
      'navigationEndpoint',
      'watchEndpoint',
      'playlistId'
    ])?.replaceAll('RDAMPL', ''),
    'videoId': nav(header, [
      'buttons',
      0,
      'musicPlayButtonRenderer',
      'playNavigationEndpoint',
      'watchEndpoint',
      'videoId'
    ]),
    'params': nav(header, [
      'startRadioButton',
      'buttonRenderer',
      'navigationEndpoint',
      'watchEndpoint',
      'params'
    ]),
    'channelId': nav(
        header, ['subscriptionButton', 'subscribeButtonRenderer', 'channelId']),
    'artists': [],
  };
  if (subruns != null) {
    for (Map run in subruns) {
      Map? navigationEndpoint = nav(run, ['navigationEndpoint']);
      Map? browseEndpoint = nav(navigationEndpoint, ['browseEndpoint']);
      String? pageType = nav(browseEndpoint, [
        'browseEndpointContextSupportedConfigs',
        'browseEndpointContextMusicConfig',
        'pageType'
      ]);
      if (pageType == 'MUSIC_PAGE_TYPE_ARTIST') {
        result['artists'].add({
          'name': nav(run, ['text']),
          'endpoint': browseEndpoint
        });
      } else if (pageType == 'MUSIC_PAGE_TYPE_ALBUM') {
        result['album'] = {
          'name': nav(run, ['text']),
          'endpoint': browseEndpoint
        };
      }
    }
  }
  List? menuItems = nav(header, ['menu', 'menuRenderer', 'items']) ??
      (nav(header, ['buttons']) as List?)
              ?.firstWhere((el) => el['menuRenderer'] != null)?['menuRenderer']
          ?['items'];
  if (menuItems != null) {
    for (Map run in menuItems) {
      String? iconType =
          nav(run, ['menuNavigationItemRenderer', 'icon', 'iconType']) ??
              nav(run, ['menuServiceItemRenderer', 'icon', 'iconType']) ??
              nav(run,
                  ['toggleMenuServiceItemRenderer', 'defaultIcon', 'iconType']);
      if (iconType == 'MUSIC_SHUFFLE') {
        result['playlistId'] ??= nav(run, [
          'menuNavigationItemRenderer',
          'navigationEndpoint',
          'watchPlaylistEndpoint',
          'playlistId'
        ]);
      } else if (iconType == 'MIX') {
        result['playlistRadioId'] ??= nav(run, [
          'menuNavigationItemRenderer',
          'navigationEndpoint',
          'watchPlaylistEndpoint',
          'playlistId'
        ])?.replaceAll('RDAMPL', '');
      } else if (iconType == 'QUEUE_PLAY_NEXT') {
        result['playlistId'] ??= nav(run, [
          'menuServiceItemRenderer',
          'serviceEndpoint',
          'queueAddEndpoint',
          'queueTarget',
          'playlistId'
        ]);
      } else if (iconType == 'LIBRARY_ADD') {
        result['playlistId'] ??= nav(run, [
          'toggleMenuServiceItemRenderer',
          'toggledServiceEndpoint',
          'likeEndpoint',
          'target',
          'playlistId'
        ]);
      }
    }
  }
  if (editHeader != null) {
    result['privacy'] = editHeader['privacy'];
  }
  result.removeWhere((key, val) => val == null || val.toString().isEmpty);
  return result;
}

List handleContents(List contents, {List? thumbnails}) {
  List contentsResult = [];
  for (Map content in contents) {
    Map result = {};
    Map? musicResponsiveListItemRenderer =
        nav(content, ['musicResponsiveListItemRenderer']);
    Map? musicTwoRowItemRenderer = nav(content, ['musicTwoRowItemRenderer']);
    Map? musicMultiRowListItemRenderer =
        nav(content, ['musicMultiRowListItemRenderer']);
    Map? playlistPanelVideoRenderer =
        nav(content, ['playlistPanelVideoRenderer']);
    if (musicResponsiveListItemRenderer != null) {
      result = handleMusicResponsiveListItemRenderer(
          musicResponsiveListItemRenderer,
          thumbnails: thumbnails);
    } else if (musicTwoRowItemRenderer != null) {
      result = handleMusicTwoRowItemRenderer(musicTwoRowItemRenderer,
          thumbnails: thumbnails);
    } else if (musicMultiRowListItemRenderer != null) {
      result =
          handleMusicMultiRowListItemRenderer(musicMultiRowListItemRenderer);
    } else if (playlistPanelVideoRenderer != null) {
      result = handlePlaylistPanelVideoRenderer(playlistPanelVideoRenderer);
    }
    if (result['thumbnails'] == null) continue;
    contentsResult.add(result);
  }
  return contentsResult;
}

Map<String, dynamic> checkRuns(List? runs) {
  if (runs == null) return {};
  Map<String, dynamic> runResult = {'artists': []};
  for (Map run in runs) {
    String? pageType = nav(run, [
          'navigationEndpoint',
          'browseEndpoint',
          'browseEndpointContextSupportedConfigs',
          'browseEndpointContextMusicConfig',
          'pageType'
        ]) ??
        nav(run, [
          'navigationEndpoint',
          'watchEndpoint',
          'watchEndpointMusicSupportedConfigs',
          'watchEndpointMusicConfig',
          'musicVideoType'
        ]) ??
        nav(run, ['menuServiceItemRenderer', 'icon', 'iconType']);
    if (pageType == 'MUSIC_PAGE_TYPE_ARTIST') {
      runResult['artists'].add({
        'name': nav(run, ['text']),
        'endpoint': nav(run, ['navigationEndpoint', 'browseEndpoint'])
      });
    } else if (pageType == 'MUSIC_PAGE_TYPE_ALBUM') {
      runResult['album'] = {
        'name': nav(run, ['text']),
        'endpoint': nav(run, ['navigationEndpoint', 'browseEndpoint'])
      };
    } else if (pageType == 'MUSIC_VIDEO_TYPE_OMV' ||
        pageType == 'MUSIC_VIDEO_TYPE_ATV') {
      runResult['title'] ??= run['text'];
      runResult['videoId'] ??=
          nav(run, ['navigationEndpoint', 'watchEndpoint', 'videoId']);
    } else if (pageType == 'QUEUE_PLAY_NEXT') {
      runResult['videoId'] ??= nav(run, [
        'menuServiceItemRenderer',
        'serviceEndpoint',
        'queueAddEndpoint',
        'queueTarget',
        'videoId'
      ]);
    }
    if (nav(run, ['menuNavigationItemRenderer', 'icon', 'iconType']) ==
        'MUSIC_SHUFFLE') {
      runResult['playlistId'] ??= nav(run, [
        'menuNavigationItemRenderer',
        'navigationEndpoint',
        'watchPlaylistEndpoint',
        'playlistId'
      ]);
    } else if (nav(run, ['menuNavigationItemRenderer', 'icon', 'iconType']) ==
        'MIX') {
      runResult['playlistRadioId'] ??= nav(run, [
        'menuNavigationItemRenderer',
        'navigationEndpoint',
        'watchPlaylistEndpoint',
        'playlistId'
      ])?.replaceAll('RDAMPL', '');
    } else if (nav(run, [
          'toggleMenuServiceItemRenderer',
          'toggledServiceEndpoint',
          'likeEndpoint',
          'target',
          'playlistId'
        ]) !=
        null) {
      runResult['playlistId'] ??= nav(run, [
        'toggleMenuServiceItemRenderer',
        'toggledServiceEndpoint',
        'likeEndpoint',
        'target',
        'playlistId'
      ])?.replaceAll('RDAMPL', '');
    }
    if (nav(run, ['menuServiceItemRenderer', 'icon', 'iconType']) ==
        'REMOVE_FROM_HISTORY') {
      runResult['feedbackToken'] = nav(run, [
        'menuServiceItemRenderer',
        'serviceEndpoint',
        'feedbackEndpoint',
        'feedbackToken'
      ]);
    }
  }
  runResult.removeWhere((key, val) => val == null || val.isEmpty);
  return runResult;
}

Map itemCategory = {
  'MUSIC_PAGE_TYPE_ARTIST': 'ARTIST',
  'MUSIC_PAGE_TYPE_LIBRARY_ARTIST': 'ARTIST',
  'MUSIC_VIDEO_TYPE_OMV': 'VIDEO',
  'MUSIC_VIDEO_TYPE_UGC': 'VIDEO',
  'MUSIC_PAGE_TYPE_ALBUM': 'ALBUM',
  'MUSIC_VIDEO_TYPE_ATV': 'SONG',
  'MUSIC_PAGE_TYPE_PLAYLIST': 'PLAYLIST',
  'MUSIC_PAGE_TYPE_NON_MUSIC_AUDIO_TRACK_PAGE': 'EPISODE',
  'MUSIC_PAGE_TYPE_USER_CHANNEL': 'PROFILE'
};

Map<String, dynamic> handleMusicShelfRenderer(Map item, {List? thumbnails}) {
  List? contents = nav(item, ['contents']);
  Map<String, dynamic> section = {
    'title': nav(item, ['title', 'runs', 0, 'text']),
    'contents': [],
  };
  if (nav(item, ['bottomEndpoint', 'searchEndpoint']) != null) {
    section['trailing'] = {
      'text': nav(item, ['bottomText', 'runs', 0, 'text']),
      'endpoint': nav(item, ['bottomEndpoint', 'searchEndpoint'])
    };
  }
  if (contents != null) {
    section['contents']
        .addAll(handleContents(contents, thumbnails: thumbnails));
  }
  return section;
}

Map<String, dynamic> handleGridRenderer(Map item) {
  List? contents = nav(item, ['items']);
  Map<String, dynamic> section = {
    'title': nav(item, ['title', 'runs', 0, 'text']),
    'contents': [],
    'viewType': 'SINGLE_COLUMN',
  };
  if (contents != null) {
    section['contents'].addAll(handleContents(contents));
  }
  return section;
}

Map<String, dynamic> handleContinuationContents(Map item) {
  Map<String, dynamic> section = {
    'title': null,
    'contents': [],
    'viewType': 'COLUMN',
  };
  List? contents = nav(item, ['contents']);
  if (contents != null) {
    section['contents'].addAll(handleContents(contents));
  }
  return section;
}

Map<String, dynamic> handleMusicPlaylistShelfRenderer(Map item) {
  Map<String, dynamic> section = {'contents': []};
  if (nav(item, ['playlistId']) != null) {
    section['playlistId'] = nav(item, ['playlistId']);
    section['viewType'] = 'COLUMN';
  }
  String? cont =
      nav(item, ['continuations', 0, 'nextContinuationData', 'continuation']);
  String? continuationparams =
      cont != null ? getContinuationString(cont) : null;
  section['continuation'] = continuationparams;

  List? contents = nav(item, ['contents']);
  if (contents != null) {
    section['contents'].addAll(handleContents(contents));
  }
  return section;
}

Map<String, dynamic> handleMusicResponsiveListItemRenderer(Map item,
    {List? thumbnails}) {
  List flexColumns = nav(item, ['flexColumns']);

  List allRuns = flexColumns
      .map((column) => nav(column,
          ['musicResponsiveListItemFlexColumnRenderer', 'text', 'runs']))
      .toList();
  allRuns.removeWhere((element) => element == null);
  allRuns = allRuns.expand((x) => x).toList();

  Map firstRun = allRuns[0];
  Map<String, dynamic> itemresult = {
    'thumbnails': nav(item, [
          'thumbnail',
          'musicThumbnailRenderer',
          'thumbnail',
          'thumbnails'
        ]) ??
        thumbnails,
    'explicit': nav(item,
            ['badges', 0, 'musicInlineBadgeRenderer', 'icon', 'iconType']) ==
        'MUSIC_EXPLICIT_BADGE',
    'title': nav(firstRun, ['text']),
    'subtitle': nav(flexColumns.last, [
      'musicResponsiveListItemFlexColumnRenderer',
      'text',
      'runs'
    ])?.map((el) => el['text']).join(''),
    'endpoint': nav(firstRun, ['navigationEndpoint', 'browseEndpoint']) ??
        nav(item, ['navigationEndpoint', 'browseEndpoint']),
    'videoId':
        nav(firstRun, ['navigationEndpoint', 'watchEndpoint', 'videoId']) ??
            nav(item, ['playlistItemData', 'videoId']),
    'type': itemCategory[nav(firstRun, [
          'navigationEndpoint',
          'watchEndpoint',
          'watchEndpointMusicSupportedConfigs',
          'watchEndpointMusicConfig',
          'musicVideoType'
        ]) ??
        nav(firstRun, [
          'navigationEndpoint',
          'browseEndpoint',
          'browseEndpointContextSupportedConfigs',
          'browseEndpointContextMusicConfig',
          'pageType'
        ]) ??
        nav(item, [
          'navigationEndpoint',
          'browseEndpoint',
          'browseEndpointContextSupportedConfigs',
          'browseEndpointContextMusicConfig',
          'pageType'
        ])],
    ...checkRuns(allRuns),
    ...checkRuns(nav(item, ['menu', 'menuRenderer', 'items']))
  };

  itemresult.removeWhere((key, val) => val == null || val.toString().isEmpty);
  return itemresult;
}

Map handleMusicTwoRowItemRenderer(Map item, {List? thumbnails}) {
  Map itemresult = {
    'title': nav(item, ['title', 'runs', 0, 'text']),
    'thumbnails': nav(item, [
          'thumbnailRenderer',
          'musicThumbnailRenderer',
          'thumbnail',
          'thumbnails'
        ]) ??
        thumbnails,
    'explicit': nav(item, [
          'subtitleBadges',
          0,
          'musicInlineBadgeRenderer',
          'icon',
          'iconType'
        ]) ==
        'MUSIC_EXPLICIT_BADGE',
    'subtitle':
        nav(item, ['subtitle', 'runs'])?.map((el) => el['text']).join(''),
    'aspectRatio': nav(item, ['aspectRatio']) ==
            'MUSIC_TWO_ROW_ITEM_THUMBNAIL_ASPECT_RATIO_RECTANGLE_16_9'
        ? 16 / 9
        : 1 / 1,
    'endpoint': nav(item,
            ['title', 'runs', 0, 'navigationEndpoint', 'browseEndpoint']) ??
        nav(item, ['navigationEndpoint', 'browseEndpoint']),
    'videoId': nav(item, ['navigationEndpoint', 'watchEndpoint', 'videoId']),
    'type': itemCategory[nav(item, [
          'title',
          'runs',
          0,
          'navigationEndpoint',
          'watchEndpoint',
          'watchEndpointMusicSupportedConfigs',
          'watchEndpointMusicConfig',
          'musicVideoType'
        ]) ??
        nav(item, [
          'title',
          'runs',
          0,
          'navigationEndpoint',
          'browseEndpoint',
          'browseEndpointContextSupportedConfigs',
          'browseEndpointContextMusicConfig',
          'pageType'
        ]) ??
        nav(item, [
          'navigationEndpoint',
          'browseEndpoint',
          'browseEndpointContextSupportedConfigs',
          'browseEndpointContextMusicConfig',
          'pageType'
        ]) ??
        nav(item, [
          'navigationEndpoint',
          'watchEndpoint',
          'watchEndpointMusicSupportedConfigs',
          'watchEndpointMusicConfig',
          'musicVideoType'
        ])],
    'description': nav(item, ['runs', 0, 'text']),
    ...checkRuns(nav(item, ['subtitle', 'runs'])),
    ...checkRuns(nav(item, ['menu', 'menuRenderer', 'items']))
  };
  itemresult.removeWhere((key, val) => val == null || val.toString().isEmpty);
  return itemresult;
}

Map handlePlaylistPanelVideoRenderer(Map item) {
  Map itemresult = {
    'title': nav(item, ['title', 'runs', 0, 'text']),
    'thumbnails': nav(item, ['thumbnail', 'thumbnails']),
    'explicit': nav(item, [
          'subtitleBadges',
          0,
          'musicInlineBadgeRenderer',
          'icon',
          'iconType'
        ]) ==
        'MUSIC_EXPLICIT_BADGE',
    'subtitle':
        nav(item, ['longBylineText', 'runs'])?.map((el) => el['text']).join(''),
    'aspectRatio': nav(item, ['aspectRatio']) ==
            'MUSIC_TWO_ROW_ITEM_THUMBNAIL_ASPECT_RATIO_RECTANGLE_16_9'
        ? 16 / 9
        : 1 / 1,
    'endpoint': nav(item,
            ['title', 'runs', 0, 'navigationEndpoint', 'browseEndpoint']) ??
        nav(item, ['navigationEndpoint', 'browseEndpoint']),
    'videoId': nav(item, ['videoId']) ??
        nav(item, ['navigationEndpoint', 'watchEndpoint', 'videoId']),
    'playlistId':
        nav(item, ['navigationEndpoint', 'watchEndpoint', 'playlistId']),
    'type': itemCategory[nav(item, [
          'title',
          'runs',
          0,
          'navigationEndpoint',
          'watchEndpoint',
          'watchEndpointMusicSupportedConfigs',
          'watchEndpointMusicConfig',
          'musicVideoType'
        ]) ??
        nav(item, [
          'title',
          'runs',
          0,
          'navigationEndpoint',
          'browseEndpoint',
          'browseEndpointContextSupportedConfigs',
          'browseEndpointContextMusicConfig',
          'pageType'
        ]) ??
        nav(item, [
          'navigationEndpoint',
          'browseEndpoint',
          'browseEndpointContextSupportedConfigs',
          'browseEndpointContextMusicConfig',
          'pageType'
        ]) ??
        nav(item, [
          'navigationEndpoint',
          'watchEndpoint',
          'watchEndpointMusicSupportedConfigs',
          'watchEndpointMusicConfig',
          'musicVideoType'
        ])],
    'description': nav(item, ['runs', 0, 'text']),
    ...checkRuns(nav(item, ['longBylineText', 'runs'])),
    ...checkRuns(nav(item, ['menu', 'menuRenderer', 'items']))
  };
  itemresult.removeWhere((key, val) => val == null || val.toString().isEmpty);
  return itemresult;
}

Map handleMusicMultiRowListItemRenderer(Map item) {
  Map itemresult = {
    'title': nav(item, ['title', 'runs', 0, 'text']),
    'type': itemCategory[nav(item, [
          'title',
          'runs',
          0,
          'navigationEndpoint',
          'browseEndpoint',
          'browseEndpointContextSupportedConfigs',
          'browseEndpointContextMusicConfig',
          'pageType'
        ]) ??
        nav(item, [
          'navigationEndpoint',
          'browseEndpoint',
          'browseEndpointContextSupportedConfigs',
          'browseEndpointContextMusicConfig',
          'pageType'
        ])],
    'description': nav(item, ['description', 'runs', 0, 'text']),
    'thumbnails': nav(item,
        ['thumbnail', 'musicThumbnailRenderer', 'thumbnail', 'thumbnails']),
    'subtitle':
        nav(item, ['subtitle', 'runs'])?.map((el) => el['text']).join(''),
    'videoId': nav(item, ['onTap', 'watchEndpoint', 'videoId']),
    'playlistId': nav(item, ['onTap', 'watchEndpoint', 'playlistId']),
    'endpoint': nav(item,
            ['title', 'runs', 0, 'navigationEndpoint', 'browseEndpoint']) ??
        nav(item, ['navigationEndpoint', 'browseEndpoint']),
    'aspectRatio': 16 / 9,
    ...checkRuns(nav(item, ['subtitle', 'runs'])),
  };

  itemresult.removeWhere((key, val) => val == null || val.toString().isEmpty);
  return itemresult;
}
