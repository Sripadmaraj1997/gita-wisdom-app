// Shared UI primitives for Gita Wisdom screens.
//
// This file bridges the app-specific design system in theme/app_theme.dart with
// screen-level widgets. Keep reusable visual components here so individual
// pages focus on product flow rather than repeated styling.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart' as design;

const kNavy = design.AppColors.deepNavy;
const kNavy2 = design.AppColors.navy;
const kCard = design.AppColors.card;
const kCard2 = design.AppColors.cardAlt;
const kGold = design.AppColors.gold;
const kAntiqueGold = design.AppColors.antiqueGold;
const kSoftGold = design.AppColors.softGold;
const kCream = design.AppColors.cream;
const kDarkText = design.AppColors.darkText;
const kSaffron = design.AppColors.saffron;
const kText = design.AppColors.ivory;
const kMuted = design.AppColors.muted;
const kLine = design.AppColors.line;
const kRoyalPurple = design.AppColors.royalPurple;
const kDeepBrinjal = design.AppColors.deepBrinjal;
const kPeacockTeal = design.AppColors.peacockTeal;
const kPeacockBlue = design.AppColors.peacockBlue;

const kBottomNavigationBarHeight = 84.0;
const kFixedBottomControlsHeight = 96.0;

double gitaBottomNavScrollPadding(BuildContext context) =>
    kBottomNavigationBarHeight + MediaQuery.of(context).viewPadding.bottom + 24;

double gitaFixedControlsScrollPadding(
  BuildContext context, {
  double controlsHeight = kFixedBottomControlsHeight,
}) =>
    controlsHeight + MediaQuery.of(context).viewPadding.bottom + 24;

class GitaChapter {
  const GitaChapter(
      this.number, this.title, this.englishTitle, this.verses, this.theme);

  final String number;
  final String title;
  final String englishTitle;
  final int verses;
  final String theme;
}

class GitaVerse {
  const GitaVerse({
    required this.ref,
    required this.sanskrit,
    required this.english,
    required this.note,
  });

  final String ref;
  final String sanskrit;
  final String english;
  final String note;
}

const chapters = [
  GitaChapter('01', 'Arjuna Vishada Yoga', 'Arjuna\'s Despair', 47, 'Dharma'),
  GitaChapter('02', 'Sankhya Yoga', 'Knowledge of the Self', 72, 'Wisdom'),
  GitaChapter('03', 'Karma Yoga', 'The Yoga of Action', 43, 'Action'),
  GitaChapter('04', 'Jnana Karma Yoga', 'Wisdom in Action', 42, 'Sacrifice'),
  GitaChapter('05', 'Karma Sannyasa Yoga', 'Renunciation', 29, 'Peace'),
  GitaChapter('06', 'Dhyana Yoga', 'Meditation', 47, 'Mind'),
  GitaChapter('07', 'Jnana Vijnana Yoga', 'Realization', 30, 'Truth'),
  GitaChapter('08', 'Akshara Brahma Yoga', 'The Imperishable', 28, 'Memory'),
  GitaChapter('09', 'Raja Vidya Yoga', 'Royal Knowledge', 34, 'Devotion'),
  GitaChapter('10', 'Vibhuti Yoga', 'Divine Glories', 42, 'Wonder'),
  GitaChapter('11', 'Vishvarupa Darshana Yoga', 'Universal Form', 55, 'Vision'),
  GitaChapter('12', 'Bhakti Yoga', 'Devotion', 20, 'Love'),
  GitaChapter('13', 'Kshetra Yoga', 'Field and Knower', 35, 'Awareness'),
  GitaChapter('14', 'Gunatraya Yoga', 'The Three Gunas', 27, 'Nature'),
  GitaChapter('15', 'Purushottama Yoga', 'The Supreme Person', 20, 'Reality'),
  GitaChapter('16', 'Daivasura Yoga', 'Divine Qualities', 24, 'Character'),
  GitaChapter('17', 'Shraddhatraya Yoga', 'Threefold Faith', 28, 'Faith'),
  GitaChapter('18', 'Moksha Sannyasa Yoga', 'Liberation', 78, 'Freedom'),
];

