/// ------------------------------------------------------------
/// AppEntryPoint
///
/// Purpose:
/// Bootstrap Gita Wisdom and configure app-wide routing/theme setup.
///
/// Architecture:
/// Gita Wisdom is intentionally offline-first. Scripture, reflections, saved
/// verses, journal entries, reading preferences, journey progress, and local
/// personalization signals live on device through bundled JSON and
/// SharedPreferences-backed services.
///
/// Notes:
/// There is no Firebase, login, cloud sync, or OpenAI startup dependency. Launch
/// should stay fast, predictable, and available without network access.
///
/// TODO(cloud-sync): If accounts are introduced later, keep offline startup as
/// the baseline and sync after the app is already usable.
/// ------------------------------------------------------------
library;

import 'dart:async';

import 'package:flutter/material.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import 'flutter_flow/flutter_flow_util.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  assert(() {
    debugPrint('App started');
    return true;
  }());

  // Keep web URLs clean and route-driven. The initial route is the custom
  // SplashScreen, which transitions directly into Home.
  GoRouter.optionURLReflectsImperativeAPIs = true;
  usePathUrlStrategy();

  unawaited(FlutterFlowTheme.initialize());

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  State<MyApp> createState() => _MyAppState();

  // ignore: library_private_types_in_public_api
  static _MyAppState of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>()!;
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = FlutterFlowTheme.themeMode;

  late AppStateNotifier _appStateNotifier;
  late GoRouter _router;
  String getRoute([RouteMatch? routeMatch]) {
    final RouteMatch lastMatch =
        routeMatch ?? _router.routerDelegate.currentConfiguration.last;
    final RouteMatchList matchList = lastMatch is ImperativeRouteMatch
        ? lastMatch.matches
        : _router.routerDelegate.currentConfiguration;
    return matchList.uri.path;
  }

  List<String> getRouteStack() =>
      _router.routerDelegate.currentConfiguration.matches
          .map((e) => getRoute(e))
          .toList();
  @override
  void initState() {
    super.initState();

    // AppStateNotifier is retained from the FlutterFlow shell, but routing is
    // now simple: Splash -> Home, with the rest of the MVP behind GoRouter.
    _appStateNotifier = AppStateNotifier.instance;
    _router = createRouter(_appStateNotifier);
  }

  void setThemeMode(ThemeMode mode) => safeSetState(() {
        _themeMode = mode;
        FlutterFlowTheme.saveThemeMode(mode);
      });

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Gita Wisdom',
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en', '')],
      theme: _premiumTheme(Brightness.light),
      darkTheme: _premiumTheme(Brightness.dark),
      themeMode: _themeMode,
      routerConfig: _router,
    );
  }
}

ThemeData _premiumTheme(Brightness brightness) {
  // Central Material theme wrapper. Most custom visual styling lives in
  // theme/app_theme.dart and gita_common.dart so screens can stay declarative.
  return ThemeData(
    brightness: brightness,
    useMaterial3: false,
    scaffoldBackgroundColor: AppColors.deepNavy,
    primaryColor: AppColors.gold,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.gold,
      brightness: brightness,
      primary: AppColors.gold,
      secondary: AppColors.saffron,
      surface: AppColors.card,
      onPrimary: AppColors.deepNavy,
      onSecondary: AppColors.deepNavy,
      onSurface: AppColors.ivory,
    ),
    textTheme: TextTheme(
      displayLarge: AppTextStyles.display(size: 34),
      titleLarge: AppTextStyles.title(size: 24),
      bodyMedium: AppTextStyles.body(color: AppColors.ivory),
      bodySmall: AppTextStyles.caption(),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.cream,
      labelStyle: AppTextStyles.body(
        color: AppColors.darkText,
        weight: FontWeight.w700,
      ),
      hintStyle: AppTextStyles.body(
        color: const Color(0xFF6F6258),
        weight: FontWeight.w600,
      ),
      prefixIconColor: AppColors.darkText,
      suffixIconColor: AppColors.darkText,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.gold),
      ),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: AppColors.deepNavy,
      selectionColor: AppColors.gold.withValues(alpha: 0.28),
      selectionHandleColor: AppColors.gold,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.gold,
        foregroundColor: AppColors.darkText,
        disabledBackgroundColor: AppColors.card,
        disabledForegroundColor: AppColors.secondaryText,
        minimumSize: const Size(48, 50),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
        textStyle: AppTextStyles.body(
          color: AppColors.darkText,
          weight: FontWeight.w800,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.softGold,
        minimumSize: const Size(48, 44),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        textStyle: AppTextStyles.body(
          color: AppColors.softGold,
          weight: FontWeight.w800,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.ivory,
        side: const BorderSide(color: AppColors.gold, width: 1.2),
        minimumSize: const Size(48, 50),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        textStyle: AppTextStyles.body(
          color: AppColors.ivory,
          weight: FontWeight.w800,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppColors.gold
            : AppColors.muted,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppColors.saffron.withValues(alpha: 0.42)
            : AppColors.line,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.card,
      contentTextStyle: AppTextStyles.body(color: AppColors.ivory),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
    ),
  );
}
