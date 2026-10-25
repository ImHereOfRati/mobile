import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iamhere/components/foundation.dart';

/// Applies the ImHere design system to the native app shell and auth flow.
class ImHereAppTheme {
  const ImHereAppTheme._();

  static final light = _create(Brightness.light);
  static final dark = _create(Brightness.dark);

  static ThemeData _create(Brightness brightness) {
    final base = ImHereTheme.create(brightness);
    final colors = brightness == Brightness.dark
        ? ImHereColors.dark
        : ImHereColors.light;
    final scheme = base.colorScheme.copyWith(
      primaryContainer: colors.actionSubtle,
      onPrimaryContainer: colors.action,
      onSurfaceVariant: colors.textMuted,
      surfaceContainerHighest: colors.surfaceSubtle,
      outline: colors.border,
    );

    return base.copyWith(
      colorScheme: scheme,
      appBarTheme: AppBarTheme(
        backgroundColor: colors.surface,
        foregroundColor: colors.text,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: brightness == Brightness.dark
              ? Brightness.light
              : Brightness.dark,
          statusBarBrightness: brightness,
          systemNavigationBarColor: colors.background,
          systemNavigationBarIconBrightness: brightness == Brightness.dark
              ? Brightness.light
              : Brightness.dark,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: colors.actionSubtle,
        elevation: 0,
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return ImHereType.style(
            ImHereTypeScale.t1,
            selected ? ImHereType.bold : ImHereType.medium,
            selected ? colors.action : colors.textMuted,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? colors.action : colors.textMuted,
            size: ImHereSpace.lg,
          );
        }),
      ),
      cardTheme: CardThemeData(
        color: colors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ImHereRadius.lg),
          side: BorderSide(color: colors.divider),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ImHereRadius.sheet),
          side: BorderSide(color: colors.divider),
        ),
        titleTextStyle: base.textTheme.titleMedium,
        contentTextStyle: base.textTheme.bodyMedium?.copyWith(
          color: colors.textMuted,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colors.action,
          foregroundColor: colors.onAction,
          minimumSize: const Size(44, 48),
          padding: const EdgeInsets.symmetric(
            horizontal: ImHereSpace.md,
            vertical: ImHereSpace.sm,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ImHereRadius.md),
          ),
          textStyle: base.textTheme.labelLarge,
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.text,
          minimumSize: const Size(44, 48),
          padding: const EdgeInsets.symmetric(
            horizontal: ImHereSpace.md,
            vertical: ImHereSpace.sm,
          ),
          side: BorderSide(color: colors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ImHereRadius.md),
          ),
          textStyle: base.textTheme.labelLarge,
        ),
      ),
    );
  }
}
