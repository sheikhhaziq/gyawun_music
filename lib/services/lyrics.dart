import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart';
import 'package:translator/translator.dart';
import 'package:language_detector/language_detector.dart';

class Lyrics {
  Map lyricsList = {};
  Future<Map<String, dynamic>> getLyrics({
    required String videoId,
    required String title,
    required int durationInSeconds,
    String? artist,
    String? album,
    String? translation,
  }) async {
    if (lyricsList[videoId] != null) {
      return lyricsList[videoId];
    }
    Map response = await fetchLyrics(
      videoId: videoId,
      title: title,
      durationInSeconds: durationInSeconds,
      album: album,
      artist: artist,
    );
    if (response["syncedLyrics"] != null || response['plainLyrics'] != null) {
      final lyricsData = {
        "syncedLyrics": response["syncedLyrics"].toString(),
        "plainLyrics": response["plainLyrics"],
        "transLyrics": "",
      };
      if (translation != null) {
        String lyricsLang = await LanguageDetector.getLanguageCode(
            content: response["plainLyrics"]);
        if (lyricsLang != translation) {
          if (response["syncedLyrics"] != null) {
            lyricsData["transLyrics"] = await translateSyncLyrics(
              response["syncedLyrics"].toString(),
              lyricsLang,
              translation,
            );
          } else {
            lyricsData["plainLyrics"] = await translatePlainLyrics(
              response['plainLyrics'],
              lyricsLang,
              translation,
            );
          }
        }
      }
      lyricsList[videoId] = lyricsData;
      return lyricsData;
    }
    return {'success': false};
  }

  void fixLrcFormat(Map lrc) {
    if (lrc.containsKey('syncedLyrics') && lrc['syncedLyrics'] != null) {
      lrc['syncedLyrics'] = (lrc['syncedLyrics'] as String)
          .replaceAllMapped(RegExp(r'\[(\d{2}):(\d{2}):(\d{2,3})\]'), (match) {
        return '[${match.group(1)}:${match.group(2)}.${match.group(3)}]';
      });
    }
  }

  Future<Map> fetchLyrics({
    required String videoId,
    required String title,
    required int durationInSeconds,
    String? artist,
    String? album,
  }) async {
    try {
      Uri uri;
      bool isSpecificSearch = false;
      if (artist != null && album != null) {
        uri = Uri.https('lrclib.net', '/api/get', {
          'artist_name': artist,
          'track_name': title,
          'album_name': album,
          'duration': durationInSeconds.toString(),
        });
        isSpecificSearch = true;
      } else {
        final params = {'track_name': title};
        if (artist != null) params['artist_name'] = artist;
        if (album != null) params['album_name'] = album;
        uri = Uri.https('lrclib.net', '/api/search', params);
      }
      final response = await get(uri).timeout(const Duration(seconds: 20));
      if (response.statusCode != 200) {
        debugPrint("Error in lrclib get : ${response.statusCode}");
        return {};
      }
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      Map lyric = {};
      if (isSpecificSearch) {
        if (decoded is Map) lyric = decoded;
      } else {
        if (decoded is List && decoded.isNotEmpty) {
          decoded.sort((a, b) {
            final durA = (a['duration'] as num).toDouble();
            final durB = (b['duration'] as num).toDouble();
            final target = durationInSeconds.toDouble();
            return (durA - target).abs().compareTo((durB - target).abs());
          });
          lyric = decoded.first;
        }
      }
      fixLrcFormat(lyric);
      return lyric;
    } catch (e) {
      debugPrint("Error in fetchLyrics: $e");
      return {};
    }
  }

  Future<String?> translateSyncLyrics(
      String lyric, String from, String to) async {
    try {
      Translation trans = await lyric.translate(from: from, to: to);
      final transLines = trans.text.split("\n");
      final lyricLines = lyric.split("\n");
      if (lyricLines.length != transLines.length) {
        throw Exception("Translation lines do not match original lines");
      }
      String transLyric = "";
      for (int i = 0; i < transLines.length; i++) {
        transLyric +=
            "${lyricLines[i].split("]")[0]}]${transLines[i].split("]")[1]}\n";
      }
      return transLyric;
    } catch (e) {
      return "";
    }
  }

  Future<String?> translatePlainLyrics(
      String lyric, String from, String to) async {
    try {
      Translation trans = await lyric.translate(from: from, to: to);
      final lines = lyric.split("\n");
      final transLines = trans.text.split("\n");
      if (lines.length != transLines.length) {
        throw Exception("Translation lines do not match original lines");
      }
      String transLyric = '';
      for (int i = 0; i < lines.length; i++) {
        transLyric += "${lines[i]}\n[${transLines[i]}]\n\n";
      }
      return transLyric;
    } catch (e) {
      return "";
    }
  }
}
