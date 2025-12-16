import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:gyawun/generated/l10n.dart';
import 'package:gyawun/themes/colors.dart';
import 'package:gyawun/utils/adaptive_widgets/buttons.dart';
import 'package:gyawun/utils/adaptive_widgets/icons.dart';
import 'package:gyawun/ytmusic/ytmusic.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

class InternetGuard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onInternetLost;
  final VoidCallback? onInternetRestored;

  const InternetGuard({
    super.key,
    required this.child,
    this.onInternetLost,
    this.onInternetRestored,
  });

  @override
  State<InternetGuard> createState() => _InternetGuardState();
}

class _InternetGuardState extends State<InternetGuard> {
  int _lastHandledError = 0;
  bool _isOfflineMode = false;
  ValueNotifier<int> get lastConnectionError =>
      GetIt.I<YTMusic>().lastConnectionError;
  StreamSubscription<InternetStatus>? _networkSubscription;
  final InternetConnection _internetConnection = InternetConnection();

  @override
  void initState() {
    super.initState();
    lastConnectionError.addListener(_onConnectionErrorDetected);
    _lastHandledError = lastConnectionError.value;
  }

  @override
  void dispose() {
    _networkSubscription?.cancel();
    lastConnectionError.removeListener(_onConnectionErrorDetected);
    super.dispose();
  }

  void _onConnectionErrorDetected() {
    if (!mounted) return;
    final currentErrorTime = lastConnectionError.value;
    if (currentErrorTime > _lastHandledError) {
      _lastHandledError = currentErrorTime;
      _enterOfflineMode();
    }
  }

  void _enterOfflineMode() {
    if (_isOfflineMode) return;
    setState(() {
      _isOfflineMode = true;
    });
    widget.onInternetLost?.call();
    _startMonitoringNetwork();
  }

  void _startMonitoringNetwork() async {
    _networkSubscription?.cancel();
    // Prevent flickering loops: only auto-restore if we transition from Offline to Online.
    // If we are already connected (API error), we wait for manual retry.
    InternetStatus lastKnownStatus = await _internetConnection.internetStatus;
    _networkSubscription = _internetConnection.onStatusChange.listen((status) {
      if (lastKnownStatus == InternetStatus.disconnected &&
          status == InternetStatus.connected) {
        _tryRestoreConnection();
      }
    });
  }

  void _tryRestoreConnection() {
    if (!mounted || !_isOfflineMode) return;
    setState(() {
      _isOfflineMode = false;
    });
    _networkSubscription?.cancel();
    _networkSubscription = null;
    widget.onInternetRestored?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_isOfflineMode)
          Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(AdaptiveIcons.wifi_off_rounded,
                      size: 80, color: greyColor),
                  const SizedBox(height: 20),
                  Text(
                    S.of(context).No_Internet_Connection,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  AdaptiveFilledButton(
                    onPressed: () => context.go('/saved/downloads'),
                    child: Text(S.of(context).Go_To_Downloads),
                  ),
                  const SizedBox(height: 20),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: Text(S.of(context).Retry),
                    onPressed: () {
                      _tryRestoreConnection();
                    },
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
