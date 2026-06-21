// Global design system for the offline Gita Wisdom MVP.
//
// The visual identity is quiet, warm, grounded, and timeless: deep blue for
// stillness, warm cream for reading, and soft gold as a restrained accent.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  const AppColors._();

  // Core palette. Keep gold as an accent rather than a page background; this
  // prevents bright overlays from reducing text contrast.
  static const deepNavy = Color(0xFF071E3D);
  static const navy = Color(0xFF061A2E);
  static const royalPurple = Color(0xFF253A5A);
  static const purpleInk = Color(0xFF102A4C);
  static const deepBrinjal = Color(0xFF061A2E);
  static const peacockTeal = Color(0xFF0B2C5F);
  static const peacockBlue = Color(0xFF0B2C5F);
  static const card = Color(0xFF061A2E);
  static const cardAlt = Color(0xFF0B2C5F);
  static const gold = Color(0xFFD4AF37);
  static const templeGold = Color(0xFFD4AF37);
  static const antiqueGold = Color(0xFFF4E7B2);
  static const softGold = Color(0xFFE6C76A);
  static const cream = Color(0xFFFFF8EE);
  static const softCream = Color(0xFFF7F1E5);
  static const darkText = Color(0xFF2B1F1A);
  static const secondaryText = Color(0xFFD8CCBE);
  static const saffron = Color(0xFFD4AF37);
  static const ivory = Color(0xFFFFF7E8);
  static const muted = Color(0xFFD8CCBE);
  static const line = Color(0x33D4AF37);
  static const sage = Color(0xFF0B2C5F);
  static const inputPlaceholder = Color(0xFF6F6258);
  static const secondaryDarkText = Color(0xFF6F6258);
}

class AppGradients {
  const AppGradients._();

  static const spiritualBackground = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.deepNavy,
      AppColors.peacockBlue,
      AppColors.navy,
      AppColors.purpleInk,
    ],
    stops: [0, 0.46, 0.78, 1],
  );

  static LinearGradient get premiumCard => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.card.withValues(alpha: 0.96),
          AppColors.cardAlt.withValues(alpha: 0.86),
          AppColors.navy.withValues(alpha: 0.92),
        ],
      );

  static LinearGradient get brinjalCard => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.deepBrinjal,
          AppColors.peacockBlue,
          AppColors.deepBrinjal,
        ],
        stops: [0, 0.58, 1],
      );

  static LinearGradient get divineGlow => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.antiqueGold.withValues(alpha: 0.38),
          AppColors.softGold.withValues(alpha: 0.28),
          AppColors.gold.withValues(alpha: 0.18),
          Colors.transparent,
        ],
      );

  static LinearGradient get goldAction => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.softGold,
          AppColors.antiqueGold,
          AppColors.softGold,
        ],
      );

  static LinearGradient get iconMedallion => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.gold,
          AppColors.softGold,
          AppColors.antiqueGold,
        ],
      );
}

class AppSpacing {
  const AppSpacing._();

  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
}

class AppRadius {
  const AppRadius._();

  static const sm = 16.0;
  static const md = 22.0;
  static const lg = 28.0;
  static const pill = 100.0;
}

class AppTextStyles {
  const AppTextStyles._();

  static TextStyle display({
    double size = 34,
    Color color = AppColors.gold,
  }) {
    return GoogleFonts.playfairDisplay(
      color: color,
      fontSize: size,
      fontWeight: FontWeight.w800,
      height: 1.14,
    );
  }

  static TextStyle title({
    double size = 24,
    Color color = AppColors.gold,
  }) {
    return GoogleFonts.playfairDisplay(
      color: color,
      fontSize: size,
      fontWeight: FontWeight.w700,
      height: 1.2,
    );
  }

  static TextStyle body({
    double size = 16,
    Color color = AppColors.muted,
    FontWeight weight = FontWeight.w500,
  }) {
    return GoogleFonts.inter(
      color: color,
      fontSize: size < 16 ? 16 : size,
      fontWeight: weight,
      height: 1.55,
    );
  }

  static TextStyle caption({
    double size = 12,
    Color color = AppColors.muted,
    FontWeight weight = FontWeight.w600,
  }) {
    return GoogleFonts.inter(
      color: color,
      fontSize: size,
      fontWeight: weight,
      height: 1.4,
    );
  }

  static TextStyle sanskrit(double size) {
    return GoogleFonts.notoSerifDevanagari(
      color: AppColors.antiqueGold,
      fontSize: size,
      fontWeight: FontWeight.w700,
      height: 1.72,
    );
  }

  static TextStyle transliteration({
    double size = 16,
    Color color = AppColors.muted,
  }) {
    return GoogleFonts.lora(
      color: color,
      fontSize: size,
      fontWeight: FontWeight.w500,
      fontStyle: FontStyle.italic,
      height: 1.62,
    );
  }
}

class AppShadows {
  const AppShadows._();

  static List<BoxShadow> get soft => [
        BoxShadow(
          color: AppColors.deepBrinjal.withValues(alpha: 0.20),
          blurRadius: 18,
          offset: const Offset(0, 10),
        ),
      ];

