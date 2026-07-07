import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Central playful color palette shared across Splash / Home / Game screens.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF3D7BFF);
  static const Color primaryDark = Color(0xFF1E4FCC);
  static const Color accent = Color(0xFFFF8A3D);
  static const Color success = Color(0xFF2ECC71);

  static const List<Color> splashGradient = [
    Color(0xFF4F8CFF),
    Color(0xFF3D7BFF),
    Color(0xFF2450C9),
  ];

  static const List<Color> homeBackground = [
    Color(0xFFEAF2FF),
    Color(0xFFFFFFFF),
  ];

  static const Color gameBackground = Color(0xFF0D1424);

  static const Color cardLocked = Color(0xFFE3E7ED);
  static const List<Color> cardCompleted = [
    Color(0xFFD4F7DE),
    Color(0xFFEFFFF3),
  ];
  static const List<Color> cardCurrent = [
    Color(0xFF5B9BFF),
    Color(0xFFA7C7FF),
  ];
  static const List<Color> cardUpcoming = [
    Color(0xFFEAF2FF),
    Color(0xFFFFFFFF),
  ];
}

/// Central playful typography shared across screens.
class AppTextStyles {
  AppTextStyles._();

  static TextStyle heading({
    double fontSize = 26,
    Color color = Colors.blueGrey,
    FontWeight weight = FontWeight.w700,
  }) =>
      GoogleFonts.baloo2(
        fontSize: fontSize,
        fontWeight: weight,
        color: color,
      );

  static TextStyle body({
    double fontSize = 14,
    Color color = Colors.black87,
    FontWeight weight = FontWeight.w500,
  }) =>
      GoogleFonts.nunito(
        fontSize: fontSize,
        fontWeight: weight,
        color: color,
      );

  static TextTheme textTheme(TextTheme base) =>
      GoogleFonts.nunitoTextTheme(base).copyWith(
        displayLarge: GoogleFonts.baloo2(textStyle: base.displayLarge),
        displayMedium: GoogleFonts.baloo2(textStyle: base.displayMedium),
        displaySmall: GoogleFonts.baloo2(textStyle: base.displaySmall),
        headlineLarge: GoogleFonts.baloo2(textStyle: base.headlineLarge),
        headlineMedium: GoogleFonts.baloo2(textStyle: base.headlineMedium),
        headlineSmall: GoogleFonts.baloo2(textStyle: base.headlineSmall),
        titleLarge: GoogleFonts.baloo2(textStyle: base.titleLarge),
      );
}

class AppTheme {
  AppTheme._();

  static ThemeData get themeData {
    final base = ThemeData(
      primarySwatch: Colors.blue,
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
      ),
    );
    return base.copyWith(
      textTheme: AppTextStyles.textTheme(base.textTheme),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _FadeSlidePageTransitionsBuilder(),
          TargetPlatform.iOS: _FadeSlidePageTransitionsBuilder(),
          TargetPlatform.macOS: _FadeSlidePageTransitionsBuilder(),
          TargetPlatform.windows: _FadeSlidePageTransitionsBuilder(),
          TargetPlatform.linux: _FadeSlidePageTransitionsBuilder(),
        },
      ),
    );
  }
}

/// Smooth fade + slide-up transition used app-wide instead of the
/// default platform push transition.
class _FadeSlidePageTransitionsBuilder extends PageTransitionsBuilder {
  const _FadeSlidePageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.04),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}
