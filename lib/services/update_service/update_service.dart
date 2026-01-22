import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:gyawun/services/update_service/models/update_info.dart';
import 'package:gyawun/services/update_service/widgets/update_checking.dart';
import 'package:gyawun/services/update_service/widgets/update_dialog.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pub_semver/pub_semver.dart';

class UpdateService {
  static const String owner = 'sheikhhaziq';
  static const String repo = 'gyawun_music';

  /* ─────────────────────────────────────────────
   * UPDATE CHECK (CHANNEL AWARE)
   * ───────────────────────────────────────────── */
  static Future<UpdateInfo?> checkForUpdate() async {
    try {
      final package = await PackageInfo.fromPlatform();
      final currentVersion = Version.parse(package.version);

      final bool isAlpha = package.version.contains('-alpha.');
      final bool isBeta = package.version.contains('-beta.');

      final uri = Uri.parse(
        'https://api.github.com/repos/$owner/$repo/releases',
      );

      final response = await http.get(
        uri,
        headers: {'Accept': 'application/vnd.github+json'},
      );

      if (response.statusCode != 200) return null;

      final List releases = jsonDecode(response.body);

      Iterable<Map<String, dynamic>> channelReleases;

      if (isAlpha) {
        channelReleases = releases
            .where(
              (r) =>
                  r['prerelease'] == true &&
                  r['tag_name'].toString().contains('-alpha.'),
            )
            .whereType<Map<String, dynamic>>();
      } else if (isBeta) {
        channelReleases = releases
            .where(
              (r) =>
                  r['prerelease'] == true &&
                  r['tag_name'].toString().contains('-beta.'),
            )
            .whereType<Map<String, dynamic>>();
      } else {
        channelReleases = releases
            .where((r) => r['prerelease'] == false)
            .whereType<Map<String, dynamic>>();
      }

      if (channelReleases.isEmpty) return null;

      final sorted = channelReleases.toList()
        ..sort((a, b) {
          final va = Version.parse(
            a['tag_name'].toString().replaceFirst('v', ''),
          );
          final vb = Version.parse(
            b['tag_name'].toString().replaceFirst('v', ''),
          );
          return vb.compareTo(va);
        });

      final release = sorted.first;

      final remoteVersion = Version.parse(
        release['tag_name'].toString().replaceFirst('v', ''),
      );

      if (remoteVersion <= currentVersion) return null;

      final asset = await _selectAsset(release['assets']);
      if (asset == null) return null;

      return UpdateInfo(
        version: remoteVersion,
        name: release['name'] ?? '',
        body: release['body'] ?? '',
        publishedAt: release['published_at'] ?? '',
        downloadUrl: asset['browser_download_url'],
      );
    } catch (_) {
      return null;
    }
  }

  /* ───────────────────────────────────────────── */
  static Future<void> autoCheck(BuildContext context) async {
    final update = await checkForUpdate();
    if (update == null || !context.mounted) return;
    await showUpdateDialog(context, update);
  }

  static Future<void> manualCheck(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: false,
      builder: (_) => const UpdateCheckingDialog(),
    );

    final update = await checkForUpdate();

    if (!context.mounted) return;
    Navigator.pop(context);

    if (update != null) {
      await showUpdateDialog(context, update);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You are already on the latest version')),
      );
    }
  }

  static Future<void> showUpdateDialog(BuildContext context, UpdateInfo info) {
    return showDialog(
      context: context,
      useRootNavigator: false,
      builder: (_) => UpdateDialog(info),
    );
  }

  /* ─────────────────────────────────────────────
   * ASSET SELECTION
   * ───────────────────────────────────────────── */
  static Future<Map?> _selectAsset(List assets) async {
    final deviceInfo = DeviceInfoPlugin();

    if (Platform.isAndroid) {
      final android = await deviceInfo.androidInfo;
      for (final abi in android.supportedAbis) {
        final match = assets.where((a) => a['name'].contains(abi)).toList();
        if (match.isNotEmpty) return match.first;
      }
    }

    // if (Platform.isWindows) {
    //   return assets.firstWhere(
    //     (a) => a['name'].toString().endsWith('.exe'),
    //     orElse: () => null,
    //   );
    // }

    return null;
  }
}
