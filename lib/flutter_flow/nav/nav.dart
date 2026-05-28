// Application routing layer.
//
// The app keeps FlutterFlow's generated navigation helpers, but the MVP route
// graph is intentionally small and explicit. Main tabs use bottom navigation;
// detail flows such as Verse Reader, Ask Gita, Saved, Reading Plans, and One
// Minute Wisdom are pushed as focused screens.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '/flutter_flow/flutter_flow_util.dart';

import '/index.dart';
import '/pages/gita_common/gita_common.dart';

export 'package:go_router/go_router.dart';
export 'serialization_util.dart';

const kTransitionInfoKey = '__transition_info__';

GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

class AppStateNotifier extends ChangeNotifier {
  AppStateNotifier._();

  static AppStateNotifier? _instance;
  static AppStateNotifier get instance => _instance ??= AppStateNotifier._();

  bool showSplashImage = true;

  void stopShowingSplashImage() {
    showSplashImage = false;
    notifyListeners();
  }
}

GoRouter createRouter(AppStateNotifier appStateNotifier) => GoRouter(
      initialLocation: '/',
      refreshListenable: appStateNotifier,
      navigatorKey: appNavigatorKey,
      errorBuilder: (context, state) {
        debugPrint(
          'Navigation error: no route for ${state.uri}. '
          'error=${state.error}',
        );
        return RouteErrorPage(
          location: state.uri.toString(),
        );
      },
      routes: [
        // Startup always enters the custom splash screen first. The splash
        // screen owns the timed transition to Home.
        FFRoute(
          name: '_initialize',
          path: '/',
          builder: (context, _) => const SplashPageWidget(),
        ),
        FFRoute(
          name: HomePageWidget.routeName,
          path: HomePageWidget.routePath,
          builder: (context, params) => const HomePageWidget(),
        ),
        FFRoute(
          name: SearchPageWidget.routeName,
          path: SearchPageWidget.routePath,
          builder: (context, params) => SearchPageWidget(
            initialQuery: params.getParam<String>('q', ParamType.String),
          ),
        ),
        FFRoute(
          name: ChaptersPageWidget.routeName,
          path: ChaptersPageWidget.routePath,
          builder: (context, params) => const ChaptersPageWidget(),
        ),
        FFRoute(
          name: VerseReaderPageWidget.routeName,
          path: VerseReaderPageWidget.routePath,
          builder: (context, params) => VerseReaderPageWidget(
            verseId: params.getParam<String>('verseId', ParamType.String),
          ),
        ),
        FFRoute(
          name: AskGitaPageWidget.routeName,
          path: AskGitaPageWidget.routePath,
          builder: (context, params) => AskGitaPageWidget(
            initialQuestion:
                params.getParam<String>('initialQuestion', ParamType.String),
            initialContext:
                params.getParam<String>('context', ParamType.String),
          ),
        ),
        FFRoute(
          name: JournalPageWidget.routeName,
          path: JournalPageWidget.routePath,
          builder: (context, params) => JournalPageWidget(
            prefill: params.getParam<String>('prefill', ParamType.String),
            chapter: params.getParam<String>('chapter', ParamType.String),
          ),
        ),
        FFRoute(
          name: SavedVersesPageWidget.routeName,
          path: SavedVersesPageWidget.routePath,
          builder: (context, params) => const SavedVersesPageWidget(),
        ),
        FFRoute(
          name: SettingsPageWidget.routeName,
          path: SettingsPageWidget.routePath,
          builder: (context, params) => const SettingsPageWidget(),
        ),
        FFRoute(
          name: TransformationPageWidget.routeName,
          path: TransformationPageWidget.routePath,
          builder: (context, params) => const TransformationPageWidget(),
        ),
        FFRoute(
          name: OneMinuteWisdomPageWidget.routeName,
          path: OneMinuteWisdomPageWidget.routePath,
          builder: (context, params) => const OneMinuteWisdomPageWidget(),
        ),
      ].map((r) => r.toRoute(appStateNotifier)).toList(),
    );

extension NavParamExtensions on Map<String, String?> {
  Map<String, String> get withoutNulls => Map.fromEntries(
        entries
            .where((e) => e.value != null)
            .map((e) => MapEntry(e.key, e.value!)),
      );
}

class RouteErrorPage extends StatelessWidget {
  const RouteErrorPage({
    super.key,
    required this.location,
  });

  final String location;

