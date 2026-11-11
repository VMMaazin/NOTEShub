import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/app_colors.dart';

/// Refined academic footer for NOTEShub.
class AppFooter extends StatelessWidget {
  const AppFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32.0),
      child: Column(
        children: [
          Divider(
            color: isDark
                ? RoyalColors.glassGoldBorder.withValues(alpha: 0.25)
                : RoyalColors.ivoryBorder,
            thickness: 1,
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: RoyalColors.royalGold,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${AppConstants.appName} • Curated Academic Notes',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? RoyalColors.textMutedDark
                      : RoyalColors.textNavyMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Open access library for students. No sign-in required.',
            style: TextStyle(
              fontSize: 11,
              color: isDark
                  ? RoyalColors.textSlateMuted
                  : RoyalColors.textNavySubtle,
            ),
          ),
          const SizedBox(height: 14),
          InkWell(
            onTap: () => launchUrl(
              Uri.parse(AppConstants.androidApkDownloadUrl),
              mode: LaunchMode.externalApplication,
            ),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.android_rounded,
                    size: 15,
                    color: isDark ? RoyalColors.champagne : const Color(0xFF8A6715),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Download NOTEShub for Android (v${AppConstants.appVersion} APK)',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: isDark ? RoyalColors.champagne : const Color(0xFF8A6715),
                      decoration: TextDecoration.underline,
                      decorationColor: (isDark ? RoyalColors.champagne : const Color(0xFF8A6715))
                          .withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

