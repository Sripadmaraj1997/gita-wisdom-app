/// ------------------------------------------------------------
/// SplashScreen
///
/// Purpose:
/// Calm launch moment before HomeScreen.
///
/// Responsibilities:
/// - Display the app's Krishna image/branding.
/// - Transition to Home once, without redirecting users away from a page they
///   already opened.
/// - Avoid auth/onboarding/network checks during launch.
///
/// Notes:
/// The app is offline-first. Splash must never wait on Firebase, cloud state, or
/// personalization setup; first launch should feel predictable and stable.
/// ------------------------------------------------------------
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../gita_common/gita_common.dart';

const _darkKrishnaBlue = Color(0xFF071E3D);
const _midnightNavy = Color(0xFF061A2E);
const _illuminatedGold = Color(0xFFD4AF37);
const _softGold = Color(0xFFE6C76A);
const _warmGoldGlow = Color(0xFFF4E7B2);
const _lightText = Color(0xFFFFF7E8);

void _splashDebugLog(String message) {
  assert(() {
    debugPrint(message);
    return true;
  }());
}

class SplashPageWidget extends StatefulWidget {
  const SplashPageWidget({super.key});

  static String routeName = 'SplashPage';
  static String routePath = '/';

  @override
  State<SplashPageWidget> createState() => _SplashPageWidgetState();
}

