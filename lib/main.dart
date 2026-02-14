import 'dart:io';

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get_it/get_it.dart';
import 'package:gyawun/themes/theme.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';
import 'package:m3e_collection/m3e_collection.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:yt_music/client.dart';
import 'package:yt_music/modals/yt_config.dart';
import 'package:yt_music/ytmusic.dart';

import 'generated/l10n.dart';
import 'services/download_manager.dart';
import 'services/favourites_manager.dart';
import 'services/file_storage.dart';
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

  SettingsManager settingsManager = await SettingsManager.create();
  GetIt.I.registerSingleton<SettingsManager>(settingsManager);

  final ytConfig = await getYtConfig(settingsManager);
  YTMusic ytMusic = YTMusic(config: ytConfig!);
  GetIt.I.registerSingleton<YTMusic>(ytMusic);

  final GlobalKey<NavigatorState> panelKey = GlobalKey<NavigatorState>();
  GetIt.I.registerSingleton(panelKey);

  await FileStorage.initialise();
  FileStorage fileStorage = FileStorage();
  GetIt.I.registerSingleton<FileStorage>(fileStorage);

  MediaPlayer mediaPlayer = MediaPlayer();
  GetIt.I.registerSingleton<MediaPlayer>(mediaPlayer);

  LibraryService libraryService = LibraryService();
  GetIt.I.registerSingleton<LibraryService>(libraryService);

  DownloadManager downloadManager = await DownloadManager.create();
  GetIt.I.registerSingleton<DownloadManager>(downloadManager);

  GetIt.I.registerSingleton<Lyrics>(Lyrics());

  FavouritesManager favouritesManager = await FavouritesManager.create();
  GetIt.I.registerSingleton<FavouritesManager>(favouritesManager);

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
    final settings = context.select(
      (SettingsManager s) => (
        language: s.language['value']!,
        themeMode: s.themeMode,
        dynamicColors: s.dynamicColors,
        accentColor: s.accentColor,
        amoledBlack: s.amoledBlack,
      ),
    );
    return DynamicColorBuilder(
      builder: (lightScheme, darkScheme) {
        final primaryColor =
            (settings.dynamicColors && darkScheme != null
                ? darkScheme.primary
                : settings.accentColor) ??
            Colors.red;
        final isPureBlack = settings.amoledBlack;
        return Shortcuts(
          shortcuts: <LogicalKeySet, Intent>{
            LogicalKeySet(LogicalKeyboardKey.select): const ActivateIntent(),
          },
          child: MaterialApp.router(
            title: 'Gyawun Music',
            routerConfig: router,
            locale: Locale(settings.language),
            localizationsDelegates: const [
              S.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: S.delegate.supportedLocales,
            debugShowCheckedModeBanner: false,
            themeMode: settings.themeMode,
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
  await Hive.openBox('LIBRARY');
  await Hive.openBox('SEARCH_HISTORY');
  await Hive.openBox('SONG_HISTORY');
}

Future<YTConfig?>? getYtConfig(SettingsManager settingsManager) async {
  final visitorId = settingsManager.visitorId;
  final apiKey = settingsManager.apiKey;
  final clientName = settingsManager.clientName;
  final clientVersion = settingsManager.clientVersion;
  if (visitorId == null ||
      apiKey == null ||
      clientName == null ||
      clientVersion == null) {
    final config = await YTClient.getConfig();
    settingsManager.visitorId = visitorId ?? config?.visitorData;
    settingsManager.apiKey = apiKey ?? config?.apiKey;
    settingsManager.clientName = clientName ?? config?.clientName;
    settingsManager.clientVersion = clientVersion ?? config?.clientVersion;
    return config;
  } else {
    return YTConfig(
      visitorData: visitorId,
      language: settingsManager.language['value']!,
      location: settingsManager.location['value']!,
      apiKey: apiKey,
      clientName: clientName,
      clientVersion: clientVersion,
    );
  }
}
