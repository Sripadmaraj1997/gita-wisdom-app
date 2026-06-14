/// ------------------------------------------------------------
/// PrivacyPolicyScreen
///
/// Purpose:
/// User-facing privacy explanation for the offline-first app.
///
/// Responsibilities:
/// - Explain local storage of progress, saved verses, highlights, journal
///   entries, journey progress, and preferences.
/// - Clarify that Gita Wisdom does not sell personal information or track users
///   across apps.
/// - Mention external community links without hiding that they leave the app.
///
/// Notes:
/// This screen supports store readiness and user trust. Keep it readable,
/// scrollable, and aligned with the actual local-only architecture.
/// ------------------------------------------------------------
library;

import 'package:flutter/material.dart';

import '../gita_common/gita_common.dart';

class PrivacyPolicyPageWidget extends StatelessWidget {
  const PrivacyPolicyPageWidget({super.key});

  static String routeName = 'PrivacyPolicyPage';
  static String routePath = '/privacyPolicyPage';

  @override
  Widget build(BuildContext context) {
    return GitaScaffold(
      child: SafeArea(
        top: false,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.only(
            bottom: gitaBottomNavScrollPadding(context),
          ),
          children: const [
            PageHeader(
              title: 'Privacy Policy',
              subtitle: 'Local-first privacy and data handling',
              showBack: true,
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(24, 18, 24, 36),
              child: _PrivacyPolicyCard(),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrivacyPolicyCard extends StatelessWidget {
  const _PrivacyPolicyCard();

  static const _items = [
    'Gita Wisdom is designed to work primarily offline.',
    'Reading progress, saved verses, highlights, journal entries, journey progress, personalization signals, and preferences are stored locally on your device.',
    'Personalized guidance is based only on local app activity and does not require an account or cloud sync.',
    'Gita Wisdom does not sell personal information.',
    'Gita Wisdom does not track users across apps.',
    'Community links may open external services such as WhatsApp.',
    'Future versions may introduce optional cloud features, which will be disclosed before use.',
  ];

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      accent: true,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const IconMedallion(
                icon: Icons.privacy_tip_rounded,
                size: 46,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Gita Wisdom Privacy Policy',
                  style: gitaBody(color: kText, weight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          for (final item in _items) ...[
            _PolicyBullet(text: item),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _PolicyBullet extends StatelessWidget {
  const _PolicyBullet({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: kGold,
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: gitaBody(color: kText).copyWith(height: 1.55),
          ),
        ),
      ],
    );
  }
}