  @override
  Widget build(BuildContext context) {
    return GitaScaffold(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: PremiumCard(
              accent: true,
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const IconMedallion(
                    icon: Icons.route_rounded,
                    size: 62,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Page not found',
                    textAlign: TextAlign.center,
                    style: gitaTitle(30),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    location.isEmpty
                        ? 'This route is not registered.'
                        : 'No screen is registered for $location.',
                    textAlign: TextAlign.center,
                    style: gitaBody(size: 14),
                  ),
                  const SizedBox(height: 22),
                  GoldButton(
                    label: 'Return Home',
                    icon: Icons.home_rounded,
                    onPressed: () => context.go('/homePage'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

extension NavigationExtensions on BuildContext {
  void safePop() {
    // If there is only one route on the stack, navigate to the initial
    // page instead of popping.
    if (canPop()) {
      pop();
    } else {
      go('/');
    }
  }
}

extension _GoRouterStateExtensions on GoRouterState {
  Map<String, dynamic> get extraMap =>
      extra != null ? extra as Map<String, dynamic> : {};
  Map<String, dynamic> get allParams => <String, dynamic>{}
    ..addAll(pathParameters)
    ..addAll(uri.queryParameters)
    ..addAll(extraMap);
  TransitionInfo get transitionInfo => extraMap.containsKey(kTransitionInfoKey)
      ? extraMap[kTransitionInfoKey] as TransitionInfo
      : TransitionInfo.appDefault();
}

class FFParameters {
  FFParameters(this.state, [this.asyncParams = const {}]);

  final GoRouterState state;
  final Map<String, Future<dynamic> Function(String)> asyncParams;

  Map<String, dynamic> futureParamValues = {};

  // Parameters are empty if the params map is empty or if the only parameter
  // present is the special extra parameter reserved for the transition info.
  bool get isEmpty =>
      state.allParams.isEmpty ||
      (state.allParams.length == 1 &&
          state.extraMap.containsKey(kTransitionInfoKey));
  bool isAsyncParam(MapEntry<String, dynamic> param) =>
      asyncParams.containsKey(param.key) && param.value is String;
  bool get hasFutures => state.allParams.entries.any(isAsyncParam);
  Future<bool> completeFutures() => Future.wait(
        state.allParams.entries.where(isAsyncParam).map(
          (param) async {
            final doc = await asyncParams[param.key]!(param.value)
                .onError((_, __) => null);
            if (doc != null) {
              futureParamValues[param.key] = doc;
              return true;
            }
            return false;
          },
        ),
      ).onError((_, __) => [false]).then((v) => v.every((e) => e));

  dynamic getParam<T>(
    String paramName,
    ParamType type, {
    bool isList = false,
  }) {
    if (futureParamValues.containsKey(paramName)) {
      return futureParamValues[paramName];
    }
    if (!state.allParams.containsKey(paramName)) {
      return null;
    }
    final param = state.allParams[paramName];
    // Got parameter from `extras`, so just directly return it.
    if (param is! String) {
      return param;
    }
    // Return serialized value.
    return deserializeParam<T>(
      param,
      type,
      isList,
    );
  }
}

class FFRoute {
  const FFRoute({
    required this.name,
    required this.path,
    required this.builder,
    this.requireAuth = false,
    this.asyncParams = const {},
    this.routes = const [],
  });

  final String name;
  final String path;
  final bool requireAuth;
  final Map<String, Future<dynamic> Function(String)> asyncParams;
  final Widget Function(BuildContext, FFParameters) builder;
  final List<GoRoute> routes;

  GoRoute toRoute(AppStateNotifier appStateNotifier) => GoRoute(
        name: name,
        path: path,
        pageBuilder: (context, state) {
          fixStatusBarOniOS16AndBelow(context);
          final ffParams = FFParameters(state, asyncParams);
          final page = ffParams.hasFutures
              ? FutureBuilder(
                  future: ffParams.completeFutures(),
                  builder: (context, _) => builder(context, ffParams),
                )
              : builder(context, ffParams);
          final child = page;

          final transitionInfo = state.transitionInfo;
          return transitionInfo.hasTransition
              ? CustomTransitionPage(
                  key: state.pageKey,
                  name: state.name,
                  child: child,
                  transitionDuration: transitionInfo.duration,
                  reverseTransitionDuration: const Duration(milliseconds: 220),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                    final curved = CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                      reverseCurve: Curves.easeInCubic,
                    );
                    final secondaryCurved = CurvedAnimation(
                      parent: secondaryAnimation,
                      curve: Curves.easeOutCubic,
                    );
                    return FadeTransition(
                      opacity: Tween<double>(begin: 0, end: 1).animate(curved),
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.04, 0.018),
                          end: Offset.zero,
                        ).animate(curved),
                        child: ScaleTransition(
                          scale: Tween<double>(begin: 0.985, end: 1)
                              .animate(curved),
                          child: FadeTransition(
                            opacity: Tween<double>(begin: 1, end: 0.92)
                                .animate(secondaryCurved),
                            child: child,
                          ),
                        ),
                      ),
                    );
                  },
                )
              : MaterialPage(
                  key: state.pageKey, name: state.name, child: child);
        },
        routes: routes,
      );
}

class TransitionInfo {
  const TransitionInfo({
    required this.hasTransition,
    this.duration = const Duration(milliseconds: 300),
    this.alignment,
  });

  final bool hasTransition;
  final Duration duration;
  final Alignment? alignment;

  static TransitionInfo appDefault() => const TransitionInfo(
        hasTransition: true,
        duration: Duration(milliseconds: 320),
      );
}

class RootPageContext {
  const RootPageContext(this.isRootPage, [this.errorRoute]);
  final bool isRootPage;
  final String? errorRoute;

  static bool isInactiveRootPage(BuildContext context) {
    final rootPageContext = context.read<RootPageContext?>();
    final isRootPage = rootPageContext?.isRootPage ?? false;
    final location = GoRouterState.of(context).uri.toString();
    return isRootPage &&
        location != '/' &&
        location != rootPageContext?.errorRoute;
  }

  static Widget wrap(Widget child, {String? errorRoute}) => Provider.value(
        value: RootPageContext(true, errorRoute),
        child: child,
      );
}

extension GoRouterLocationExtension on GoRouter {
  String getCurrentLocation() {
    final RouteMatch lastMatch = routerDelegate.currentConfiguration.last;
    final RouteMatchList matchList = lastMatch is ImperativeRouteMatch
        ? lastMatch.matches
        : routerDelegate.currentConfiguration;
    return matchList.uri.toString();
  }
}
