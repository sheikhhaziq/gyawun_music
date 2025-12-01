import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gyawun/generated/l10n.dart';
import 'package:gyawun/themes/colors.dart';
import 'package:gyawun/utils/adaptive_widgets/buttons.dart';
import 'package:gyawun/utils/adaptive_widgets/icons.dart';
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
  late final InternetConnection _internetConnection;
  StreamSubscription<InternetStatus>? _subscription;
  InternetStatus? _internetStatus;

  @override
  void initState() {
    super.initState();
    _internetConnection = InternetConnection();
    _subscription =
        _internetConnection.onStatusChange.listen(_handleConnectionChange);
    _checkInitialStatus();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _checkInitialStatus() async {
    final status = await _internetConnection.internetStatus;
    _handleConnectionChange(status);
  }

  void _handleConnectionChange(InternetStatus newStatus) {
    if (!mounted) return;
    if (_internetStatus == InternetStatus.connected &&
        newStatus == InternetStatus.disconnected) {
      widget.onInternetLost?.call();
    } else if (_internetStatus == InternetStatus.disconnected &&
        newStatus == InternetStatus.connected) {
      widget.onInternetRestored?.call();
    }
    setState(() {
      _internetStatus = newStatus;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_internetStatus == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      );
    }
    return Stack(
      children: [
        widget.child,
        if (_internetStatus == InternetStatus.disconnected)
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
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  const SizedBox(height: 30),
                  AdaptiveFilledButton(
                    onPressed: () => context.go('/saved/downloads'),
                    child: Text(S.of(context).Go_To_Downloads),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
