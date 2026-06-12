// Settings screen for the local MVP.
//
// Contains only working, user-facing controls: reader preferences, support
// links, about/disclaimer copy, and a local data reset. There are no account,
// subscription, Firebase, or OpenAI settings in this offline build.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../services/local_storage_service.dart';
import '../../services/reading_progress_service.dart';
import '../gita_common/gita_common.dart';
import '../privacy_policy_page/privacy_policy_page_widget.dart';
import '../support_page/support_page_widget.dart';

class SettingsPageWidget extends StatefulWidget {
  const SettingsPageWidget({super.key});

  static String routeName = 'SettingsPage';
  static String routePath = '/settingsPage';

  @override
  State<SettingsPageWidget> createState() => _SettingsPageWidgetState();
}

class _SettingsPageWidgetState extends State<SettingsPageWidget> {
  bool _isClearing = false;

  @override
  Widget build(BuildContext context) {
    return GitaScaffold(
      bottomNavIndex: 4,
      child: ListView(
        key: const PageStorageKey('settings_scroll_position'),
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.only(bottom: gitaBottomNavScrollPadding(context)),
        children: [
          const PageHeader(
            title: 'Settings',
            subtitle: 'Offline app settings and saved reflections',
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 36),
            child: Column(
              children: [
                // Reading preferences:
                // These settings feed VerseReaderScreen and are kept local so
                // reading remains available without an account.
                const _SettingsSectionHeader(
                  title: 'Reading',
                  icon: Icons.format_size_rounded,
                ),
                const SizedBox(height: 10),
                const AnimatedEntrance(
                  delay: Duration(milliseconds: 72),
                  child: _ReadingPreferencesCard(),
                ),
                const SizedBox(height: 12),
                const _SettingsSectionHeader(
                  title: 'Support',
                  icon: Icons.help_outline_rounded,
                ),
                const SizedBox(height: 10),
                AnimatedEntrance(
                  delay: const Duration(milliseconds: 96),
                  child: _SettingRow(
                    icon: Icons.privacy_tip_rounded,
                    label: 'Privacy Policy',
                    value: 'View',
                    valueColor: kSoftGold,
                    iconColor: kSoftGold,
                    onTap: () => context.push(
                      PrivacyPolicyPageWidget.routePath,
                    ),
                  ),
                ),
                AnimatedEntrance(
                  delay: const Duration(milliseconds: 102),
                  child: _SettingRow(
                    icon: Icons.support_agent_rounded,
                    label: 'Support',
                    value: 'Contact',
                    valueColor: kSoftGold,
                    iconColor: kSoftGold,
                    onTap: () => context.push(SupportPageWidget.routePath),
                  ),
                ),
                const AnimatedEntrance(
                  delay: Duration(milliseconds: 106),
                  child: _SettingRow(
                    icon: Icons.people_outline_rounded,
                    label: 'Community Links',
                    value: 'None active',
                    valueColor: kSoftGold,
                    iconColor: kSoftGold,
                    onTap: null,
                  ),
                ),
                const SizedBox(height: 12),
                // About / disclaimer:
                // Keep source notes and spiritual-scope language close to app
                // settings where users naturally look for trust information.
                const _SettingsSectionHeader(
                  title: 'About',
                  icon: Icons.verified_user_rounded,
                ),
                const SizedBox(height: 10),
                const AnimatedEntrance(
                  delay: Duration(milliseconds: 140),
                  child: _AboutCard(),
                ),
                const SizedBox(height: 18),
                // Local data clearing:
                // Removes user-owned saved content and preferences from this
                // device. Bundled scripture JSON remains part of the app.
                const _SettingsSectionHeader(
                  title: 'Data',
                  icon: Icons.storage_rounded,
                ),
                const SizedBox(height: 10),
                AnimatedEntrance(
                  delay: const Duration(milliseconds: 210),
                  child: _SettingRow(
                    icon: Icons.delete_sweep_rounded,
                    label: _isClearing ? 'Clearing...' : 'Clear Local Data',
                    value: 'Local only',
                    valueColor: kSoftGold,
                    iconColor: kSoftGold,
                    onTap: _isClearing ? null : _confirmClearData,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmClearData() async {
    // Clear all user-owned local state but leave packaged scripture assets
    // untouched. ReadingProgressService has separate keys, so clear both.
    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kCard,
        title: Text('Clear local data?', style: gitaTitle(22)),
        content: Text(
          'This removes saved verses, highlights, journal entries, journey progress, Ask Gita history, font size, and continue reading progress from this device only.',
          style: gitaBody(color: kText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel', style: gitaBody(color: kGold)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Clear', style: gitaBody(color: kSaffron)),
          ),
        ],
      ),
    );
    if (shouldClear != true) {
      return;
    }

    setState(() => _isClearing = true);
    try {
      await LocalStorageService.clearAllUserData();
      await ReadingProgressService.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Local data cleared.')),
        );
      }
    } catch (error, stackTrace) {
      debugPrint('Clear local data failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Local data was not cleared.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isClearing = false);
      }
    }
  }
}

class _AboutCard extends StatelessWidget {
  const _AboutCard();

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      accent: true,
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const IconMedallion(icon: Icons.info_outline_rounded, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'About',
                  style: gitaBody(color: kText, weight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                Text(
                  'Gita Wisdom is a peaceful Bhagavad Gita companion created to help bring timeless wisdom into daily life.\n\nMost core features are available offline, including reading, saved verses, journal, journeys, and reflections.\n\nTranslations and transliterations are loaded from the app\'s local Bhagavad Gita dataset. Gita Wisdom Interpretation offers practical contemplative insights designed to help apply timeless teachings to everyday life. Reflections are practical study notes intended for daily contemplation.\n\nGita Wisdom supports spiritual learning. It is not medical, legal, financial, or mental health advice.',
                  style: gitaBody(color: kText, size: 16).copyWith(
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadingPreferencesCard extends StatefulWidget {
  const _ReadingPreferencesCard();

  @override
  State<_ReadingPreferencesCard> createState() =>
      _ReadingPreferencesCardState();
}

class _ReadingPreferencesCardState extends State<_ReadingPreferencesCard> {
  double _fontScale = 1;
  bool _showSanskrit = true;
  bool _showTransliteration = true;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // Reader preferences are shared with VerseReaderScreen via
    // shared_preferences so they persist across app launches.
    final fontScale = await LocalStorageService.readerFontScale();
    final showSanskrit = await LocalStorageService.readerShowSanskrit();
    final showTransliteration =
        await LocalStorageService.readerShowTransliteration();
    if (!mounted) {
      return;
    }
    setState(() {
      _fontScale = fontScale;
      _showSanskrit = showSanskrit;
      _showTransliteration = showTransliteration;
      _loaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const IconMedallion(icon: Icons.format_size_rounded, size: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Reading preferences',
                  style: gitaBody(color: kText, weight: FontWeight.w900),
                ),
              ),
              AccentPill(_fontSizeLabel(_fontScale)),
            ],
          ),
          const SizedBox(height: 12),
          if (!_loaded)
            const LinearProgressIndicator(
              minHeight: 6,
              backgroundColor: kLine,
              valueColor: AlwaysStoppedAnimation<Color>(kGold),
            )
          else ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _PreferenceChip(
                  label: 'Small',
                  selected: _fontScale <= 0.94,
                  onTap: () => _setFontScale(0.9),
                ),
                _PreferenceChip(
                  label: 'Medium',
                  selected: _fontScale > 0.94 && _fontScale < 1.14,
                  onTap: () => _setFontScale(1),
                ),
                _PreferenceChip(
                  label: 'Large',
                  selected: _fontScale >= 1.14,
                  onTap: () => _setFontScale(1.18),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _PreferenceSwitch(
              label: 'Show Sanskrit',
              value: _showSanskrit,
              onChanged: (value) {
                setState(() => _showSanskrit = value);
                LocalStorageService.setReaderShowSanskrit(value);
              },
            ),
            const SizedBox(height: 8),
            _PreferenceSwitch(
              label: 'Show Transliteration',
              value: _showTransliteration,
              onChanged: (value) {
                setState(() => _showTransliteration = value);
                LocalStorageService.setReaderShowTransliteration(value);
              },
            ),
          ],
          const SizedBox(height: 12),
          Text(
            'Applies to scripture reading in Verse Reader.',
            style: gitaBody(color: kText, size: 13),
          ),
        ],
      ),
    );
  }

  void _setFontScale(double value) {
    setState(() => _fontScale = value);
    LocalStorageService.setReaderFontScale(value);
  }

  String _fontSizeLabel(double value) {
    if (value <= 0.94) {
      return 'Small';
    }
    if (value >= 1.14) {
      return 'Large';
    }
    return 'Medium';
  }
}

class _PreferenceChip extends StatelessWidget {
  const _PreferenceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      borderRadius: BorderRadius.circular(100),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? kRoyalPurple : kCard2.withValues(alpha: 0.78),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: kGold.withValues(alpha: 0.28)),
        ),
        child: Text(
          label,
          style: gitaBody(
            color: selected ? kSoftGold : kText,
            size: 12,
            weight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _PreferenceSwitch extends StatelessWidget {
  const _PreferenceSwitch({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: kCard2.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kGold.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: gitaBody(color: kText, size: 13, weight: FontWeight.w800),
            ),
          ),
          Switch.adaptive(
            value: value,
            activeThumbColor: kGold,
            activeTrackColor: kGold.withValues(alpha: 0.34),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _SettingsSectionHeader extends StatelessWidget {
  const _SettingsSectionHeader({
    required this.title,
    required this.icon,
  });

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: kGold, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: gitaBody(color: kText, size: 13, weight: FontWeight.w900),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 1,
            color: kGold.withValues(alpha: 0.12),
          ),
        ),
      ],
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    this.valueColor,
    this.iconColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;
  final Color? valueColor;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PremiumCard(
        onTap: onTap,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: iconColor ?? kGold),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: gitaBody(color: kText, weight: FontWeight.w800),
              ),
            ),
            Text(
              value,
              style: gitaBody(
                color: valueColor ?? kMuted,
                size: 13,
                weight: FontWeight.w800,
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right_rounded, color: kMuted),
            ],
          ],
        ),
      ),
    );
  }
}
