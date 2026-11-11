import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

/// Interactive academic deck card for Semesters, Subjects, and Syllabus Modules.
/// Features a metallic gold squircle emblem, glowing emerald status pill,
/// smooth hover scaling (1.02x), and an animated trailing arrow transition.
class NotesHubAcademicCard extends StatefulWidget {
  const NotesHubAcademicCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badgeText,
    this.isActive = true,
    this.leadingNumber,
    this.leadingIcon,
    this.actionLabel = 'VIEW NOTES',
    this.adminAction,
    this.adminTooltip = 'Edit',
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final String? badgeText;
  final bool isActive;
  final int? leadingNumber;
  final IconData? leadingIcon;
  final String actionLabel;
  final VoidCallback? adminAction;
  final String adminTooltip;

  @override
  State<NotesHubAcademicCard> createState() => _NotesHubAcademicCardState();
}

class _NotesHubAcademicCardState extends State<NotesHubAcademicCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgFill = isDark
        ? (_isHovered ? const Color(0xE6101B3B) : const Color(0xCC090F22))
        : (_isHovered ? const Color(0xFFFFFFFF) : const Color(0xF2FAF7F0));

    final borderColor = isDark
        ? (_isHovered ? RoyalColors.cyanInteractive : RoyalColors.glassGoldBorder)
        : (_isHovered ? RoyalColors.royalGold : RoyalColors.ivoryBorder);

    final borderWidth = _isHovered ? 1.5 : 1.0;

    return MouseRegion(
      cursor: widget.isActive ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isHovered && widget.isActive ? 1.02 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: bgFill,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: borderColor, width: borderWidth),
              boxShadow: _isHovered && widget.isActive
                  ? (isDark
                      ? [
                          BoxShadow(
                            color: RoyalColors.cyanInteractive.withValues(alpha: 0.15),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                          const BoxShadow(
                            color: Color(0x33090F22),
                            blurRadius: 16,
                            offset: Offset(0, 4),
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: RoyalColors.royalGold.withValues(alpha: 0.2),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ])
                  : (isDark
                      ? const [
                          BoxShadow(
                            color: Color(0x26000000),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ]
                      : RoyalShadows.subtleCard),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top row: Emblem + Status badge + Optional Admin action
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Squircle Emblem
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: widget.isActive
                                ? RoyalGradients.metallicGold
                                : null,
                            color: widget.isActive
                                ? null
                                : (isDark ? const Color(0x26FFFFFF) : const Color(0x1A101B3B)),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: widget.isActive
                                ? [
                                    BoxShadow(
                                      color: RoyalColors.royalGold.withValues(alpha: 0.35),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: widget.leadingNumber != null
                                ? Text(
                                    '${widget.leadingNumber}'.padLeft(2, '0'),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w900,
                                      color: RoyalColors.midnightNavy,
                                    ),
                                  )
                                : Icon(
                                    widget.leadingIcon ?? Icons.menu_book_rounded,
                                    size: 20,
                                    color: widget.isActive
                                        ? RoyalColors.midnightNavy
                                        : (isDark ? RoyalColors.textMutedDark : RoyalColors.textNavyMuted),
                                  ),
                          ),
                        ),

                        // Badges and Admin Controls
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (widget.adminAction != null) ...[
                              IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                icon: const Icon(
                                  Icons.edit_note_rounded,
                                  size: 18,
                                  color: RoyalColors.royalGold,
                                ),
                                tooltip: widget.adminTooltip,
                                onPressed: widget.adminAction,
                              ),
                              const SizedBox(width: 8),
                            ],

                            // Status Pill
                            if (widget.badgeText != null && widget.badgeText!.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                                decoration: BoxDecoration(
                                  color: widget.isActive
                                      ? (isDark ? const Color(0x2610B981) : const Color(0x1A10B981))
                                      : (isDark ? const Color(0x1AFFFFFF) : const Color(0x0D101B3B)),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: widget.isActive
                                        ? RoyalColors.emeraldActive.withValues(alpha: 0.4)
                                        : (isDark ? const Color(0x33FFFFFF) : RoyalColors.ivoryBorder),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (widget.isActive) ...[
                                      Container(
                                        width: 5,
                                        height: 5,
                                        decoration: const BoxDecoration(
                                          color: RoyalColors.emeraldActive,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                    ],
                                    Text(
                                      widget.badgeText!,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: widget.isActive
                                            ? (isDark ? RoyalColors.champagne : const Color(0xFF047857))
                                            : (isDark ? RoyalColors.textSlateMuted : RoyalColors.textNavySubtle),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Middle: Title & Subtitle
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                            color: isDark ? RoyalColors.pearlWhite : RoyalColors.midnightNavy,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isDark ? RoyalColors.textSlateMuted : RoyalColors.textNavyMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Bottom: Action Nav Link with Animated Arrow
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.actionLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                            color: widget.isActive
                                ? (_isHovered
                                    ? (isDark ? RoyalColors.cyanInteractive : RoyalColors.royalGold)
                                    : (isDark ? RoyalColors.champagne : const Color(0xFF8A6715)))
                                : (isDark ? RoyalColors.textDisabled : RoyalColors.textNavySubtle),
                          ),
                        ),
                        AnimatedPadding(
                          duration: const Duration(milliseconds: 180),
                          padding: EdgeInsets.only(left: _isHovered && widget.isActive ? 6.0 : 0.0),
                          child: Icon(
                            Icons.arrow_forward_rounded,
                            size: 15,
                            color: widget.isActive
                                ? (_isHovered
                                    ? (isDark ? RoyalColors.cyanInteractive : RoyalColors.royalGold)
                                    : (isDark ? RoyalColors.champagne : const Color(0xFF8A6715)))
                                : (isDark ? RoyalColors.textDisabled : RoyalColors.textNavySubtle),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The signature study material document card with PDF emblem,
/// type badge, metadata, View PDF action, Download action, and contextual admin controls.
class NotesHubResourceCard extends StatefulWidget {
  const NotesHubResourceCard({
    super.key,
    required this.title,
    required this.moduleNumber,
    required this.categoryType,
    required this.onView,
    required this.onDownload,
    this.isDownloaded = false,
    this.isDownloading = false,
    this.downloadProgress,
    this.fileMetadata,
    this.onRename,
    this.onDelete,
  });

  final String title;
  final int moduleNumber;
  final String categoryType;
  final VoidCallback onView;
  final VoidCallback onDownload;
  final bool isDownloaded;
  final bool isDownloading;
  final double? downloadProgress;
  final String? fileMetadata;
  final VoidCallback? onRename;
  final VoidCallback? onDelete;

  @override
  State<NotesHubResourceCard> createState() => _NotesHubResourceCardState();
}

class _NotesHubResourceCardState extends State<NotesHubResourceCard> {
  bool _isHovered = false;

  Color _getCategoryColor() {
    switch (widget.categoryType.toLowerCase()) {
      case 'qbank':
        return RoyalColors.champagne;
      case 'extra':
        return RoyalColors.emeraldActive;
      case 'notes':
      default:
        return RoyalColors.royalGold;
    }
  }

  String _getCategoryLabel() {
    switch (widget.categoryType.toLowerCase()) {
      case 'qbank':
        return 'Question Bank';
      case 'extra':
        return 'Extra Material';
      case 'notes':
      default:
        return 'Lecture Notes';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final catColor = _getCategoryColor();

    final bgFill = isDark
        ? (_isHovered ? const Color(0xE6101B3B) : const Color(0xCC0B1224))
        : (_isHovered ? const Color(0xFFFFFFFF) : const Color(0xF2FAF7F0));

    final borderColor = isDark
        ? (_isHovered ? RoyalColors.cyanInteractive : RoyalColors.glassGoldBorder)
        : (_isHovered ? RoyalColors.royalGold : RoyalColors.ivoryBorder);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? 1.015 : 1.0,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: bgFill,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor, width: _isHovered ? 1.4 : 1.0),
            boxShadow: _isHovered
                ? (isDark
                    ? [
                        BoxShadow(
                          color: RoyalColors.cyanInteractive.withValues(alpha: 0.12),
                          blurRadius: 18,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: RoyalColors.royalGold.withValues(alpha: 0.18),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ])
                : (isDark
                    ? const [
                        BoxShadow(
                          color: Color(0x26000000),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ]
                    : RoyalShadows.subtleCard),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: PDF Emblem + Details + Badges
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // PDF Icon Emblem
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0x26EF4444) : const Color(0x1AEF4444),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.35),
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.picture_as_pdf_rounded,
                        color: Color(0xFFEF4444),
                        size: 22,
                      ),
                    ),
                  ),

                  const SizedBox(width: 14),

                  // Title + Pills
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                            color: isDark ? RoyalColors.pearlWhite : RoyalColors.midnightNavy,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            // Module Pill
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0x331D2C5A) : const Color(0xFFF0EBE1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Module ${widget.moduleNumber}',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? RoyalColors.champagne : RoyalColors.midnightNavy,
                                ),
                              ),
                            ),

                            // Category Pill
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: catColor.withValues(alpha: isDark ? 0.15 : 0.12),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: catColor.withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                _getCategoryLabel(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: catColor,
                                ),
                              ),
                            ),

                            // Offline Pill
                            if (widget.isDownloaded)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                decoration: BoxDecoration(
                                  color: const Color(0x2610B981),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: RoyalColors.emeraldActive.withValues(alpha: 0.4),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.check_circle_rounded,
                                      size: 11,
                                      color: RoyalColors.emeraldActive,
                                    ),
                                    SizedBox(width: 3),
                                    Text(
                                      'Offline',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: RoyalColors.emeraldActive,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Admin Actions
                  if (widget.onRename != null || widget.onDelete != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.onRename != null)
                          IconButton(
                            icon: const Icon(Icons.edit_note_rounded, size: 20),
                            color: RoyalColors.royalGold,
                            tooltip: 'Rename Resource',
                            onPressed: widget.onRename,
                          ),
                        if (widget.onDelete != null)
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, size: 18),
                            color: const Color(0xFFDC2626),
                            tooltip: 'Delete Resource',
                            onPressed: widget.onDelete,
                          ),
                      ],
                    ),
                ],
              ),

              // Download progress bar
              if (widget.isDownloading) ...[
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: widget.downloadProgress != null && widget.downloadProgress! > 0
                      ? widget.downloadProgress
                      : null,
                  color: RoyalColors.royalGold,
                  backgroundColor: isDark ? const Color(0x33C5A04A) : const Color(0x1AC5A04A),
                ),
              ],

              const SizedBox(height: 14),

              // Actions: View PDF & Download
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // View PDF Button
                  OutlinedButton.icon(
                    onPressed: widget.onView,
                    icon: const Icon(Icons.visibility_rounded, size: 15),
                    label: const Text('View PDF'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark ? RoyalColors.cyanInteractive : const Color(0xFF0284C7),
                      side: BorderSide(
                        color: isDark ? RoyalColors.cyanInteractive : const Color(0xFF0284C7),
                        width: 1.2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Download Button
                  FilledButton.tonalIcon(
                    onPressed: widget.onDownload,
                    icon: Icon(
                      widget.isDownloaded ? Icons.offline_pin_rounded : Icons.download_rounded,
                      size: 15,
                    ),
                    label: Text(widget.isDownloaded ? 'Saved' : 'Download'),
                    style: FilledButton.styleFrom(
                      backgroundColor: isDark ? const Color(0x33C5A04A) : const Color(0x26C5A04A),
                      foregroundColor: isDark ? RoyalColors.champagne : const Color(0xFF8A6715),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: isDark ? RoyalColors.glassGoldBorder : const Color(0xFFC5A04A),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

