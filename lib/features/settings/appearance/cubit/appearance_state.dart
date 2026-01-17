part of 'appearance_cubit.dart';

@immutable
sealed class AppearanceState {
  const AppearanceState();
}

class AppearanceLoaded extends AppearanceState {
  final ThemeMode themeMode;
  final Color? accentColor;
  final bool amoledBlack;
  final bool dynamicColors;

  const AppearanceLoaded({
    required this.themeMode,
    required this.accentColor,
    required this.amoledBlack,
    required this.dynamicColors,
  });
}
