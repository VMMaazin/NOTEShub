import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/theme_controller.dart';
import '../features/admin/presentation/admin_login_screen.dart';
import '../features/auth/bloc/auth_bloc.dart';
import '../features/downloads/logic/download_cubit.dart';
import '../features/downloads/logic/download_state.dart';
import '../features/downloads/presentation/downloads_screen.dart';

/// Unified Royal Academic AppBar for NOTEShub providing consistent branding,
/// theme toggling, offline library access, and contextual admin account controls.
class NotesHubAppBar extends StatelessWidget implements PreferredSizeWidget {
  const NotesHubAppBar({
    super.key,
    this.title,
    this.subtitle,
    this.bottom,
    this.showBackButton = false,
    this.showDownloadsButton = true,
    this.showThemeToggle = true,
    this.showAdminControls = true,
    this.onBack,
    this.actions,
  });

  final String? title;
  final String? subtitle;
  final PreferredSizeWidget? bottom;
  final bool showBackButton;
  final bool showDownloadsButton;
  final bool showThemeToggle;
  final bool showAdminControls;
  final VoidCallback? onBack;
  final List<Widget>? actions;

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (bottom?.preferredSize.height ?? 0.0),
      );

  void _showAdminAccountDialog(BuildContext context, Authenticated authState) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark
            ? RoyalColors.midnightNavySurface
            : RoyalColors.creamCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(
            color: isDark ? RoyalColors.glassGoldBorder : const Color(0x33C5A04A),
            width: 1.2,
          ),
        ),
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: RoyalGradients.metallicGold,
                borderRadius: BorderRadius.circular(10),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x4DC5A04A),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.admin_panel_settings_rounded,
                color: RoyalColors.midnightNavy,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Administrator',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: isDark ? RoyalColors.pearlWhite : RoyalColors.midnightNavy,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              authState.user.name ?? 'Academic Staff',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: isDark ? RoyalColors.pearlWhite : RoyalColors.midnightNavy,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? const Color(0x33C5A04A) : const Color(0x26C5A04A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? RoyalColors.glassGoldBorder : const Color(0xFFC5A04A),
                ),
              ),
              child: Text(
                'ROLE: ${(authState.user.role ?? 'Author').toUpperCase()}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isDark ? RoyalColors.champagne : const Color(0xFF8A6715),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0x26FFFFFF) : const Color(0x0D101B3B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? RoyalColors.glassWhiteBorder : RoyalColors.ivoryBorder,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: isDark ? RoyalColors.champagne : const Color(0xFF8A6715),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Admin mode active: Contextual controls (Add/Rename Subject, Upload Material) are enabled directly in curriculum views.',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: isDark ? RoyalColors.textMutedDark : RoyalColors.textNavyMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Close',
              style: TextStyle(
                color: isDark ? RoyalColors.textMutedDark : RoyalColors.textNavyMuted,
              ),
            ),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<AuthBloc>().add(const SignOutRequested());
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Signed out of Administrator Mode.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: const Icon(Icons.logout_rounded, size: 16),
            label: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final canPop = showBackButton || Navigator.of(context).canPop();

    final screenWidth = MediaQuery.sizeOf(context).width;
    final isNarrow = screenWidth < 400;

    return AppBar(
      backgroundColor: isDark
          ? const Color(0xE60A1124)
          : const Color(0xF2F7F3E9),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      titleSpacing: canPop ? (isNarrow ? 4.0 : 8.0) : NavigationToolbar.kMiddleSpacing,
      leading: canPop
          ? IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: isDark ? RoyalColors.pearlWhite : RoyalColors.midnightNavy,
              ),
              tooltip: 'Back',
              onPressed: onBack ?? () => Navigator.of(context).maybePop(),
            )
          : null,
      title: title != null
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title!,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: isNarrow ? 15 : 16,
                    color: isDark ? RoyalColors.pearlWhite : RoyalColors.midnightNavy,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: isNarrow ? 10 : 11,
                      fontWeight: FontWeight.normal,
                      color: isDark
                          ? RoyalColors.champagne.withValues(alpha: 0.8)
                          : const Color(0xFF64748B),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: RoyalGradients.metallicGold,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: RoyalColors.royalGold.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.school_rounded,
                    size: 18,
                    color: RoyalColors.midnightNavy,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  AppConstants.appName,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    letterSpacing: -0.3,
                    color: isDark ? RoyalColors.pearlWhite : RoyalColors.midnightNavy,
                  ),
                ),
              ],
            ),
      actions: [
        if (actions != null) ...actions!,

        // 1. Offline Library Action
        if (showDownloadsButton)
          BlocBuilder<DownloadCubit, DownloadState>(
            builder: (context, state) {
              final count = state.allDocuments.length;
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    tooltip: 'Offline Library',
                    visualDensity: isNarrow ? VisualDensity.compact : VisualDensity.standard,
                    icon: Icon(
                      Icons.download_for_offline_rounded,
                      size: isNarrow ? 20 : 22,
                      color: isDark ? RoyalColors.pearlWhite : RoyalColors.midnightNavy,
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const DownloadsScreen()),
                      );
                    },
                  ),
                  if (count > 0)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: RoyalColors.royalGold,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),

        // 2. Theme Toggle Action (Sun / Moon)
        if (showThemeToggle)
          IconButton(
            tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
            visualDensity: isNarrow ? VisualDensity.compact : VisualDensity.standard,
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              size: isNarrow ? 18 : 20,
              color: isDark ? RoyalColors.champagne : const Color(0xFF8A6715),
            ),
            onPressed: () => ThemeScope.of(context).toggleTheme(),
          ),

        // 3. Admin Status / Login Action
        if (showAdminControls)
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, authState) {
              final isAdmin = authState is Authenticated && authState.isAuthor;

              if (isAdmin) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _showAdminAccountDialog(context, authState),
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      padding: EdgeInsets.symmetric(
                        horizontal: isNarrow ? 6 : 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0x33C5A04A) : const Color(0x26C5A04A),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? RoyalColors.glassGoldBorder : const Color(0xFFC5A04A),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF10B981),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Admin',
                            style: TextStyle(
                              fontSize: isNarrow ? 10 : 12,
                              fontWeight: FontWeight.w700,
                              color: isDark ? RoyalColors.champagne : const Color(0xFF8A6715),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              return Padding(
                padding: const EdgeInsets.only(right: 6.0),
                child: IconButton(
                  tooltip: 'Admin Sign In',
                  visualDensity: isNarrow ? VisualDensity.compact : VisualDensity.standard,
                  icon: Icon(
                    Icons.admin_panel_settings_outlined,
                    size: isNarrow ? 18 : 20,
                    color: isDark ? const Color(0xFF8A99AD) : const Color(0xFF64748B),
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
                    );
                  },
                ),
              );
            },
          ),
      ],
      bottom: bottom,
    );
  }
}

