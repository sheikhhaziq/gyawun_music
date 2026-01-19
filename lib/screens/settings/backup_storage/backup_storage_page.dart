import 'dart:io';

import 'package:easy_folder_picker/FolderPicker.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../generated/l10n.dart';
import '../widgets/setting_item.dart';
import '../../../utils/adaptive_widgets/adaptive_widgets.dart';
import '../../../utils/bottom_modals.dart';
import '../../../services/bottom_message.dart';

import 'cubit/backup_storage_cubit.dart';

class BackupStoragePage extends StatelessWidget {
  const BackupStoragePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => BackupStorageCubit(),
      child: BlocListener<BackupStorageCubit, BackupStorageState>(
        listenWhen: (_, state) => state.lastResult != null,
        listener: (context, state) {
          final result = state.lastResult;
          if (result == null) return;

          if (result is BackupSuccess) {
            BottomMessage.showText(
              context,
              '${S.of(context).Backup_Success} ${result.path}',
            );
          } else if (result is BackupFailure) {
            BottomMessage.showText(
              context,
              S.of(context).Backup_Failed,
            );
          } else if (result is RestoreSuccess) {
            BottomMessage.showText(
              context,
              S.of(context).Restore_Success,
            );
          } else if (result is RestoreFailure) {
            BottomMessage.showText(
              context,
              S.of(context).Restore_Failed,
            );
          }
        },
        child: const _BackupStoragePage(),
      ),
    );
  }
}

class _BackupStoragePage extends StatelessWidget {
  const _BackupStoragePage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).Backup_And_Restore),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: BlocBuilder<BackupStorageCubit, BackupStorageState>(
            builder: (context, state) {
              final cubit = context.read<BackupStorageCubit>();

              return ListView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  if (Platform.isAndroid) ...[
                    GroupTitle(title: "Storage"),
                    SettingTile(
                      title: "App Folder",
                      leading: const Icon(FluentIcons.folder_24_filled),
                      isFirst: true,
                      isLast: true,
                      subtitle: state.appFolder,
                      trailing: AdaptiveOutlinedButton(
                        child: const Text('Change'),
                        onPressed: () async {
                          final dir = await FolderPicker.pick(
                            context: context,
                            allowFolderCreation: true,
                            rootDirectory: Directory(state.appFolder),
                          );
                          if (dir != null) {
                            cubit.setAppFolder(dir.path);
                          }
                        },
                      ),
                    ),
                  ],

                  GroupTitle(title: S.of(context).Backup_And_Restore),

                  /// BACKUP
                  SettingTile(
                    title: S.of(context).Backup,
                    leading: const Icon(Icons.backup_rounded),
                    isFirst: true,
                    onTap: () async {
                      final result = await showBackupSelector(context);
                      if (result == null) return;

                      cubit.backup(
                        action: result.$1,
                        items: result.$2,
                      );
                    },
                  ),

                  /// RESTORE
                  SettingTile(
                    title: S.of(context).Restore,
                    leading: const Icon(Icons.restore_rounded),
                    isLast: true,
                    onTap: cubit.restore,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/* ──────────────────────────────────────────────────────────────── */
/* BACKUP SELECTION MODAL (UI ONLY)                                  */
/* ──────────────────────────────────────────────────────────────── */

Future<(String, List)?> showBackupSelector(BuildContext context) async {
  return await showCupertinoModalPopup<(String, List)?>(
    useRootNavigator: false,
    context: context,
    builder: (context) {
      final items = ValueNotifier<List<Map<String, dynamic>>>([
        {'name': 'Favourites', 'selected': false},
        {'name': 'Playlists', 'selected': false},
        {'name': 'Settings', 'selected': false},
        {'name': 'Song History', 'selected': false},
        {'name': 'Downloads', 'selected': false},
      ]);

      return BottomModalLayout(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: Text(S.of(context).Select_Backup),
                centerTitle: true,
                automaticallyImplyLeading: false,
              ),
              const Divider(),
              ValueListenableBuilder(
                valueListenable: items,
                builder: (_, backups, _) {
                  return Column(
                    children: backups.indexed.map((el) {
                      final index = el.$1;
                      final item = el.$2;

                      return CheckboxListTile(
                        title: Text(item['name']),
                        value: item['selected'],
                        onChanged: (val) {
                          final newItems = List<Map<String, dynamic>>.from(
                            items.value,
                          );
                          newItems[index]['selected'] = val;
                          items.value = newItems;
                        },
                      );
                    }).toList(),
                  );
                },
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _backupActionButton(
                      context,
                      label: S.of(context).Share,
                      action: 'Share',
                      items: items,
                    ),
                    const SizedBox(width: 20),
                    _backupActionButton(
                      context,
                      label: S.of(context).Save,
                      action: 'Save',
                      items: items,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Widget _backupActionButton(
  BuildContext context, {
  required String label,
  required String action,
  required ValueNotifier<List<Map<String, dynamic>>> items,
}) {
  return MaterialButton(
    color: Theme.of(context).colorScheme.primary,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
    ),
    onPressed: () {
      final selected = items.value
          .where((e) => e['selected'] == true)
          .map((e) => e['name'].toLowerCase())
          .toList();

      Navigator.pop(
        context,
        selected.isEmpty ? null : (action, selected),
      );
    },
    child: Text(
      label,
      style: TextStyle(
        color: Theme.of(context).scaffoldBackgroundColor,
      ),
    ),
  );
}
