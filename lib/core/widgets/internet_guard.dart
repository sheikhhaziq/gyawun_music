import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'package:gyawun/generated/l10n.dart';
import 'package:gyawun/themes/colors.dart';
import 'package:gyawun/utils/adaptive_widgets/buttons.dart';
import 'package:gyawun/utils/adaptive_widgets/icons.dart';

class InternetGuard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onConnectivityRestored;

  const InternetGuard({
    super.key,
    required this.child,
    this.onConnectivityRestored,
  });

  @override
  State<InternetGuard> createState() => _InternetGuardState();
}

class _InternetGuardState extends State<InternetGuard> {
  final Connectivity _connectivity = Connectivity();

  bool _isOnline = true;
  bool _wasOffline = false;
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    _initConnectivity();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _initConnectivity() async {
    // Initial check
    final result = await _connectivity.checkConnectivity();
    _updateStatus(result);

    // Listen for changes
    _subscription =
        _connectivity.onConnectivityChanged.listen(_updateStatus);
  }

  void _updateStatus(dynamic value) {
    final bool online = !_isOffline(value);

    if (online != _isOnline && mounted) {
      setState(() {
        if (!online) {
          _wasOffline = true;
        }
        
        if (online && _wasOffline) {
          _wasOffline = false;
          widget.onConnectivityRestored?.call();
        }
        
        _isOnline = online;
      });
    }
  }

  bool _isOffline(dynamic value) {
    if (value is ConnectivityResult) {
      return value == ConnectivityResult.none;
    }

    if (value is List<ConnectivityResult>) {
      return value.contains(ConnectivityResult.none);
    }

    return true;
  }

  Future<void> _retry() async {
    final result = await _connectivity.checkConnectivity();
    _updateStatus(result);
  }

  @override
  Widget build(BuildContext context) {
    if (_isOnline) {
      return widget.child;
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              AdaptiveIcons.wifi_off_rounded,
              size: 80,
              color: greyColor,
            ),
            const SizedBox(height: 20),
            Text(
              S.of(context).No_Internet_Connection,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            AdaptiveFilledButton(
              onPressed: () => context.go('/library/downloads'),
              child: Text(S.of(context).Go_To_Downloads),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              icon: const Icon(Icons.refresh),
              label: Text(S.of(context).Retry),
              onPressed: _retry,
            ),
          ],
        ),
      ),
    );
  }
}