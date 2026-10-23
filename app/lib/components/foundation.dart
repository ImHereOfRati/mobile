import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Raw values have no UI meaning. Components use [ImHereColors] instead.
abstract final class ImHerePalette {
  static const blue50 = Color(0xFFEAF3FF);
  static const blue100 = Color(0xFFD4E7FF);
  static const blue300 = Color(0xFF80B8FF);
  static const blue500 = Color(0xFF0077FB);
  static const blue600 = Color(0xFF0067DB);
  static const blue700 = Color(0xFF0055B8);
  static const blue900 = Color(0xFF073A79);
  static const neutral0 = Color(0xFFFFFFFF);
  static const neutral50 = Color(0xFFF7F9FC);
  static const neutral100 = Color(0xFFEDF1F5);
  static const neutral200 = Color(0xFFE3E9EF);
  static const neutral300 = Color(0xFFC7D0DA);
  static const neutral500 = Color(0xFF667585);
  static const neutral700 = Color(0xFF354353);
  static const neutral800 = Color(0xFF1F2C3A);
  static const neutral900 = Color(0xFF152230);
  static const neutral1000 = Color(0xFF0D1723);
  static const red100 = Color(0xFFFFE7E4);
  static const red600 = Color(0xFFC92B24);
  static const green100 = Color(0xFFDFF5E9);
  static const green700 = Color(0xFF176C42);
  static const amber100 = Color(0xFFFFF1D6);
  static const amber700 = Color(0xFF835000);
}

@immutable
class ImHereColors extends ThemeExtension<ImHereColors> {
  const ImHereColors({
    required this.text,
    required this.textMuted,
    required this.background,
    required this.surface,
    required this.surfaceSubtle,
    required this.border,
    required this.divider,
    required this.action,
    required this.onAction,
    required this.actionSubtle,
    required this.error,
    required this.errorSubtle,
    required this.success,
    required this.successSubtle,
    required this.warning,
    required this.warningSubtle,
  });

  final Color text;
  final Color textMuted;
  final Color background;
  final Color surface;
  final Color surfaceSubtle;
  final Color border;
  final Color divider;
  final Color action;
  final Color onAction;
  final Color actionSubtle;
  final Color error;
  final Color errorSubtle;
  final Color success;
  final Color successSubtle;
  final Color warning;
  final Color warningSubtle;

  static const light = ImHereColors(
    text: ImHerePalette.neutral900,
    textMuted: ImHerePalette.neutral500,
    background: ImHerePalette.neutral0,
    surface: ImHerePalette.neutral0,
    surfaceSubtle: ImHerePalette.neutral50,
    border: ImHerePalette.neutral300,
    divider: ImHerePalette.neutral200,
    action: ImHerePalette.blue700,
    onAction: ImHerePalette.neutral0,
    actionSubtle: ImHerePalette.blue50,
    error: ImHerePalette.red600,
    errorSubtle: ImHerePalette.red100,
    success: ImHerePalette.green700,
    successSubtle: ImHerePalette.green100,
    warning: ImHerePalette.amber700,
    warningSubtle: ImHerePalette.amber100,
  );

  static const dark = ImHereColors(
    text: ImHerePalette.neutral0,
    textMuted: ImHerePalette.neutral300,
    background: ImHerePalette.neutral1000,
    surface: ImHerePalette.neutral900,
    surfaceSubtle: ImHerePalette.neutral800,
    border: ImHerePalette.neutral500,
    divider: ImHerePalette.neutral700,
    action: ImHerePalette.blue300,
    onAction: ImHerePalette.neutral1000,
    actionSubtle: ImHerePalette.blue900,
    error: Color(0xFFFF8E86),
    errorSubtle: Color(0xFF5B2222),
    success: Color(0xFF7ED7A3),
    successSubtle: Color(0xFF17472F),
    warning: Color(0xFFFFCA6A),
    warningSubtle: Color(0xFF584016),
  );

  static ImHereColors of(BuildContext context) =>
      Theme.of(context).extension<ImHereColors>() ??
      (Theme.of(context).brightness == Brightness.dark ? dark : light);

