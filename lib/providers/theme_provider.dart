import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDark = false;
  bool get isDark => _isDark;

  void toggleTheme() {
    _isDark = !_isDark;
    notifyListeners();
  }

  static const _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.indigo,
    onPrimary: Colors.white,
    primaryContainer: AppColors.sage,
    onPrimaryContainer: AppColors.ink,
    secondary: AppColors.blue,
    onSecondary: AppColors.ink,
    secondaryContainer: AppColors.aqua,
    onSecondaryContainer: AppColors.ink,
    tertiary: AppColors.aqua,
    onTertiary: AppColors.ink,
    error: Color(0xFFB3261E),
    onError: Colors.white,
    surface: Color(0xFFF6FAF1),
    onSurface: AppColors.ink,
    onSurfaceVariant: Color(0xFF4A4D80),
    outline: Color(0xFF7C80B8),
    outlineVariant: AppColors.sage,
    surfaceContainerHighest: AppColors.sage,
  );

  static const _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.aqua,
    onPrimary: AppColors.night,
    primaryContainer: AppColors.indigo,
    onPrimaryContainer: AppColors.mist,
    secondary: AppColors.blue,
    onSecondary: AppColors.night,
    secondaryContainer: AppColors.nightRaised,
    onSecondaryContainer: AppColors.mist,
    tertiary: AppColors.sage,
    onTertiary: AppColors.night,
    error: Color(0xFFF2B8B5),
    onError: AppColors.night,
    surface: AppColors.nightSurface,
    onSurface: AppColors.mist,
    onSurfaceVariant: Color(0xFFB9C0E6),
    outline: Color(0xFF6F74B8),
    outlineVariant: Color(0xFF33377A),
    surfaceContainerHighest: AppColors.nightRaised,
  );

  ThemeData get lightTheme => _build(_lightScheme);
  ThemeData get darkTheme => _build(_darkScheme);

  ThemeData _build(ColorScheme scheme) {
    final isLight = scheme.brightness == Brightness.light;
    final textTheme = GoogleFonts.poppinsTextTheme(
      ThemeData(brightness: scheme.brightness).textTheme,
    ).apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface);

    final appBarBackground = isLight ? AppColors.indigo : AppColors.nightSurface;
    final appBarForeground = isLight ? Colors.white : AppColors.mist;
    final fieldFill = isLight ? Colors.white : AppColors.nightRaised;

    OutlineInputBorder fieldBorder(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: color, width: width),
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: isLight ? AppColors.mist : AppColors.night,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: appBarBackground,
        foregroundColor: appBarForeground,
        iconTheme: IconThemeData(color: appBarForeground),
        actionsIconTheme: IconThemeData(color: appBarForeground),
      ),
      cardTheme: CardThemeData(
        color: isLight ? Colors.white : AppColors.nightRaised,
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: fieldFill,
        border: fieldBorder(scheme.outlineVariant),
        enabledBorder: fieldBorder(scheme.outlineVariant),
        focusedBorder: fieldBorder(scheme.primary, 2),
        errorBorder: fieldBorder(scheme.error),
        focusedErrorBorder: fieldBorder(scheme.error, 2),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          selectedBackgroundColor: AppColors.indigo,
          selectedForegroundColor: Colors.white,
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 66,
        backgroundColor: scheme.surface,
        elevation: 3,
        indicatorColor: isLight ? AppColors.aqua : AppColors.indigo,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? (isLight ? AppColors.ink : Colors.white)
                : scheme.onSurfaceVariant,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isLight ? AppColors.ink : AppColors.mist,
        contentTextStyle: GoogleFonts.poppins(
          color: isLight ? Colors.white : AppColors.ink,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