const dailyVerse = GitaVerse(
  ref: 'Bhagavad Gita 2.47',
  sanskrit: 'कर्मण्येवाधिकारस्ते मा फलेषु कदाचन।',
  english: 'You have a right to action alone, never to its fruits.',
  note: 'Act with devotion and clarity, releasing attachment to outcomes.',
);

const savedVerses = [
  dailyVerse,
  GitaVerse(
    ref: 'Bhagavad Gita 6.5',
    sanskrit: 'उद्धरेदात्मनात्मानं नात्मानमवसादयेत्।',
    english: 'Lift yourself by yourself; do not degrade yourself.',
    note: 'The disciplined mind becomes a friend on the spiritual path.',
  ),
  GitaVerse(
    ref: 'Bhagavad Gita 18.66',
    sanskrit: 'सर्वधर्मान्परित्यज्य मामेकं शरणं व्रज।',
    english: 'Take refuge in Me alone.',
    note: 'Surrender is complete trust in the highest truth.',
  ),
];

TextStyle gitaTitle(double size) => design.AppTextStyles.title(size: size);

TextStyle gitaBody({
  double size = 16,
  Color color = kMuted,
  FontWeight weight = FontWeight.w500,
}) =>
    design.AppTextStyles.body(
      size: size < 16 ? 16 : size,
      color: color,
      weight: weight,
    );

TextStyle gitaSanskrit(double size) => design.AppTextStyles.sanskrit(size);

TextStyle gitaTransliteration({
  double size = 16,
  Color color = kMuted,
}) =>
    design.AppTextStyles.transliteration(size: size, color: color);

class GitaScaffold extends StatelessWidget {
  const GitaScaffold({
    super.key,
    required this.child,
    this.bottomNavIndex,
  });

  final Widget child;
  final int? bottomNavIndex;

  @override
  Widget build(BuildContext context) {
    // Constraining content width keeps web/tablet layouts readable while still
    // allowing mobile screens to use the full available width.
    return design.PremiumScaffold(
      bottomNavigation: bottomNavIndex == null
          ? null
          : SpiritualBottomNav(index: bottomNavIndex!),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: SizedBox(width: double.infinity, child: child),
        ),
      ),
    );
  }
}

