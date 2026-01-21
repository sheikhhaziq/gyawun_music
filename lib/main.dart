import 'dart:io';

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get_it/get_it.dart';
import 'package:gyawun/services/backup_service/backup_service.dart';
import 'package:gyawun/services/directory_service/directory_service.dart';
import 'package:gyawun/themes/theme.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';
import 'package:m3e_collection/m3e_collection.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:saf_stream/saf_stream.dart';
import 'package:saf_util/saf_util.dart';
import 'package:yt_music/client.dart';
import 'package:yt_music/modals/yt_config.dart';
import 'package:yt_music/ytmusic.dart';

import 'generated/l10n.dart';
import 'services/download_manager.dart';
import 'services/library.dart';
import 'services/lyrics.dart';
import 'services/media_player.dart';
import 'services/settings_manager.dart';
import 'utils/router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isAndroid) {
    await JustAudioBackground.init(
      androidNotificationChannelId: 'com.jhelum.gyawun.audio',
      androidNotificationChannelName: 'Audio playback',
      androidNotificationOngoing: true,
      // androidStopForegroundOnPause: false,
    );
  }

  if (Platform.isWindows || Platform.isLinux) {
    JustAudioMediaKit.ensureInitialized();
    JustAudioMediaKit.bufferSize = 8 * 1024 * 1024;
    JustAudioMediaKit.title = 'Gyawun Music';
    JustAudioMediaKit.prefetchPlaylist = true;
    JustAudioMediaKit.pitch = true;
  }
  await initialiseHive();
  await SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
    overlays: [SystemUiOverlay.top],
  );

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  final ytConfig = await getYtConfig();
  YTMusic ytMusic = YTMusic(config: ytConfig!);

  final GlobalKey<NavigatorState> panelKey = GlobalKey<NavigatorState>();
  final safutil = SafUtil();
  final safStream = SafStream();
  DirectoryService directoryService = DirectoryService(
    safStream: safStream,
    safUtil: safutil,
  );

  GetIt.I.registerSingleton<DirectoryService>(directoryService);

  SettingsManager settingsManager = SettingsManager();

  GetIt.I.registerSingleton<SettingsManager>(settingsManager);

  MediaPlayer mediaPlayer = MediaPlayer();
  GetIt.I.registerSingleton<MediaPlayer>(mediaPlayer);
  LibraryService libraryService = LibraryService();
  GetIt.I.registerSingleton<DownloadManager>(DownloadManager(directoryService));
  GetIt.I.registerSingleton(panelKey);
  GetIt.I.registerSingleton<YTMusic>(ytMusic);

  GetIt.I.registerSingleton<LibraryService>(libraryService);
  GetIt.I.registerSingleton<Lyrics>(Lyrics());

  GetIt.I.registerSingleton<BackupService>(
    BackupService(directoryService, settingsManager, libraryService),
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => settingsManager),
        ChangeNotifierProvider(create: (_) => mediaPlayer),
        ChangeNotifierProvider(create: (_) => libraryService),
      ],
      child: const Gyawun(),
    ),
  );
}

class Gyawun extends StatelessWidget {
  const Gyawun({super.key});
  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (lightScheme, darkScheme) {
        final primaryColor =
            (context.watch<SettingsManager>().dynamicColors &&
                    darkScheme != null
                ? darkScheme.primary
                : context.watch<SettingsManager>().accentColor) ??
            Colors.red;
        final isPureBlack = context.watch<SettingsManager>().amoledBlack;
        return Shortcuts(
          shortcuts: <LogicalKeySet, Intent>{
            LogicalKeySet(LogicalKeyboardKey.select): const ActivateIntent(),
          },
          child: MaterialApp.router(
            title: 'Gyawun Music',
            routerConfig: router,
            locale: Locale(context.watch<SettingsManager>().language['value']!),
            localizationsDelegates: const [
              S.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: S.delegate.supportedLocales,
            debugShowCheckedModeBanner: false,
            themeMode: context.watch<SettingsManager>().themeMode,
            theme: ColorScheme.fromSeed(
              seedColor: primaryColor,
            ).toM3EThemeData(base: AppTheme.light(primary: primaryColor)),
            darkTheme:
                ColorScheme.fromSeed(
                  brightness: Brightness.dark,
                  surface: isPureBlack ? Colors.black : null,
                  seedColor: primaryColor,
                ).toM3EThemeData(
                  base: AppTheme.dark(
                    primary: primaryColor,
                    isPureBlack: isPureBlack,
                  ),
                ),
          ),
        );
      },
    );
  }
}

Future<void> initialiseHive() async {
  String? applicationDataDirectoryPath;
  if (Platform.isWindows || Platform.isLinux) {
    applicationDataDirectoryPath =
        "${(await getApplicationSupportDirectory()).path}/database";
  }
  await Hive.initFlutter(applicationDataDirectoryPath);
  await Hive.openBox('SETTINGS');
  await Hive.openBox('LIBRARY');
  await Hive.openBox('SEARCH_HISTORY');
  await Hive.openBox('SONG_HISTORY');
  await Hive.openBox('FAVOURITES');
  await Hive.openBox('DOWNLOADS');
}

Future<YTConfig?>? getYtConfig() async {
  String? visitorData = await Hive.box('SETTINGS').get('VISITOR_ID');
  String language = await Hive.box(
    'SETTINGS',
  ).get('YT_LANGUAGE', defaultValue: 'en');
  String location = await Hive.box(
    'SETTINGS',
  ).get('YT_LOCATION', defaultValue: 'IN');
  String? apikey = await Hive.box(
    'SETTINGS',
  ).get('YT_API_KEY', defaultValue: null);
  String clientName = await Hive.box(
    'SETTINGS',
  ).get('YT_CLIENT_NAME', defaultValue: 'WEB_REMIX');
  String? clientVersion = await Hive.box(
    'SETTINGS',
  ).get('YT_CLIENT_VERSION', defaultValue: null);

  if (visitorData == null || apikey == null || clientVersion == null) {
    final config = await YTClient.getConfig();
    final box = Hive.box('SETTINGS');
    await box.putAll({
      'VISITOR_ID': visitorData ?? config?.visitorData,
      'YT_LOCATION': location,
      'YT_LANGUAGE': language,
      'YT_API_KEY': config?.apiKey,
      'YT_CLIENT_NAME': config?.clientName,
      'YT_CLIENT_VERSION': config?.clientVersion,
    });
    return config;
  } else {
    return YTConfig(
      visitorData: visitorData,
      language: language,
      location: location,
      apiKey: apikey,
      clientName: clientName,
      clientVersion: clientVersion,
    );
  }
}
