import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

/// Standard empty or error display complying with Royal Academic Glassmorphism.
class EmptyStateView extends StatelessWidget {
  const EmptyStateView({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final primaryGold = isDark
        ? RoyalColors.royalGold
        : const Color(0xFF8A6715);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark
                    ? const Color(0x26C5A04A)
                    : const Color(0x1FC5A04A),
                border: Border.all(
                  color: isDark
                      ? RoyalColors.glassGoldBorder
                      : const Color(0xFFC5A04A),
                  width: 1.2,
                ),
              ),
              child: Icon(
                icon,
                size: 36,
                color: primaryGold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: isDark
                    ? RoyalColors.pearlWhite
                    : RoyalColors.midnightNavy,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Text(
                message,
                style: TextStyle(
                  color: isDark
                      ? const Color(0xFF8A99AD)
                      : const Color(0xFF64748B),
                  fontSize: 13,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: Text(actionLabel!),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryGold,
                  side: BorderSide(
                    color: isDark
                        ? RoyalColors.glassGoldBorder
                        : const Color(0xFFC5A04A),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