class GitaBottomNav extends StatelessWidget {
  const GitaBottomNav({super.key, required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    // Five-tab MVP navigation. Detail screens omit bottomNavIndex so users stay
    // focused on reading, saving, or journaling flows.
    final items = [
      (
        'Home',
        Icons.spa_outlined,
        Icons.spa,
        '/homePage',
      ),
      (
        'Read',
        Icons.menu_book_outlined,
        Icons.menu_book,
        '/chaptersPage',
      ),
      (
        'Search',
        Icons.search_rounded,
        Icons.travel_explore_rounded,
        '/searchPage',
      ),
      (
        'Journal',
        Icons.history_edu_outlined,
        Icons.history_edu_rounded,
        '/journalPage',
      ),
      (
        'Settings',
        Icons.settings_outlined,
        Icons.settings_rounded,
        '/settingsPage',
      ),
    ];
    return Container(
      height: 84,
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: kGold.withValues(alpha: 0.28)),
        boxShadow: [
          BoxShadow(
            color: kGold.withValues(alpha: 0.22),
            blurRadius: 28,
            offset: const Offset(0, -8),
          ),
          BoxShadow(
            color: kRoyalPurple.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: BottomNavigationBar(
        currentIndex: index,
        onTap: (itemIndex) => context.go(items[itemIndex].$4),
        type: BottomNavigationBarType.fixed,
        backgroundColor: kCard,
        elevation: 0,
        selectedItemColor: kSoftGold,
        unselectedItemColor: kMuted,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
        items: [
          for (final item in items)
            BottomNavigationBarItem(
              icon: Icon(item.$2),
              activeIcon: Icon(item.$3),
              label: item.$1,
            ),
        ],
      ),
    );
  }
}

class SpiritualBottomNav extends GitaBottomNav {
  const SpiritualBottomNav({super.key, required super.index});
}

class PremiumCard extends StatelessWidget {
  const PremiumCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.onTap,
    this.accent = false,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return design.PremiumCard(
      padding: padding,
      onTap: onTap,
      accent: accent,
      child: child,
    );
  }
}

class PurpleVerseCard extends StatelessWidget {
  const PurpleVerseCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.onTap,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      enabled: onTap != null,
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: double.infinity,
        padding: padding,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [kDeepBrinjal, kRoyalPurple, kDeepBrinjal],
          ),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: kGold.withValues(alpha: 0.48)),
          boxShadow: [
            BoxShadow(
              color: kGold.withValues(alpha: 0.28),
              blurRadius: 34,
              offset: const Offset(0, 16),
            ),
            BoxShadow(
              color: kDeepBrinjal.withValues(alpha: 0.20),
              blurRadius: 28,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

class ChapterListCard extends StatelessWidget {
  const ChapterListCard({
    super.key,
    required this.chapterNumber,
    required this.title,
    required this.subtitle,
    required this.meta,
    this.onTap,
    this.actions,
  });

  final int chapterNumber;
  final String title;
  final String subtitle;
  final String meta;
  final VoidCallback? onTap;
  final Widget? actions;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      onTap: onTap,
      padding: const EdgeInsets.all(22),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(colors: [kGold, kSoftGold]),
              border: Border.all(color: kAntiqueGold.withValues(alpha: 0.70)),
              boxShadow: [
                BoxShadow(
                  color: kGold.withValues(alpha: 0.24),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Text(
              chapterNumber.toString(),
              style: gitaBody(color: kDeepBrinjal, weight: FontWeight.w900),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: gitaBody(color: kText, weight: FontWeight.w900),
                ),
                const SizedBox(height: 7),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: gitaBody(color: kMuted),
                ),
                const SizedBox(height: 10),
                Text(
                  meta,
                  style: gitaBody(
                    size: 12,
                    color: kGold,
                    weight: FontWeight.w800,
                  ),
                ),
                if (actions != null) ...[
                  const SizedBox(height: 14),
                  actions!,
                ],
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: kMuted),
        ],
      ),
    );
  }
}

class AccentPill extends StatelessWidget {
  const AccentPill(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: kAntiqueGold.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: kGold.withValues(alpha: 0.24)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final label = Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: gitaBody(
              size: 12,
              color: kText,
              weight: FontWeight.w800,
            ),
          );
          if (constraints.maxWidth.isFinite) {
            return Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                const Icon(Icons.spa_rounded, size: 12, color: kSoftGold),
                const SizedBox(width: 5),
                Expanded(child: label),
              ],
            );
          }
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.spa_rounded, size: 12, color: kSoftGold),
              const SizedBox(width: 5),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 86),
                child: label,
              ),
            ],
          );
        },
      ),
    );
  }
}

class IconMedallion extends StatelessWidget {
  const IconMedallion({
    super.key,
    required this.icon,
    this.size = 44,
    this.backgroundColor = kSaffron,
    this.iconColor = kDeepBrinjal,
  });

  final IconData icon;
  final double size;
  final Color backgroundColor;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            backgroundColor,
            backgroundColor == kSaffron ? kGold : backgroundColor,
            backgroundColor == kSaffron ? kSoftGold : backgroundColor,
          ],
        ),
        border: Border.all(color: kAntiqueGold.withValues(alpha: 0.44)),
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withValues(alpha: 0.16),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Icon(icon, color: iconColor, size: size * 0.52),
    );
  }
}

class SpiritualIconPlaceholder extends StatelessWidget {
  const SpiritualIconPlaceholder({
    super.key,
    required this.icon,
    this.label,
    this.size = 104,
    this.futureAssetPath,
  });

