// GENERATED CODE - DO NOT MODIFY BY HAND
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'intl/messages_all.dart';

// **************************************************************************
// Generator: Flutter Intl IDE plugin
// Made by Localizely
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, lines_longer_than_80_chars
// ignore_for_file: join_return_with_assignment, prefer_final_in_for_each
// ignore_for_file: avoid_redundant_argument_values, avoid_escaping_inner_quotes

class S {
  S();

  static S? _current;

  static S get current {
    assert(
      _current != null,
      'No instance of S was loaded. Try to initialize the S delegate before accessing S.current.',
    );
    return _current!;
  }

  static const AppLocalizationDelegate delegate = AppLocalizationDelegate();

  static Future<S> load(Locale locale) {
    final name = (locale.countryCode?.isEmpty ?? false)
        ? locale.languageCode
        : locale.toString();
    final localeName = Intl.canonicalizedLocale(name);
    return initializeMessages(localeName).then((_) {
      Intl.defaultLocale = localeName;
      final instance = S();
      S._current = instance;

      return instance;
    });
  }

  static S of(BuildContext context) {
    final instance = S.maybeOf(context);
    assert(
      instance != null,
      'No instance of S present in the widget tree. Did you add S.delegate in localizationsDelegates?',
    );
    return instance!;
  }