  static List<BoxShadow> get goldGlow => [
        BoxShadow(
          color: AppColors.deepBrinjal.withValues(alpha: 0.18),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: AppColors.gold.withValues(alpha: 0.06),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ];
}

class PremiumScaffold extends StatelessWidget {
  const PremiumScaffold({
    super.key,
    required this.child,
    this.bottomNavigation,
    this.optionalBackgroundLayer,
  });

  final Widget child;
  final Widget? bottomNavigation;
  final Widget? optionalBackgroundLayer;

  @override
  Widget build(BuildContext context) {
    // Every screen shares the same layered background and safe-area behavior.
    // Bottom navigation is injected here so tab screens do not duplicate shell
    // layout code.
    return Scaffold(
      backgroundColor: AppColors.deepNavy,
      body: SpiritualBackground(
        child: SafeArea(
          child: Stack(
            children: [
              if (optionalBackgroundLayer != null)
                Positioned.fill(child: optionalBackgroundLayer!),
              Column(
                children: [
                  Expanded(child: child),
                  if (bottomNavigation != null) bottomNavigation!,
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GoldenScaffold extends PremiumScaffold {
  const GoldenScaffold({
    super.key,
    required super.child,
    super.bottomNavigation,
    super.optionalBackgroundLayer,
  });
}

class GoldenBackground extends StatelessWidget {
  const GoldenBackground({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SpiritualBackground(child: child);
  }
}

class SpiritualBackground extends StatelessWidget {
  const SpiritualBackground({
    super.key,
    required this.child,
    this.overlayOpacity = 1,
  });

  static const assetPath = 'assets/backgrounds/back.png';

  final Widget child;
  final double overlayOpacity;

  @override
  Widget build(BuildContext context) {
    // The background image is decorative only. The gradient overlays guarantee
    // readable text even when the image asset changes or fails to load.
    return DecoratedBox(
      decoration:
          const BoxDecoration(gradient: AppGradients.spiritualBackground),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            assetPath,
            fit: BoxFit.cover,
            alignment: Alignment.center,
            errorBuilder: (context, error, stackTrace) {
              debugPrint('SpiritualBackground image failed to load: $error');
              return const SizedBox.expand();
            },
          ),
          const IgnorePointer(
            child: ColoredBox(color: Color(0xCC071E3D)),
          ),
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.deepNavy.withValues(alpha: 0.88 * overlayOpacity),
                    AppColors.peacockBlue
                        .withValues(alpha: 0.76 * overlayOpacity),
                    AppColors.navy.withValues(alpha: 0.86 * overlayOpacity),
                  ],
                  stops: const [0, 0.46, 1],
                ),
              ),
            ),
          ),
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.24, -0.42),
                  radius: 1.08,
                  colors: [
                    AppColors.gold.withValues(alpha: 0.18 * overlayOpacity),
                    AppColors.gold.withValues(alpha: 0.06 * overlayOpacity),
                    Colors.transparent,
                  ],
                  stops: const [0, 0.34, 1],
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class PremiumCard extends StatelessWidget {
  const PremiumCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(22),
    this.onTap,
    this.accent = false,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.lg);
    return PressableScale(
      enabled: onTap != null,
      onTap: onTap,
      borderRadius: radius,
      child: Container(
        width: double.infinity,
        padding: padding,
        decoration: BoxDecoration(
          color: null,
          gradient: accent
              ? AppGradients.premiumCard
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.card.withValues(alpha: 0.96),
                    AppColors.cardAlt.withValues(alpha: 0.86),
                    AppColors.navy.withValues(alpha: 0.92),
                  ],
                ),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: accent
                ? AppColors.gold.withValues(alpha: 0.26)
                : AppColors.gold.withValues(alpha: 0.16),
          ),
          boxShadow: AppShadows.soft,
        ),
        child: child,
      ),
    );
  }
}

class GoldButton extends StatelessWidget {
  const GoldButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    // Primary actions should feel steady, not flashy. Soft gold is reserved for
    // the action surface, with subdued shadowing and high contrast text.
    final enabled = onPressed != null && !isLoading;
    return PressableScale(
      enabled: enabled,
      onTap: enabled ? onPressed : null,
      scale: 0.975,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        constraints: const BoxConstraints(minHeight: 58),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        decoration: BoxDecoration(
          color: enabled ? null : AppColors.card.withValues(alpha: 0.72),
          gradient: enabled ? AppGradients.goldAction : null,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: enabled
                ? AppColors.antiqueGold.withValues(alpha: 0.42)
                : AppColors.gold.withValues(alpha: 0.24),
          ),
          boxShadow: enabled ? AppShadows.goldGlow : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: enabled ? AppColors.darkText : AppColors.secondaryText,
                ),
              )
            else
              Icon(
                icon ?? Icons.arrow_forward_rounded,
                color: enabled ? AppColors.darkText : AppColors.secondaryText,
              ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                isLoading ? 'Loading...' : label,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.body(
                  color: enabled ? AppColors.darkText : AppColors.secondaryText,
                  weight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PressableScale extends StatefulWidget {
  const PressableScale({
    super.key,
    required this.child,
    this.onTap,
    this.enabled = true,
    this.scale = 0.985,
    this.borderRadius,
  });

  final Widget child;
  final VoidCallback? onTap;
  final bool enabled;
  final double scale;
  final BorderRadius? borderRadius;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;

  bool get _interactive => widget.enabled && widget.onTap != null;

  void _setPressed(bool value) {
    if (!_interactive || _pressed == value) {
      return;
    }
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor:
          _interactive ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: _interactive
            ? () {
                HapticFeedback.selectionClick();
                widget.onTap?.call();
              }
            : null,
        child: AnimatedScale(
          scale: _pressed ? widget.scale : 1,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(borderRadius: widget.borderRadius),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class AnimatedGoldIconButton extends StatelessWidget {
  const AnimatedGoldIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.isBusy = false,
    this.tooltip,
    this.backgroundColor,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final bool isBusy;
  final String? tooltip;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final background = backgroundColor;
    final foregroundColor = background == null
        ? AppColors.darkText
        : background.computeLuminance() > 0.45
            ? AppColors.darkText
            : AppColors.ivory;
    final button = PressableScale(
      enabled: onTap != null && !isBusy,
      onTap: isBusy ? null : onTap,
      scale: 0.92,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: Container(
        width: 48,
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: backgroundColor ?? AppColors.cardAlt.withValues(alpha: 0.78),
          gradient: null,
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.18)),
          boxShadow: AppShadows.soft,
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: isBusy
              ? SizedBox(
                  key: const ValueKey('busy'),
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: foregroundColor,
                  ),
                )
              : Icon(
                  icon,
                  key: ValueKey(icon),
                  color: foregroundColor,
                  size: 20,
                ),
        ),
      ),
    );

    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.action,
    this.onActionTap,
  });

