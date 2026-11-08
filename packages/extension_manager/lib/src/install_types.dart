import 'package:gmx/gmx.dart';

import 'installed_record.dart';

/// The install could not proceed. The message is safe to show to the user.
class InstallException implements Exception {
  const InstallException(this.message);

  final String message;

  @override
  String toString() => 'InstallException: $message';
}

/// What the user is asked to approve. Everything here comes from the
/// downloaded archive, never from the repository.
class InstallPrompt {
  const InstallPrompt({
    required this.metadata,
    this.installed,
    this.permissionsGrew = false,
    this.sourceChanged = false,
  });

  final GmxMetadata metadata;

  /// The current record when this is an update, null for a fresh install.
  final InstalledRecord? installed;

  /// The update asks for more than the installed version had.
  final bool permissionsGrew;

  /// The update comes from a different repository than the install.
  final bool sourceChanged;

  bool get isUpdate => installed != null;
}

/// Return true to proceed, false to cancel.
typedef ConfirmInstall = Future<bool> Function(InstallPrompt prompt);
