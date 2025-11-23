import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gyawun/generated/l10n.dart';
import 'package:gyawun/themes/colors.dart';
import 'package:gyawun/utils/adaptive_widgets/buttons.dart';
import 'package:gyawun/utils/adaptive_widgets/icons.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

class InternetGuard extends StatelessWidget {
  final Widget child;

  const InternetGuard({super.key, required this.child});

  Stream<InternetStatus> get _internetStatusStream async* {
    yield await InternetConnection().internetStatus;
    yield* InternetConnection().onStatusChange;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<InternetStatus>(
      stream: _internetStatusStream,
      builder: (context, snapshot) {
        final status = snapshot.data;
        if (status == InternetStatus.disconnected) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(AdaptiveIcons.wifi_off_rounded,
                    size: 80, color: greyColor),
                const SizedBox(height: 20),
                Text(
                  S.of(context).No_Internet_Connection,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const SizedBox(height: 30),
                AdaptiveFilledButton(
                  onPressed: () => context.go('/saved/downloads'),
                  child: Text(S.of(context).Go_To_Downloads),
                ),
              ],
            ),
          );
        }
        return child;
      },
    );
  }
}