  static S? maybeOf(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  /// `Gyawun`
  String get Gyawun {
    return Intl.message('Gyawun', name: 'Gyawun', desc: '', args: []);
  }

  /// `Next Up`
  String get Next_Up {
    return Intl.message('Next Up', name: 'Next_Up', desc: '', args: []);
  }

  /// `Shuffle`
  String get Shuffle {
    return Intl.message('Shuffle', name: 'Shuffle', desc: '', args: []);
  }

  /// `Home`
  String get Home {
    return Intl.message('Home', name: 'Home', desc: '', args: []);
  }

  /// `Saved`
  String get Saved {
    return Intl.message('Saved', name: 'Saved', desc: '', args: []);
  }

  /// `YTMusic`
  String get YTMusic {
    return Intl.message('YTMusic', name: 'YTMusic', desc: '', args: []);
  }

  /// `Settings`
  String get Settings {
    return Intl.message('Settings', name: 'Settings', desc: '', args: []);
  }

  /// `Search Gyawun`
  String get Search_Gyawun {
    return Intl.message(
      'Search Gyawun',
      name: 'Search_Gyawun',
      desc: '',
      args: [],
    );
  }

  /// `Favourites`
  String get Favourites {
    return Intl.message('Favourites', name: 'Favourites', desc: '', args: []);
  }

  /// `Downloads`
  String get Downloads {
    return Intl.message('Downloads', name: 'Downloads', desc: '', args: []);
  }

  /// `History`
  String get History {
    return Intl.message('History', name: 'History', desc: '', args: []);
  }

  /// `{count, plural, =0{No Songs} =1{1 Song} other{{count} Songs}}`
  String nSongs(num count) {
    return Intl.plural(
      count,
      zero: 'No Songs',
      one: '1 Song',
      other: '$count Songs',
      name: 'nSongs',
      desc: 'Number of songs',
      args: [count],
    );
  }

  /// `Songs`
  String get Songs {
    return Intl.message('Songs', name: 'Songs', desc: '', args: []);
  }

  /// `Albums`
  String get Albums {
    return Intl.message('Albums', name: 'Albums', desc: '', args: []);
  }

  /// `Playlists`
  String get Playlists {
    return Intl.message('Playlists', name: 'Playlists', desc: '', args: []);
  }

  /// `Artists`
  String get Artists {
    return Intl.message('Artists', name: 'Artists', desc: '', args: []);
  }

  /// `Subscriptions`
  String get Subscriptions {
    return Intl.message(
      'Subscriptions',
      name: 'Subscriptions',
      desc: '',
      args: [],
    );
  }

  /// `Search Settings`
  String get Search_Settings {
    return Intl.message(
      'Search Settings',
      name: 'Search_Settings',
      desc: '',
      args: [],
    );
  }

  /// `Battery Optimisation Detected`
  String get Battery_Optimisation_title {
    return Intl.message(
      'Battery Optimisation Detected',
      name: 'Battery_Optimisation_title',
      desc: '',
      args: [],
    );
  }

  /// `Click here disable battery optimisation for Gyawun to work properly`
  String get Battery_Optimisation_message {
    return Intl.message(
      'Click here disable battery optimisation for Gyawun to work properly',
      name: 'Battery_Optimisation_message',
      desc: '',
      args: [],
    );
  }

  /// `Donate`
  String get Donate {
    return Intl.message('Donate', name: 'Donate', desc: '', args: []);
  }

  /// `Support the development of Gyawun`
  String get Donate_Message {
    return Intl.message(
      'Support the development of Gyawun',
      name: 'Donate_Message',
      desc: '',
      args: [],
    );
  }

  /// `Payment Methods`
  String get Payment_Methods {
    return Intl.message(
      'Payment Methods',
      name: 'Payment_Methods',
      desc: '',
      args: [],
    );
  }

  /// `Pay with UPI`
  String get Pay_With_UPI {
    return Intl.message(
      'Pay with UPI',
      name: 'Pay_With_UPI',
      desc: '',
      args: [],
    );
  }

  /// `Support me on Ko-fi`
  String get Support_Me_On_Kofi {
    return Intl.message(
      'Support me on Ko-fi',
      name: 'Support_Me_On_Kofi',
      desc: '',
      args: [],
    );
  }

  /// `Buy me a Coffee`
  String get Buy_Me_A_Coffee {
    return Intl.message(
      'Buy me a Coffee',
      name: 'Buy_Me_A_Coffee',
      desc: '',
      args: [],
    );
  }

  /// `Google Account`
  String get Google_Account {
    return Intl.message(
      'Google Account',
      name: 'Google_Account',
      desc: '',
      args: [],
    );
  }

  /// `Appearence`
  String get Appearence {
    return Intl.message('Appearence', name: 'Appearence', desc: '', args: []);
  }

  /// `Theme Mode`
  String get Theme_Mode {
    return Intl.message('Theme Mode', name: 'Theme_Mode', desc: '', args: []);
  }

  /// `Window Effect`
  String get Window_Effect {
    return Intl.message(
      'Window Effect',
      name: 'Window_Effect',
      desc: '',
      args: [],
    );
  }

  /// `Dynamic Colors`
  String get Dynamic_Colors {
    return Intl.message(
      'Dynamic Colors',
      name: 'Dynamic_Colors',
      desc: '',
      args: [],
    );
  }

  /// `Content`
  String get Content {
    return Intl.message('Content', name: 'Content', desc: '', args: []);
  }

  /// `Country`
  String get Country {
    return Intl.message('Country', name: 'Country', desc: '', args: []);
  }

  /// `Language`
  String get Language {
    return Intl.message('Language', name: 'Language', desc: '', args: []);
  }

  /// `Translate Lyrics`
  String get Translate_Lyrics {
    return Intl.message(
      'Translate Lyrics',
      name: 'Translate_Lyrics',
      desc: '',
      args: [],
    );
  }

  /// `Autoplay Similar Songs`
  String get Autofetch_Songs {
    return Intl.message(
      'Autoplay Similar Songs',
      name: 'Autofetch_Songs',
      desc: '',
      args: [],
    );
  }

  /// `Personalised Content`
  String get Personalised_Content {
    return Intl.message(
      'Personalised Content',
      name: 'Personalised_Content',
      desc: '',
      args: [],
    );
  }

  /// `Enter Visitor Id`
  String get Enter_Visitor_Id {
    return Intl.message(
      'Enter Visitor Id',
      name: 'Enter_Visitor_Id',
      desc: '',
      args: [],
    );
  }

  /// `Visitor Id`
  String get Visitor_Id {
    return Intl.message('Visitor Id', name: 'Visitor_Id', desc: '', args: []);
  }

  /// `Reset Visitor Id`
  String get Reset_Visitor_Id {
    return Intl.message(
      'Reset Visitor Id',
      name: 'Reset_Visitor_Id',
      desc: '',
      args: [],
    );
  }

  /// `Audio and Playback`
  String get Audio_And_Playback {
    return Intl.message(
      'Audio and Playback',
      name: 'Audio_And_Playback',
      desc: '',
      args: [],
    );
  }

  /// `Loudness And Equalizer`
  String get Loudness_And_Equalizer {
    return Intl.message(
      'Loudness And Equalizer',
      name: 'Loudness_And_Equalizer',
      desc: '',
      args: [],
    );
  }

  /// `Loudness Enhancer`
  String get Loudness_Enhancer {
    return Intl.message(
      'Loudness Enhancer',
      name: 'Loudness_Enhancer',
      desc: '',
      args: [],
    );
  }

  /// `Enable Equalizer`
  String get Enable_Equalizer {
    return Intl.message(
      'Enable Equalizer',
      name: 'Enable_Equalizer',
      desc: '',
      args: [],
    );
  }

  /// `Streaming Quality`
  String get Streaming_Quality {
    return Intl.message(
      'Streaming Quality',
      name: 'Streaming_Quality',
      desc: '',
      args: [],
    );
  }

  /// `Download Quality`
  String get DOwnload_Quality {
    return Intl.message(
      'Download Quality',
      name: 'DOwnload_Quality',
      desc: '',
      args: [],
    );
  }

  /// `App Folder`
  String get App_Folder {
    return Intl.message('App Folder', name: 'App_Folder', desc: '', args: []);
  }

  /// `Skip Silence`
  String get Skip_Silence {
    return Intl.message(
      'Skip Silence',
      name: 'Skip_Silence',
      desc: '',
      args: [],
    );
  }

  /// `Enable Playback History`
  String get Enable_Playback_History {
    return Intl.message(
      'Enable Playback History',
      name: 'Enable_Playback_History',
      desc: '',
      args: [],
    );
  }

  /// `Delete Playback History`
  String get Delete_Playback_History {
    return Intl.message(
      'Delete Playback History',
      name: 'Delete_Playback_History',
      desc: '',
      args: [],
    );
  }

  /// `Are you sure you want to delete Playback History.`
  String get Delete_Playback_History_Confirm_Message {
    return Intl.message(
      'Are you sure you want to delete Playback History.',
      name: 'Delete_Playback_History_Confirm_Message',
      desc: '',
      args: [],
    );
  }

  /// `Playback History Deleted`
  String get Playback_History_Deleted {
    return Intl.message(
      'Playback History Deleted',
      name: 'Playback_History_Deleted',
      desc: '',
      args: [],
    );
  }

  /// `Enable Search History`
  String get Enable_Search_History {
    return Intl.message(
      'Enable Search History',
      name: 'Enable_Search_History',
      desc: '',
      args: [],
    );
  }

  /// `Delete Search History`
  String get Delete_Search_History {
    return Intl.message(
      'Delete Search History',
      name: 'Delete_Search_History',
      desc: '',
      args: [],
    );
  }

  /// `Are you sure you want to delete Search History.`
  String get Delete_Search_History_Confirm_Message {
    return Intl.message(
      'Are you sure you want to delete Search History.',
      name: 'Delete_Search_History_Confirm_Message',
      desc: '',
      args: [],
    );
  }

  /// `Search History Deleted`
  String get Search_History_Deleted {
    return Intl.message(
      'Search History Deleted',
      name: 'Search_History_Deleted',
      desc: '',
      args: [],
    );
  }

  /// `Backup and Restore`
  String get Backup_And_Restore {
    return Intl.message(
      'Backup and Restore',
      name: 'Backup_And_Restore',
      desc: '',
      args: [],
    );
  }

  /// `Backup`
  String get Backup {
    return Intl.message('Backup', name: 'Backup', desc: '', args: []);
  }

  /// `Restore`
  String get Restore {
    return Intl.message('Restore', name: 'Restore', desc: '', args: []);
  }

  /// `Share`
  String get Share {
    return Intl.message('Share', name: 'Share', desc: '', args: []);
  }

  /// `Save`
  String get Save {
    return Intl.message('Save', name: 'Save', desc: '', args: []);
  }

  /// `Backed up successfully at`
  String get Backup_Success {
    return Intl.message(
      'Backed up successfully at',
      name: 'Backup_Success',
      desc: '',
      args: [],
    );
  }

  /// `Failed to back up Data`
  String get Backup_Failed {
    return Intl.message(
      'Failed to back up Data',
      name: 'Backup_Failed',
      desc: '',
      args: [],
    );
  }

  /// `Data successfully restored`
  String get Restore_Success {
    return Intl.message(
      'Data successfully restored',
      name: 'Restore_Success',
      desc: '',
      args: [],
    );
  }

  /// `Failed to restore Data`
  String get Restore_Failed {
    return Intl.message(
      'Failed to restore Data',
      name: 'Restore_Failed',
      desc: '',
      args: [],
    );
  }

  /// `Select Backup`
  String get Select_Backup {
    return Intl.message(
      'Select Backup',
      name: 'Select_Backup',
      desc: '',
      args: [],
    );
  }

  /// `About`
  String get About {
    return Intl.message('About', name: 'About', desc: '', args: []);
  }

  /// `Name`
  String get Name {
    return Intl.message('Name', name: 'Name', desc: '', args: []);
  }

  /// `Version`
  String get Version {
    return Intl.message('Version', name: 'Version', desc: '', args: []);
  }

  /// `Developer`
  String get Developer {
    return Intl.message('Developer', name: 'Developer', desc: '', args: []);
  }

  /// `Sheikh Haziq`
  String get Sheikh_Haziq {
    return Intl.message(
      'Sheikh Haziq',
      name: 'Sheikh_Haziq',
      desc: '',
      args: [],
    );
  }

  /// `Organisation`
  String get Organisation {
    return Intl.message(
      'Organisation',
      name: 'Organisation',
      desc: '',
      args: [],
    );
  }

  /// `Jhelum Corp`
  String get Jhelum_Corp {
    return Intl.message('Jhelum Corp', name: 'Jhelum_Corp', desc: '', args: []);
  }

  /// `Telegram`
  String get Telegram {
    return Intl.message('Telegram', name: 'Telegram', desc: '', args: []);
  }

  /// `Contributors`
  String get Contributors {
    return Intl.message(
      'Contributors',
      name: 'Contributors',
      desc: '',
      args: [],
    );
  }

  /// `Source Code`
  String get Source_Code {
    return Intl.message('Source Code', name: 'Source_Code', desc: '', args: []);
  }

  /// `Bug Report`
  String get Bug_Report {
    return Intl.message('Bug Report', name: 'Bug_Report', desc: '', args: []);
  }

  /// `Feature Request`
  String get Feature_Request {
    return Intl.message(
      'Feature Request',
      name: 'Feature_Request',
      desc: '',
      args: [],
    );
  }

  /// `Made in Kashmir`
  String get Made_In_Kashmir {
    return Intl.message(
      'Made in Kashmir',
      name: 'Made_In_Kashmir',
      desc: '',
      args: [],
    );
  }

  /// `Check for Update`
  String get Check_For_Update {
    return Intl.message(
      'Check for Update',
      name: 'Check_For_Update',
      desc: '',
      args: [],
    );
  }

  /// `Progress`
  String get Progress {
    return Intl.message('Progress', name: 'Progress', desc: '', args: []);
  }

  /// `Play Next`
  String get Play_Next {
    return Intl.message('Play Next', name: 'Play_Next', desc: '', args: []);
  }

  /// `Add To Queue`
  String get Add_To_Queue {
    return Intl.message(
      'Add To Queue',
      name: 'Add_To_Queue',
      desc: '',
      args: [],
    );
  }

  /// `Add To Favourites`
  String get Add_To_Favourites {
    return Intl.message(
      'Add To Favourites',
      name: 'Add_To_Favourites',
      desc: '',
      args: [],
    );
  }

  /// `Remove From Favourites`
  String get Remove_From_Favourites {
    return Intl.message(
      'Remove From Favourites',
      name: 'Remove_From_Favourites',
      desc: '',
      args: [],
    );
  }

  /// `Download`
  String get Download {
    return Intl.message('Download', name: 'Download', desc: '', args: []);
  }

  /// `Add To Playlist`
  String get Add_To_Playlist {
    return Intl.message(
      'Add To Playlist',
      name: 'Add_To_Playlist',
      desc: '',
      args: [],
    );
  }

  /// `Start Radio`
  String get Start_Radio {
    return Intl.message('Start Radio', name: 'Start_Radio', desc: '', args: []);
  }

  /// `Album`
  String get Album {
    return Intl.message('Album', name: 'Album', desc: '', args: []);
  }

  /// `Rename`
  String get Rename {
    return Intl.message('Rename', name: 'Rename', desc: '', args: []);
  }

  /// `Add To Library`
  String get Add_To_Library {
    return Intl.message(
      'Add To Library',
      name: 'Add_To_Library',
      desc: '',
      args: [],
    );
  }

  /// `Remove From Library`
  String get Remove_From_Library {
    return Intl.message(
      'Remove From Library',
      name: 'Remove_From_Library',
      desc: '',
      args: [],
    );
  }

  /// `Are you sure you want to delete this item?`
  String get Delete_Item_Message {
    return Intl.message(
      'Are you sure you want to delete this item?',
      name: 'Delete_Item_Message',
      desc: '',
      args: [],
    );
  }

  /// `Equalizer`
  String get Equalizer {
    return Intl.message('Equalizer', name: 'Equalizer', desc: '', args: []);
  }

  /// `Sleep Timer`
  String get Sleep_Timer {
    return Intl.message('Sleep Timer', name: 'Sleep_Timer', desc: '', args: []);
  }

  /// `Create Playlist`
  String get Create_Playlist {
    return Intl.message(
      'Create Playlist',
      name: 'Create_Playlist',
      desc: '',
      args: [],
    );
  }

  /// `Playlist Name`
  String get Playlist_Name {
    return Intl.message(
      'Playlist Name',
      name: 'Playlist_Name',
      desc: '',
      args: [],
    );
  }

  /// `Create`
  String get Create {
    return Intl.message('Create', name: 'Create', desc: '', args: []);
  }

  /// `Import Playlist`
  String get Import_Playlist {
    return Intl.message(
      'Import Playlist',
      name: 'Import_Playlist',
      desc: '',
      args: [],
    );
  }

  /// `Import`
  String get Import {
    return Intl.message('Import', name: 'Import', desc: '', args: []);
  }

  /// `Rename Playlist`
  String get Rename_Playlist {
    return Intl.message(
      'Rename Playlist',
      name: 'Rename_Playlist',
      desc: '',
      args: [],
    );
  }

  /// `Done`
  String get Done {
    return Intl.message('Done', name: 'Done', desc: '', args: []);
  }

  /// `Cancel`
  String get Cancel {
    return Intl.message('Cancel', name: 'Cancel', desc: '', args: []);
  }

  /// `Confirm`
  String get Confirm {
    return Intl.message('Confirm', name: 'Confirm', desc: '', args: []);
  }

  /// `Yes`
  String get Yes {
    return Intl.message('Yes', name: 'Yes', desc: '', args: []);
  }

  /// `No`
  String get No {
    return Intl.message('No', name: 'No', desc: '', args: []);
  }

  /// `Show More`
  String get Show_More {
    return Intl.message('Show More', name: 'Show_More', desc: '', args: []);
  }

  /// `Show Less`
  String get Show_Less {
    return Intl.message('Show Less', name: 'Show_Less', desc: '', args: []);
  }

  /// `Remove`
  String get Remove {
    return Intl.message('Remove', name: 'Remove', desc: '', args: []);
  }

  /// `High`
  String get High {
    return Intl.message('High', name: 'High', desc: '', args: []);
  }

  /// `Low`
  String get Low {
    return Intl.message('Low', name: 'Low', desc: '', args: []);
  }

  /// `Songs will start playing soon.`
  String get Songs_Will_Start_Playing_Soon {
    return Intl.message(
      'Songs will start playing soon.',
      name: 'Songs_Will_Start_Playing_Soon',
      desc: '',
      args: [],
    );
  }

  /// `Are you sure you want to remove it?`
  String get Remove_Message {
    return Intl.message(
      'Are you sure you want to remove it?',
      name: 'Remove_Message',
      desc: '',
      args: [],
    );
  }

  /// `Are you sure you want to remove it from YTMusic?`
  String get Remove_From_YTMusic_Message {
    return Intl.message(
      'Are you sure you want to remove it from YTMusic?',
      name: 'Remove_From_YTMusic_Message',
      desc: '',
      args: [],
    );
  }

  /// `Are you sure you want to clear all history?`
  String get Remove_All_History_Message {
    return Intl.message(
      'Are you sure you want to clear all history?',
      name: 'Remove_All_History_Message',
      desc: '',
      args: [],
    );
  }

  /// `Copied to Clipboard`
  String get Copied_To_Clipboard {
    return Intl.message(
      'Copied to Clipboard',
      name: 'Copied_To_Clipboard',
      desc: '',
      args: [],
    );
  }

  /// `No Internet Connection`
  String get No_Internet_Connection {
    return Intl.message(
      'No Internet Connection',
      name: 'No_Internet_Connection',
      desc: '',
      args: [],
    );
  }

  /// `Go to Downloads`
  String get Go_To_Downloads {
    return Intl.message(
      'Go to Downloads',
      name: 'Go_To_Downloads',
      desc: '',
      args: [],
    );
  }
}

class AppLocalizationDelegate extends LocalizationsDelegate<S> {
  const AppLocalizationDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[
      Locale.fromSubtags(languageCode: 'en'),
      Locale.fromSubtags(languageCode: 'es'),
      Locale.fromSubtags(languageCode: 'hi'),
      Locale.fromSubtags(languageCode: 'it'),
      Locale.fromSubtags(languageCode: 'tr'),
      Locale.fromSubtags(languageCode: 'ur'),
    ];
  }

  @override
  bool isSupported(Locale locale) => _isSupported(locale);
  @override
  Future<S> load(Locale locale) => S.load(locale);
  @override
  bool shouldReload(AppLocalizationDelegate old) => false;

  bool _isSupported(Locale locale) {
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return true;
      }
    }
    return false;
  }
}
