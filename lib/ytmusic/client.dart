import 'dart:convert';

import 'package:gyawun/ytmusic/helpers.dart';
import 'package:gyawun/ytmusic/modals/yt_config.dart';
import 'package:http/http.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

class YTClient {
  YTClient({required this.config, this.onIdUpdate}) {
    init();
  }
  Map<String, String> headers = {};
  Map<String, dynamic> context = {};
  int? signatureTimestamp;
  YTConfig? config;
  void Function(String visitorId)? onIdUpdate;

  static const ytmDomain = 'music.youtube.com';
  static const httpsYtmDomain = 'https://music.youtube.com';
  static const baseApiEndpoint = '/youtubei/v1/';
  static const String ytmParams =
      '?alt=json&key=AIzaSyC9XL3ZjWddXya6X74dJoCTL-WEYFDNX30';
  static const userAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:88.0) Gecko/20100101 Firefox/88.0';

  Future<void> init() async {
    headers = initializeHeaders();
    context = initializeContext();

    if (config?.visitorData != null) {
      headers['X-Goog-Visitor-Id'] = config!.visitorData;
    }
  }

  void refreshContext() {
    context = initializeContext();
  }

  Future<void> refreshHeaders() async {
    headers = initializeHeaders();
    if (config?.visitorData != null) {
      headers['X-Goog-Visitor-Id'] = config!.visitorData;
    }
  }

  static Future<bool> isOffline() async {
    return await InternetConnection().internetStatus ==
        InternetStatus.disconnected;
  }

  Future<void> resetVisitorId() async {
    Map<String, String> newHeaders = Map.from(headers);
    newHeaders.remove('X-Goog-Visitor-Id');
    final response = await sendGetRequest(httpsYtmDomain, newHeaders);
    final reg = RegExp(r'ytcfg\.set\s*\(\s*({.+?})\s*\)\s*;');
    RegExpMatch? matches = reg.firstMatch(response.body);
    String? visitorId;
    if (matches != null) {
      final ytcfg = json.decode(matches.group(1).toString());
      visitorId = ytcfg['VISITOR_DATA']?.toString();
      config ??= YTConfig(visitorData: '', language: 'en', location: 'IN');
      config = config!.copyWith(visitorData: visitorId);
      if (onIdUpdate != null && visitorId != null) {
        onIdUpdate!(visitorId);
      }
    }
    refreshHeaders();
  }

  static Future<String?> getVisitorid() async {
    Map<String, String> newHeaders = initializeHeaders();
    newHeaders.remove('X-Goog-Visitor-Id');
    final response = await _sendGetRequest(httpsYtmDomain, newHeaders);
    final reg = RegExp(r'ytcfg\.set\s*\(\s*({.+?})\s*\)\s*;');
    RegExpMatch? matches = reg.firstMatch(response.body);
    String? visitorId;
    if (matches != null) {
      final ytcfg = json.decode(matches.group(1).toString());
      visitorId = ytcfg['VISITOR_DATA']?.toString();
      return visitorId;
    }
    return null;
  }

  Future<Response> sendGetRequest(
    String url,
    Map<String, String>? headers,
  ) async {
    if (await isOffline()) {
      return Response.bytes([], 503);
    }
    final Uri uri = Uri.parse(url);
    final Response response = await get(uri, headers: headers);
    return response;
  }

  static Future<Response> _sendGetRequest(
    String url,
    Map<String, String>? headers,
  ) async {
    if (await isOffline()) {
      return Response.bytes([], 503);
    }
    final Uri uri = Uri.parse(url);
    final Response response = await get(uri, headers: headers);
    return response;
  }

  Future<Response> addPlayingStats(String videoId, Duration time) async {
    if (await isOffline()) {
      return Response.bytes([], 503);
    }
    final Uri uri = Uri.parse(
        'https://music.youtube.com/api/stats/watchtime?ns=yt&ver=2&c=WEB_REMIX&cmt=${(time.inMilliseconds / 1000)}&docid=$videoId');
    final Response response = await get(uri, headers: headers);
    return response;
  }

  Future<Map> sendRequest(String endpoint, Map<String, dynamic> body,
      {Map<String, String>? headers, String additionalParams = ''}) async {
    //
    if (await isOffline()) {
      return {};
    }
    body = {...body, ...context};

    this.headers.addAll(headers ?? {});

    if (config?.visitorData == null || config!.visitorData.isEmpty) {
      await resetVisitorId();
    }
    if (this.headers['X-Goog-Visitor-Id'] == null &&
        config?.visitorData != null) {
      this.headers['X-Goog-Visitor-Id'] = config!.visitorData;
    }
    final Uri uri = Uri.parse(httpsYtmDomain +
        baseApiEndpoint +
        endpoint +
        ytmParams +
        additionalParams);
    final response =
        await post(uri, headers: this.headers, body: jsonEncode(body));

    if (response.statusCode == 200) {
      return json.decode(response.body) as Map;
    } else {
      return {};
    }
  }
}
