import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pub_semver/pub_semver.dart';

import '../app_config.dart';

Future<UpdateInfo?> checkUpdate({BaseDeviceInfo? deviceInfo}) async {
  try {
    final response = await http.get(appConfig.updateUri,
        headers: {'Accept': 'application/vnd.github+json'});
    Map update = jsonDecode(response.body);
    Version currentVersion = Version.parse(appConfig.codeName);

    Version remoteVersion =
        Version.parse(update['tag_name'].toString().replaceAll('v', ''));

    int comparison = remoteVersion.compareTo(currentVersion);

    if (comparison > 0) {
      if (deviceInfo == null) {
        final deviceInfoPlugin = DeviceInfoPlugin();
        deviceInfo = await deviceInfoPlugin.deviceInfo;
      }

      Map? supportedAsset;
      List assets = update['assets'];
      if (Platform.isAndroid) {
        List<String> supportedAbis =
            deviceInfo.data['supportedAbis'].cast<String>();

        for (var supportedAbi in supportedAbis) {
          List supportedAssets = assets
              .where((asset) => asset['name'].contains(supportedAbi))
              .toList();
          if (supportedAssets.isNotEmpty) {
            supportedAsset = supportedAssets.first;
            break;
          }
        }
      } else if (Platform.isWindows) {
        List supportedAssets = assets
            .where(
              (asset) =>
                  asset["content_type"] == "application/x-msdownload" ||
                  asset['name'].toString().endsWith('.exe'),
            )
            .toList();
        supportedAsset =
            supportedAssets.isNotEmpty ? supportedAssets.first : null;
      }
      if (supportedAsset == null) return null;
      int downloadCount = 0;
      for (var asset in assets) {
        downloadCount += (asset['download_count'] as int);
      }
      return UpdateInfo(
        name: update['name'],
        publishedAt: update['published_at'],
        body: update['body'],
        downloadUrl: supportedAsset['browser_download_url'],
        downloadCount: downloadCount,
      );
    } else {
      return null;
    }
  } catch (e) {
    debugPrint("Exception in checkUpdate: $e");
    return null;
  }
}

class UpdateInfo {
  String name;
  String publishedAt;
  String body;
  String downloadUrl;
  int downloadCount;
  UpdateInfo({
    required this.name,
    required this.publishedAt,
    required this.body,
    required this.downloadCount,
    required this.downloadUrl,
  });
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'publishedAt': publishedAt,
      'body': body,
      'downloadUrl': downloadUrl,
      'downloadCount': downloadCount,
    };
  }
}