  @override
  ImHereColors copyWith({
    Color? text,
    Color? textMuted,
    Color? background,
    Color? surface,
    Color? surfaceSubtle,
    Color? border,
    Color? divider,
    Color? action,
    Color? onAction,
    Color? actionSubtle,
    Color? error,
    Color? errorSubtle,
    Color? success,
    Color? successSubtle,
    Color? warning,
    Color? warningSubtle,
  }) => ImHereColors(
    text: text ?? this.text,
    textMuted: textMuted ?? this.textMuted,
    background: background ?? this.background,
    surface: surface ?? this.surface,
    surfaceSubtle: surfaceSubtle ?? this.surfaceSubtle,
    border: border ?? this.border,
    divider: divider ?? this.divider,
    action: action ?? this.action,
    onAction: onAction ?? this.onAction,
    actionSubtle: actionSubtle ?? this.actionSubtle,
    error: error ?? this.error,
    errorSubtle: errorSubtle ?? this.errorSubtle,
    success: success ?? this.success,
    successSubtle: successSubtle ?? this.successSubtle,
    warning: warning ?? this.warning,
    warningSubtle: warningSubtle ?? this.warningSubtle,
  );

  @override
  ImHereColors lerp(ThemeExtension<ImHereColors>? other, double t) {
    if (other is! ImHereColors) return this;
    Color blend(Color a, Color b) => Color.lerp(a, b, t)!;
    return ImHereColors(
      text: blend(text, other.text),
      textMuted: blend(textMuted, other.textMuted),
      background: blend(background, other.background),
      surface: blend(surface, other.surface),
      surfaceSubtle: blend(surfaceSubtle, other.surfaceSubtle),
      border: blend(border, other.border),
      divider: blend(divider, other.divider),
      action: blend(action, other.action),
      onAction: blend(onAction, other.onAction),
      actionSubtle: blend(actionSubtle, other.actionSubtle),
      error: blend(error, other.error),
      errorSubtle: blend(errorSubtle, other.errorSubtle),
      success: blend(success, other.success),
      successSubtle: blend(successSubtle, other.successSubtle),
      warning: blend(warning, other.warning),
      warningSubtle: blend(warningSubtle, other.warningSubtle),
    );
  }
}

abstract final class ImHereSpace {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;

  /// Screen edge to content (SEED global-gutter).
  static const gutter = 16.0;

  /// Navigation bar to the title below it (SEED nav-to-title).
  static const navToTitle = 20.0;
}

abstract final class ImHereRadius {
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const sheet = 20.0;
  static const pill = 999.0;
}

abstract final class ImHereMotion {
  /// Micro motion for color changes and focus (SEED color-transition).
  static const color = Duration(milliseconds: 150);
  static const easing = Cubic(0.35, 0, 0.35, 1);

  /// Press feedback: the element shrinks by a fixed distance, not a ratio.
  static const pressed = Duration(milliseconds: 150);
  static const pressedCurve = Cubic(0, 0, 0.15, 1);