  final IconData icon;
  final String? label;
  final double size;
  final String? futureAssetPath;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label ?? 'Spiritual icon',
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [kGold, kSoftGold, kAntiqueGold],
          ),
          border: Border.all(color: kGold.withValues(alpha: 0.24), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: kGold.withValues(alpha: 0.16),
              blurRadius: 30,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.music_note_rounded,
              color: kDeepBrinjal.withValues(alpha: 0.14),
              size: size * 0.72,
            ),
            if (futureAssetPath != null)
              ClipOval(
                child: Image.asset(
                  futureAssetPath!,
                  width: size * 0.72,
                  height: size * 0.72,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Icon(icon, color: kDeepBrinjal, size: size * 0.48),
                ),
              )
            else
              Icon(icon, color: kDeepBrinjal, size: size * 0.48),
          ],
        ),
      ),
    );
  }
}

class KrishnaIlluminatedMark extends StatelessWidget {
  const KrishnaIlluminatedMark({
    super.key,
    this.size = 150,
  });

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * 1.08,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  kAntiqueGold.withValues(alpha: 0.76),
                  kGold.withValues(alpha: 0.30),
                  kRoyalPurple.withValues(alpha: 0.10),
                  Colors.transparent,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: kGold.withValues(alpha: 0.20),
                  blurRadius: 34,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
          ),
          Positioned(
            top: size * 0.04,
            right: size * 0.08,
            child: Icon(
              Icons.spa_rounded,
              size: size * 0.44,
              color: kPeacockBlue.withValues(alpha: 0.78),
            ),
          ),
          Positioned(
            bottom: size * 0.30,
            child: Icon(
              Icons.music_note_rounded,
              size: size * 0.76,
              color: kGold.withValues(alpha: 0.78),
            ),
          ),
        ],
      ),
    );
  }
}

class LoadingStateCard extends StatelessWidget {
  const LoadingStateCard({
    super.key,
    this.message = 'Loading...',
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return design.LoadingState(message: message);
  }
}

class EmptyStateCard extends StatelessWidget {
  const EmptyStateCard({
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
    return design.EmptyState(
      icon: icon,
      title: title,
      body: body,
    );
  }
}

class ErrorStateCard extends StatelessWidget {
  const ErrorStateCard({
    super.key,
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      child: Row(
        children: [
          const IconMedallion(
            icon: Icons.error_outline_rounded,
            size: 42,
            backgroundColor: kCard2,
            iconColor: kGold,
          ),
          const SizedBox(width: 14),
          Expanded(child: Text(message, style: gitaBody(color: kText))),
        ],
      ),
    );
  }
}

class AnimatedEntrance extends StatelessWidget {
  const AnimatedEntrance({
    super.key,
    required this.child,
    this.delay = Duration.zero,
  });

  final Widget child;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    return design.PremiumEntrance(delay: delay, child: child);
  }
}

class PressableScale extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return design.PressableScale(
      enabled: enabled,
      onTap: onTap,
      scale: scale,
      borderRadius: borderRadius,
      child: child,
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
    return design.AnimatedGoldIconButton(
      icon: icon,
      onTap: onTap,
      isBusy: isBusy,
      tooltip: tooltip,
      backgroundColor: backgroundColor,
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
    return design.GoldButton(
      label: label,
      onPressed: onPressed,
      icon: icon,
      isLoading: isLoading,
    );
  }
}

class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.showBack = false,
  });

  final String title;
  final String subtitle;
  final Widget? trailing;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
      child: Stack(
        children: [
          Positioned(
            right: 6,
            top: -4,
            child: Icon(
              Icons.music_note_rounded,
              size: 46,
              color: kGold.withValues(alpha: 0.10),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (showBack)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: AnimatedGoldIconButton(
                    icon: Icons.arrow_back_rounded,
                    tooltip: 'Back',
                    backgroundColor: kCard2,
                    onTap: () => context.canPop()
                        ? context.pop()
                        : context.go('/homePage'),
                  ),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: gitaTitle(32),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.spa_rounded,
                          size: 18,
                          color: kPeacockTeal.withValues(alpha: 0.72),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: gitaBody(size: 14),
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ],
      ),
    );
  }
}
