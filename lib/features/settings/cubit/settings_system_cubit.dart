import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

part 'settings_system_state.dart';

class SettingsSystemCubit extends Cubit<SettingsSystemState> {
  SettingsSystemCubit() : super(const SettingsSystemInitial());

  Future<void> load() async {
    if (!Platform.isAndroid) {
      emit(const SettingsSystemLoaded(
        isBatteryOptimizationDisabled: null,
      ));
      return;
    }

    final granted = await Permission.ignoreBatteryOptimizations.isGranted;

    emit(
      SettingsSystemLoaded(
        isBatteryOptimizationDisabled: granted,
      ),
    );
  }

  Future<void> requestBatteryOptimizationIgnore() async {
    if (!Platform.isAndroid) return;

    await Permission.ignoreBatteryOptimizations.request();
    await load();
  }
}
