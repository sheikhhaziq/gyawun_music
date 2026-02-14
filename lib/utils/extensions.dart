import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/settings_manager.dart';

extension DarkMode on BuildContext {
  /// is dark mode currently enabled?
  bool get isDarkMode {
    final themeMode = select<SettingsManager, ThemeMode>((s) => s.themeMode);
    final brightness = themeMode == ThemeMode.system
        ? MediaQuery.of(this).platformBrightness
        : themeMode == ThemeMode.dark
        ? Brightness.dark
        : Brightness.light;
    return brightness == Brightness.dark;
  }

  bool get isDarkModeOnce {
    final brightness = read<SettingsManager>().themeMode == ThemeMode.system
        ? MediaQuery.of(this).platformBrightness
        : read<SettingsManager>().themeMode == ThemeMode.dark
        ? Brightness.dark
        : Brightness.light;
    return brightness == Brightness.dark;
  }

  Color get subtitleColor =>
      isDarkMode ? Colors.white.withAlpha(150) : Colors.black.withAlpha(150);
  Color get bottomModalBackgroundColor => isDarkMode
      ? Color.alphaBlend(Colors.black.withAlpha(220), Colors.white)
      : Colors.white;
}

extension LayoutExtensions on BuildContext {
  bool get isKeyboardSpaceLimited {
    final mediaQuery = MediaQuery.of(this);
    final isLandscape = mediaQuery.orientation == Orientation.landscape;
    return isLandscape && mediaQuery.size.height < 450;
  }
}

extension StringMani on String {
  String get breakWord {
    String breakWord = '';
    for (var element in runes) {
      breakWord += String.fromCharCode(element);
      breakWord += '\u200B';
    }
    return breakWord;
  }
}
