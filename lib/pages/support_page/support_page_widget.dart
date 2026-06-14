/// ------------------------------------------------------------
/// SupportScreen
///
/// Purpose:
/// Simple support and feedback contact point.
///
/// Responsibilities:
/// - Show gitawisdomapp@gmail.com clearly.
/// - Open a safe mailto link when supported by the platform.
/// - Keep fallback text readable if email launch fails.
///
/// Notes:
/// Support copy is intentionally short so it works on small phones and feels
/// calm rather than like a help-center portal.
/// ------------------------------------------------------------
library;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../gita_common/gita_common.dart';

class SupportPageWidget extends StatelessWidget {
  const SupportPageWidget({super.key});

  static String routeName = 'SupportPage';
  static String routePath = '/supportPage';

  static final Uri _supportEmailUri = Uri(
    scheme: 'mailto',
    path: 'gitawisdomapp@gmail.com',
    queryParameters: {'subject': 'Gita Wisdom Support'},
  );

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
          children: [
            const PageHeader(
              title: 'Support',
              subtitle: 'Help and feedback',
              showBack: true,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 36),
              child: PremiumCard(
                accent: true,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const IconMedallion(
                          icon: Icons.support_agent_rounded,
                          size: 46,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Need help or want to share feedback?',
                            style: gitaBody(
                              color: kText,
                              weight: FontWeight.w900,
                            ).copyWith(height: 1.35),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'We welcome bug reports, suggestions, and feedback to help improve Gita Wisdom.',
                      style: gitaBody(color: kText).copyWith(height: 1.55),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Contact:',
                      style: gitaBody(color: kMuted, weight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => _openSupportEmail(context),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: kCream,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: kGold.withValues(alpha: 0.32),
                          ),
                        ),
                        child: Text(
                          'gitawisdomapp@gmail.com',
                          style: gitaBody(
                            color: kDarkText,
                            weight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> _openSupportEmail(BuildContext context) async {
    try {
      final opened = await launchUrl(
        _supportEmailUri,
        mode: LaunchMode.externalApplication,
      );
      if (!opened && context.mounted) {
        _showError(context);
      }
    } catch (error, stackTrace) {
      debugPrint('Support email open failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (context.mounted) {
        _showError(context);
      }
    }
  }

  static void _showError(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Could not open email on this device.'),
        ),
      );
  }
}
