import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:gyawun/services/settings_manager.dart';

part 'appearance_state.dart';

class AppearanceCubit extends Cubit<AppearanceState> {
  final SettingsManager _settings = GetIt.I<SettingsManager>();

  late final VoidCallback _listener;

  AppearanceCubit()
      : super(
          AppearanceLoaded(
            themeMode: GetIt.I<SettingsManager>().themeMode,
            accentColor: GetIt.I<SettingsManager>().accentColor,
            amoledBlack: GetIt.I<SettingsManager>().amoledBlack,
            dynamicColors: GetIt.I<SettingsManager>().dynamicColors,
          ),
        ) {
    _listener = () {
      if (!isClosed) {
        _emitState();
      }
    };

    _settings.addListener(_listener);
  }

  void _emitState() {
    if (isClosed) return;

    emit(
      AppearanceLoaded(
        themeMode: _settings.themeMode,
        accentColor: _settings.accentColor,
        amoledBlack: _settings.amoledBlack,
        dynamicColors: _settings.dynamicColors,
      ),
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await _settings.setThemeMode(mode);
    // listener will emit
  }

  void setAmoledBlack(bool value) {
    _settings.amoledBlack = value;
  }

  void setDynamicColors(bool value) {
    _settings.dynamicColors = value;
  }

  @override
  Future<void> close() {
    _settings.removeListener(_listener);
    return super.close();
  }
}