  final String title;
  final String? action;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: AppTextStyles.body(
            color: AppColors.ivory,
            size: 19,
            weight: FontWeight.w800,
          ),
        ),
        const Spacer(),
        if (action != null)
          TextButton(
            onPressed: onActionTap,
            child: Text(
              action!,
              style: AppTextStyles.body(color: AppColors.gold),
            ),
          ),
      ],
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: AppColors.deepBrinjal.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          _StateIcon(icon: icon),
          const SizedBox(height: AppSpacing.lg),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.title(
              size: 25,
              color: AppColors.deepBrinjal,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            body,
            textAlign: TextAlign.center,
            style: AppTextStyles.body(
              size: 15,
              color: AppColors.darkText.withValues(alpha: 0.76),
              weight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class LoadingState extends StatelessWidget {
  const LoadingState({
    super.key,
    this.message = 'Loading...',
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: const EdgeInsets.all(26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.softGold,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  message,
                  style: AppTextStyles.body(
                    color: AppColors.ivory,
                    weight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const PremiumSkeletonBlock(widthFactor: 0.72),
          const SizedBox(height: AppSpacing.sm),
          const PremiumSkeletonBlock(widthFactor: 0.92),
          const SizedBox(height: AppSpacing.sm),
          const PremiumSkeletonBlock(widthFactor: 0.54),
        ],
      ),
    );
  }
}

class PremiumSkeletonBlock extends StatefulWidget {
  const PremiumSkeletonBlock({
    super.key,
    this.height = 16,
    this.widthFactor = 1,
  });

  final double height;
  final double widthFactor;

  @override
  State<PremiumSkeletonBlock> createState() => _PremiumSkeletonBlockState();
}

class _PremiumSkeletonBlockState extends State<PremiumSkeletonBlock>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1250),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: widget.widthFactor,
      alignment: Alignment.centerLeft,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Container(
            height: widget.height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              gradient: LinearGradient(
                begin: Alignment(-1 + _controller.value * 2, 0),
                end: Alignment(0.2 + _controller.value * 2, 0),
                colors: [
                  AppColors.gold.withValues(alpha: 0.07),
                  AppColors.gold.withValues(alpha: 0.18),
                  AppColors.royalPurple.withValues(alpha: 0.08),
                ],
              ),
              border: Border.all(
                color: AppColors.gold.withValues(alpha: 0.08),
              ),
            ),
          );
        },
      ),
    );
  }
}

class PremiumEntrance extends StatelessWidget {
  const PremiumEntrance({
    super.key,
    required this.child,
    this.delay = Duration.zero,
  });

  final Widget child;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    return child
        .animate(delay: delay)
        .fadeIn(duration: 560.ms, curve: Curves.easeOutCubic)
        .slideY(
          begin: 0.025,
          end: 0,
          duration: 560.ms,
          curve: Curves.easeOutCubic,
        )
        .scale(
          begin: const Offset(0.995, 0.995),
          end: const Offset(1, 1),
          duration: 560.ms,
          curve: Curves.easeOutCubic,
        );
  }
}

class _StateIcon extends StatelessWidget {
  const _StateIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppGradients.iconMedallion,
        boxShadow: AppShadows.goldGlow,
      ),
      child: Icon(icon, color: AppColors.deepNavy, size: 29),
    );
  }
}
