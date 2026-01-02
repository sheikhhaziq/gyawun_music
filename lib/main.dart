import 'dart:io';

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get_it/get_it.dart';
import 'package:gyawun/themes/theme.dart';
import 'package:gyawun/ytmusic/modals/yt_config.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import 'generated/l10n.dart';
import 'services/download_manager.dart';
import 'services/file_storage.dart';
import 'services/library.dart';
import 'services/lyrics.dart';
import 'services/media_player.dart';
import 'services/settings_manager.dart';
import 'utils/router.dart';
import 'ytmusic/ytmusic.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isAndroid) {
    await JustAudioBackground.init(
      androidNotificationChannelId: 'com.jhelum.gyawun.audio',
      androidNotificationChannelName: 'Audio playback',
      androidShowNotificationBadge: true,
      androidStopForegroundOnPause: false,
    );
  }
  await initialiseHive();
  if (Platform.isWindows || Platform.isLinux) {
    JustAudioMediaKit.ensureInitialized();
    JustAudioMediaKit.bufferSize = 8 * 1024 * 1024;
    JustAudioMediaKit.title = 'Gyawun Music';
    JustAudioMediaKit.prefetchPlaylist = true;
    JustAudioMediaKit.pitch = true;
  }
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
  String? visitorId = await Hive.box('SETTINGS').get('VISITOR_ID');

  YTMusic ytMusic = YTMusic(
    config:
        YTConfig(visitorData: visitorId ?? '', language: 'en', location: 'IN'),
    onIdUpdate: (visitorId) async {
      await Hive.box('SETTINGS').put('VISITOR_ID', visitorId);
    },
  );

  final GlobalKey<NavigatorState> panelKey = GlobalKey<NavigatorState>();

  await FileStorage.initialise();
  FileStorage fileStorage = FileStorage();
  SettingsManager settingsManager = SettingsManager();

  GetIt.I.registerSingleton<SettingsManager>(settingsManager);
  MediaPlayer mediaPlayer = MediaPlayer();
  GetIt.I.registerSingleton<MediaPlayer>(mediaPlayer);
  LibraryService libraryService = LibraryService();
  GetIt.I.registerSingleton<DownloadManager>(DownloadManager());
  GetIt.I.registerSingleton(panelKey);
  GetIt.I.registerSingleton<YTMusic>(ytMusic);

  GetIt.I.registerSingleton<FileStorage>(fileStorage);

  GetIt.I.registerSingleton<LibraryService>(libraryService);
  GetIt.I.registerSingleton<Lyrics>(Lyrics());

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
    return DynamicColorBuilder(builder: (lightScheme, darkScheme) {
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
          theme: AppTheme.light(
            primary: context.watch<SettingsManager>().dynamicColors &&
                    lightScheme != null
                ? lightScheme.primary
                : context.watch<SettingsManager>().accentColor,
          ),
          darkTheme: AppTheme.dark(
            primary: context.watch<SettingsManager>().dynamicColors &&
                    darkScheme != null
                ? darkScheme.primary
                : context.watch<SettingsManager>().accentColor,
            isPureBlack: context.watch<SettingsManager>().amoledBlack,
          ),
        ),
      );
    });
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
