import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_colors.dart';

class SemesterPreviewCard extends StatelessWidget {
  final int semesterNumber;
  final String title;
  final String subtitle;
  final bool isActive;
  final VoidCallback? onTap;

  const SemesterPreviewCard({
    super.key,
    required this.semesterNumber,
    required this.title,
    required this.subtitle,
    required this.isActive,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isActive ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isActive ? AppColors.surface : AppColors.surface.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isActive
                  ? AppColors.surfaceBorderLight
                  : AppColors.surfaceBorder.withValues(alpha: 0.5),
              width: 1,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: AppColors.primaryBlue.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              // Semester Icon / Number Badge
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.primaryBlue.withValues(alpha: 0.12)
                      : AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isActive
                        ? AppColors.primaryBlue.withValues(alpha: 0.3)
                        : AppColors.surfaceBorder,
                  ),
                ),
                child: Center(
                  child: Text(
                    '$semesterNumber',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isActive ? AppColors.primaryBlue : AppColors.textDisabled,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Title & Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: isActive
                                    ? AppColors.textPrimary
                                    : AppColors.textDisabled,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(width: 8),
                        if (isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'OPEN',
                              style: TextStyle(
                                color: AppColors.success,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          )
                        else
                          const Icon(
                            LucideIcons.lock,
                            size: 13,
                            color: AppColors.textDisabled,
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isActive
                                ? AppColors.textSecondary
                                : AppColors.textDisabled,
                          ),
                    ),
                  ],
                ),
              ),

              // Trailing Arrow or Lock
              Icon(
                isActive ? LucideIcons.arrowRight : LucideIcons.lock,
                size: 16,
                color: isActive ? AppColors.primaryBlue : AppColors.textDisabled,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
