import 'package:drill_deck/theme/app_colors.dart';
import 'package:drill_deck/theme/mono_typography.dart';
import 'package:drill_deck/theme/scenario_palette.dart';
import 'package:flutter/material.dart';

abstract final class AppTheme {
  static ThemeData get dark {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.action,
      brightness: Brightness.dark,
    ).copyWith(
      surface: AppColors.surface,
      surfaceContainerHighest: AppColors.surface2,
      surfaceContainerHigh: AppColors.surface2,
      onSurface: AppColors.text,
      onSurfaceVariant: AppColors.muted,
      outline: AppColors.line,
      outlineVariant: AppColors.faint,
      error: AppColors.danger,
      onError: AppColors.ink,
      secondary: AppColors.got,
      onSecondary: AppColors.ink,
      tertiary: AppColors.miss,
      onTertiary: AppColors.ink,
    );

    return ThemeData(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.ink,
      useMaterial3: true,
      fontFamily: 'system-ui',
      textTheme: const TextTheme().apply(
        bodyColor: AppColors.text,
        displayColor: AppColors.text,
      ),
      extensions: [
        ScenarioPalette.dark(),
        MonoTypography.dark(),
      ],
    );
  }
}