class _SplashPageWidgetState extends State<SplashPageWidget>
    with TickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final AnimationController _glowController;
  Timer? _navigationTimer;
  bool _hasResolvedInitialRoute = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..forward();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
      lowerBound: 0.72,
      upperBound: 1,
    )..repeat(reverse: true);
    _splashDebugLog('app init started');
    _splashDebugLog('Splash started');
    // Delay navigation until after the first frame so the custom splash is
    // visibly painted before the timed transition begins.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigationTimer = Timer(
        const Duration(milliseconds: 3800),
        _navigateAfterSplash,
      );
    });
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _fadeController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _navigateAfterSplash() {
    if (!mounted) {
      return;
    }
    if (_hasResolvedInitialRoute) {
      _splashDebugLog(
        'automatic redirect skipped: initial route already resolved',
      );
      return;
    }
    _hasResolvedInitialRoute = true;

    final router = GoRouter.of(context);
    final routeBeforeInit =
        router.routerDelegate.currentConfiguration.uri.toString();
    _splashDebugLog('route before init: $routeBeforeInit');
    if (routeBeforeInit != SplashPageWidget.routePath) {
      _splashDebugLog(
        'automatic redirect skipped: user already navigated to $routeBeforeInit',
      );
      return;
    }

    _splashDebugLog('automatic redirect reason: splash completed');
    context.go('/homePage');
    final routeAfterInit =
        router.routerDelegate.currentConfiguration.uri.toString();
    _splashDebugLog('route after init: $routeAfterInit');
    _splashDebugLog('app init completed');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _midnightNavy,
      body: FadeTransition(
        opacity: CurvedAnimation(
          parent: _fadeController,
          curve: Curves.easeOutCubic,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const _SplashFallbackBackground(),
            const _ReadabilityOverlay(),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxHeight < 700;
                  final titleSize = constraints.maxWidth < 380 ? 28.0 : 34.0;
                  final imageMaxHeight =
                      constraints.maxHeight * (compact ? 0.72 : 0.78);
                  final imageMaxWidth =
                      constraints.maxWidth * (compact ? 0.98 : 0.98);
                  return Padding(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      compact ? 10 : 16,
                      16,
                      compact ? 16 : 22,
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: Center(
                            child: _KrishnaSplashImage(
                              maxHeight: imageMaxHeight,
                              maxWidth: imageMaxWidth,
                              glowAnimation: _glowController,
                            ),
                          ),
                        ),
                        SizedBox(height: compact ? 10 : 14),
                        _SplashTextPanel(
                          titleSize: titleSize,
                          compact: compact,
                        ),
                        SizedBox(height: compact ? 12 : 16),
                        const _SplashProgress(),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KrishnaSplashImage extends StatelessWidget {
  const _KrishnaSplashImage({
    required this.maxHeight,
    required this.maxWidth,
    required this.glowAnimation,
  });

  final double maxHeight;
  final double maxWidth;
  final Animation<double> glowAnimation;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: maxHeight.clamp(320, 860).toDouble(),
        maxWidth: maxWidth.clamp(320, 860).toDouble(),
      ),
      child: AnimatedBuilder(
        animation: glowAnimation,
        builder: (context, child) {
          final glow = glowAnimation.value;
          return DecoratedBox(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: _warmGoldGlow.withValues(alpha: 0.12 * glow),
                  blurRadius: 82 * glow,
                  spreadRadius: 26 * glow,
                ),
                BoxShadow(
                  color: _illuminatedGold.withValues(alpha: 0.16 * glow),
                  blurRadius: 58 * glow,
                  spreadRadius: 11 * glow,
                ),
                BoxShadow(
                  color: _midnightNavy.withValues(alpha: 0.62),
                  blurRadius: 38,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: child,
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Image.asset(
            'assets/backgrounds/krishna_splash.png',
            fit: BoxFit.contain,
            alignment: Alignment.center,
            errorBuilder: (context, error, stackTrace) =>
                const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}

class _ReadabilityOverlay extends StatelessWidget {
  const _ReadabilityOverlay();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _midnightNavy.withValues(alpha: 0.48),
            _darkKrishnaBlue.withValues(alpha: 0.18),
            _midnightNavy.withValues(alpha: 0.58),
          ],
          stops: const [0, 0.48, 1],
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.18),
            radius: 0.82,
            colors: [
              _illuminatedGold.withValues(alpha: 0.18),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }
}

class _SplashTitle extends StatelessWidget {
  const _SplashTitle({required this.titleSize});

  final double titleSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Gita Wisdom',
          textAlign: TextAlign.center,
          style: gitaTitle(titleSize).copyWith(
            color: _warmGoldGlow,
            height: 1.06,
            shadows: [
              Shadow(
                color: _midnightNavy.withValues(alpha: 0.90),
                blurRadius: 18,
                offset: const Offset(0, 3),
              ),
              Shadow(
                color: _illuminatedGold.withValues(alpha: 0.28),
                blurRadius: 22,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Timeless Wisdom. Daily Peace.',
          textAlign: TextAlign.center,
          style: gitaBody(
            color: _lightText,
            size: 15,
            weight: FontWeight.w800,
          ).copyWith(
            shadows: [
              Shadow(
                color: _midnightNavy.withValues(alpha: 0.92),
                blurRadius: 18,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SplashTextPanel extends StatelessWidget {
  const _SplashTextPanel({
    required this.titleSize,
    required this.compact,
  });

  final double titleSize;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 500),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(18, compact ? 10 : 12, 18, 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _midnightNavy.withValues(alpha: 0.18),
              _midnightNavy.withValues(alpha: 0.38),
            ],
          ),
          border: Border.all(color: _warmGoldGlow.withValues(alpha: 0.10)),
          boxShadow: [
            BoxShadow(
              color: _midnightNavy.withValues(alpha: 0.30),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SplashTitle(titleSize: titleSize),
            const SizedBox(height: 10),
            _LoadingText(compact: compact),
          ],
        ),
      ),
    );
  }
}

class _LoadingText extends StatelessWidget {
  const _LoadingText({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Text(
      'Loading divine wisdom...',
      textAlign: TextAlign.center,
      style: gitaBody(
        color: _softGold,
        size: compact ? 12.5 : 14,
        weight: FontWeight.w800,
      ).copyWith(
        shadows: [
          Shadow(
            color: _midnightNavy.withValues(alpha: 0.96),
            blurRadius: 16,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }
}

class _SplashProgress extends StatelessWidget {
  const _SplashProgress();

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Container(
        height: 6,
        decoration: BoxDecoration(
          color: _midnightNavy.withValues(alpha: 0.62),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: _warmGoldGlow.withValues(alpha: 0.32)),
          boxShadow: [
            BoxShadow(
              color: _illuminatedGold.withValues(alpha: 0.28),
              blurRadius: 22,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: LinearProgressIndicator(
          backgroundColor: Colors.transparent,
          color: _illuminatedGold,
          minHeight: 6,
          borderRadius: BorderRadius.circular(100),
        ),
      ),
    );
  }
}

class _SplashFallbackBackground extends StatelessWidget {
  const _SplashFallbackBackground();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _darkKrishnaBlue,
            Color(0xFF0B2C5F),
            _midnightNavy,
          ],
        ),
      ),
    );
  }
}