  /// Durations that collapse to zero when animations are turned off, either
  /// by the user's accessibility setting or by wrapping a subtree in
  /// `MediaQuery(disableAnimations: true)`.
  static Duration colorOf(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : color;

  static Duration pressedOf(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : pressed;
}

/// Sizes are authored against a 360 logical pixel Galaxy S26 viewport.
/// Components resolve them against the current viewport when they build.
class ImHereMetrics {
  const ImHereMetrics._(this.scale);

  final double scale;

  factory ImHereMetrics.of(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return ImHereMetrics._((width / 360).clamp(0.85, 1.2));
  }

  double resolve(double reference) => reference * scale;

  double get touchTarget => math.max(44, resolve(48));
}

abstract final class ImHereTheme {
  static ThemeData light = create(Brightness.light);
  static ThemeData dark = create(Brightness.dark);

  static ThemeData create(Brightness brightness) {
    final colors = brightness == Brightness.dark
        ? ImHereColors.dark
        : ImHereColors.light;
    // No fontFamily on purpose: text uses the platform's system font. Only
    // the logo (ImHereLogo) carries its own typeface.
    final base = ThemeData(brightness: brightness, useMaterial3: true);
    final textTheme = _textTheme(base.textTheme, colors);
    final radius = BorderRadius.circular(ImHereRadius.md);
    OutlineInputBorder outline(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: color, width: width),
        );
    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: colors.action,
        brightness: brightness,
        primary: colors.action,
        onPrimary: colors.onAction,
        surface: colors.surface,
        onSurface: colors.text,
        error: colors.error,
      ),
      scaffoldBackgroundColor: colors.background,
      extensions: [colors],
      textTheme: textTheme,
      splashFactory: NoSplash.splashFactory,
      splashColor: Colors.transparent,
      highlightColor: colors.surfaceSubtle,
      hoverColor: colors.surfaceSubtle,
      dividerTheme: DividerThemeData(
        color: colors.divider,
        thickness: 1,
        space: 1,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: colors.action),
      listTileTheme: ListTileThemeData(
        titleTextStyle: textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
        subtitleTextStyle: textTheme.bodyMedium?.copyWith(
          color: colors.textMuted,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.action,
          textStyle: textTheme.labelLarge,
          minimumSize: const Size(44, 44),
          shape: RoundedRectangleBorder(borderRadius: radius),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceSubtle,
        hintStyle: textTheme.bodyLarge?.copyWith(color: colors.textMuted),
        errorStyle: textTheme.bodySmall?.copyWith(color: colors.error),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: ImHereSpace.md,
          vertical: ImHereSpace.sm,
        ),
        border: outline(colors.border),
        enabledBorder: outline(colors.border),
        focusedBorder: outline(colors.action, 2),
        errorBorder: outline(colors.error),
        focusedErrorBorder: outline(colors.error, 2),
        disabledBorder: outline(colors.divider),
      ),
    );
  }

  /// Font sizes stay fixed: the system text scaler already honors user
  /// preference, so only spacing and shapes follow [ImHereMetrics].
  static TextTheme _textTheme(TextTheme base, ImHereColors colors) {
    TextStyle style(ImHereTypeScale t, FontWeight weight, [Color? color]) =>
        ImHereType.style(t, weight, color ?? colors.text);
    return base.copyWith(
      headlineLarge: style(ImHereTypeScale.t7, ImHereType.bold),
      headlineMedium: style(ImHereTypeScale.t6, ImHereType.bold),
      titleLarge: style(ImHereTypeScale.t6, ImHereType.bold),
      titleMedium: style(ImHereTypeScale.t5, ImHereType.bold),
      titleSmall: style(ImHereTypeScale.t4, ImHereType.bold),
      bodyLarge: style(ImHereTypeScale.t5, ImHereType.medium),
      bodyMedium: style(ImHereTypeScale.t4, ImHereType.medium),
      bodySmall: style(ImHereTypeScale.t3, ImHereType.medium, colors.textMuted),
      labelLarge: style(ImHereTypeScale.t5, ImHereType.bold),
      labelMedium: style(ImHereTypeScale.t3, ImHereType.bold),
    );
  }
}

/// SEED font-size / line-height pairs (px), capped at 20: nothing in the app
/// is set larger. Use a scale step with a weight instead of ad-hoc sizes.
enum ImHereTypeScale {
  t1(11, 15),
  t2(12, 16),
  t3(13, 18),
  t4(14, 19),
  t5(16, 22),
  t6(18, 24),
  t7(20, 27);

  const ImHereTypeScale(this.size, this.lineHeight);
  final double size;
  final double lineHeight;
}

/// The two weights the system uses: 500 for text, 700 for emphasis.
abstract final class ImHereType {
  static const medium = FontWeight.w500;
  static const bold = FontWeight.w700;

  static TextStyle style(ImHereTypeScale t, FontWeight weight, Color color) =>
      TextStyle(
        fontSize: t.size,
        height: t.lineHeight / t.size,
        fontWeight: weight,
        color: color,
      );
}
