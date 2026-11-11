import 'dart:ui';
import 'package:flutter/material.dart';

/// Royal, elegant, and sophisticated color palette for NOTEShub.
/// Inspired strictly by deep royal midnight navy, antique metallic gold,
/// warm ivory, and pearl white.
class RoyalColors {
  RoyalColors._();

  // Midnight Navy Spectrum
  static const Color midnightNavy = Color(0xFF101B3B); // Deep royal midnight navy
  static const Color midnightNavyDark = Color(0xFF090F22); // Deepest abyss background
  static const Color midnightNavySurface = Color(0xFF162248); // Card/surface on navy
  static const Color midnightNavySubtle = Color(0xFF1D2C5A); // Elevated layer

  // Royal & Antique Gold Spectrum
  static const Color royalGold = Color(0xFFC5A04A); // Signature antique gold
  static const Color antiqueGold = Color(0xFFA88434); // Deep burnished gold
  static const Color metallicGold = Color(0xFFD4AF37); // Luminous metallic gold
  static const Color lightGold = Color(0xFFDFBE6E); // Soft gold highlight
  static const Color champagne = Color(0xFFE5CCA0); // Refined champagne tint
  static const Color champagneLight = Color(0xFFF3EBD8); // Frosted champagne veil
  static const Color paleGold = Color(0xFFFAF4E6); // Delicate gold container
  static const Color goldAccentDark = Color(0xFF8A6715); // High-contrast antique gold

  // Warm Ivory & Pearl White Spectrum
  static const Color warmIvory = Color(0xFFF7F3E9); // Primary warm ivory background
  static const Color creamCard = Color(0xFFFAF7F0); // Subtle cream surface
  static const Color pearlWhite = Color(0xFFFFFFFF); // Pure pearl white
  static const Color ivoryBorder = Color(0xFFE6DFC9); // Delicate warm ivory border
  static const Color ivoryBorderSubtle = Color(0xFFEEE8D8);

  // Typography Palette
  static const Color textNavy = Color(0xFF101B3B); // Primary text on light surfaces
  static const Color textNavyMuted = Color(0xFF4A5568); // Secondary text on light surfaces
  static const Color textNavySubtle = Color(0xFF718096); // Tertiary text on light surfaces
  static const Color textWhite = Color(0xFFFFFFFF); // Primary text on navy
  static const Color textChampagne = Color(0xFFE5CCA0); // Golden text on navy
  static const Color textMutedDark = Color(0xFFB8C2D8); // Subdued text on navy
  static const Color textSlateMuted = Color(0xFF8A99AD); // Detailed metadata
  static const Color textDisabled = Color(0xFF64748B); // Disabled text / icons

  // Interactive and Status Accents
  static const Color cyanInteractive = Color(0xFF38BDF8); // Cyan hover & active border
  static const Color emeraldActive = Color(0xFF10B981); // Emerald status dot / verified
  static const Color errorRed = Color(0xFFDC2626); // Destructive action red
  static const Color errorRedDark = Color(0xFFEF4444); // Dark theme error red

  // Glassmorphism Transparency Tokens
  static const Color glassWhite = Color(0x1AFFFFFF); // 10% translucent white
  static const Color glassWhiteDense = Color(0x33FFFFFF); // 20% frosted white
  static const Color glassNavy = Color(0xB3101B3B); // 70% midnight navy
  static const Color glassNavyDense = Color(0xE6101B3B); // 90% midnight navy
  static const Color glassGoldFill = Color(0x1AC5A04A); // 10% gold glow
  static const Color glassGoldBorder = Color(0x59C5A04A); // 35% antique gold rim
  static const Color glassWhiteBorder = Color(0x33FFFFFF); // 20% pearl rim
}

/// Curated gradient definitions for metallic gold, royal navy, and liquid glass.
class RoyalGradients {
  RoyalGradients._();

  /// Rich metallic gold linear gradient for badges, emblems, and borders.
  static const LinearGradient metallicGold = LinearGradient(
    colors: [
      Color(0xFFE5CCA0), // Champagne highlight
      Color(0xFFC5A04A), // Signature gold
      Color(0xFFA88434), // Antique gold
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Shimmering multi-tone gold gradient for text headers & highlights.
  static const LinearGradient goldShimmer = LinearGradient(
    colors: [
      Color(0xFFFAF4E6),
      Color(0xFFD4AF37),
      Color(0xFFC5A04A),
      Color(0xFFFAF4E6),
    ],
    stops: [0.0, 0.35, 0.7, 1.0],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Luminous gold sheen for fine borders and interactive rims.
  static const LinearGradient goldBorderGradient = LinearGradient(
    colors: [
      Color(0x99DFBE6E),
      Color(0x4DC5A04A),
      Color(0x99A88434),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Deep midnight navy hero gradient with layered atmospheric depth.
  static const LinearGradient midnightHero = LinearGradient(
    colors: [
      Color(0xFF0A1124),
      Color(0xFF101B3B),
      Color(0xFF162550),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Subtle ivory-to-cream gradient for light cards.
  static const LinearGradient ivoryCard = LinearGradient(
    colors: [
      Color(0xFFFFFFFF),
      Color(0xFFFAF7F0),
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  /// Translucent liquid glass highlight gradient.
  static const LinearGradient liquidGlassLight = LinearGradient(
    colors: [
      Color(0x38FFFFFF),
      Color(0x0FFFFFFF),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

/// Refined ambient shadows for royal surfaces and liquid glass controls.
class RoyalShadows {
  RoyalShadows._();

  /// Soft metallic gold glow for active/hovered interactive elements.
  static const List<BoxShadow> goldGlow = [
    BoxShadow(
      color: Color(0x2BC5A04A),
      blurRadius: 20,
      spreadRadius: -2,
      offset: Offset(0, 8),
    ),
  ];

  /// Radiant glass glow shadow for cards and dialogs.
  static const List<BoxShadow> glassGlow = [
    BoxShadow(
      color: Color(0x29C5A04A),
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
  ];

  /// Deep midnight ambient shadow for large hero cards & dialogs.
  static const List<BoxShadow> midnightAmbient = [
    BoxShadow(
      color: Color(0x33090F22),
      blurRadius: 30,
      offset: Offset(0, 14),
    ),
    BoxShadow(
      color: Color(0x1AC5A04A),
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];

  /// Subtle card shadow for ivory surfaces.
  static const List<BoxShadow> subtleCard = [
    BoxShadow(
      color: Color(0x0A101B3B),
      blurRadius: 16,
      offset: Offset(0, 6),
    ),
    BoxShadow(
      color: Color(0x05C5A04A),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  /// Liquid glass button elevation shadow.
  static const List<BoxShadow> glassButton = [
    BoxShadow(
      color: Color(0x1A101B3B),
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];
}

/// A reusable glassmorphic container providing frosted blur,
/// customizable background tints, and gold specular borders.
class RoyalGlassContainer extends StatelessWidget {
  const RoyalGlassContainer({
    super.key,
    required this.child,
    this.borderRadius = 18.0,
    this.blurSigma = 12.0,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 1.0,
    this.padding = const EdgeInsets.all(16.0),
    this.margin,
    this.width,
    this.height,
    this.boxShadow,
  });

  final Widget child;
  final double borderRadius;
  final double blurSigma;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderWidth;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final List<BoxShadow>? boxShadow;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultBg = isDark
        ? RoyalColors.glassNavy
        : RoyalColors.glassWhite;
    final defaultBorder = isDark
        ? RoyalColors.glassGoldBorder
        : RoyalColors.ivoryBorder;

    Widget content = Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? defaultBg,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor ?? defaultBorder,
          width: borderWidth,
        ),
        boxShadow: boxShadow,
      ),
      child: child,
    );

    if (blurSigma > 0) {
      content = ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: content,
        ),
      );
    }

    if (margin != null) {
      content = Padding(padding: margin!, child: content);
    }

    return content;
  }
}

/// A liquid-glass interactive button with scale hover physics,
/// gold specular glow, and smooth animations.
class RoyalLiquidGlassButton extends StatefulWidget {
  const RoyalLiquidGlassButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.isGold = true,
    this.isCompact = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isGold;
  final bool isCompact;

  @override
  State<RoyalLiquidGlassButton> createState() => _RoyalLiquidGlassButtonState();
}

class _RoyalLiquidGlassButtonState extends State<RoyalLiquidGlassButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final double scale = _isPressed
        ? 0.97
        : (_isHovered ? 1.02 : 1.0);

    final bgFill = widget.isGold
        ? (isDark
            ? (_isHovered ? const Color(0x33C5A04A) : const Color(0x1AC5A04A))
            : (_isHovered ? const Color(0x26C5A04A) : const Color(0x14C5A04A)))
        : (isDark
            ? (_isHovered ? const Color(0x26FFFFFF) : const Color(0x14FFFFFF))
            : (_isHovered ? const Color(0x1A101B3B) : const Color(0x0D101B3B)));

    final borderColor = widget.isGold
        ? (isDark
            ? (_isHovered ? RoyalColors.royalGold : RoyalColors.glassGoldBorder)
            : (_isHovered ? const Color(0xFF8A6715) : const Color(0xFFC5A04A)))
        : (isDark ? RoyalColors.glassWhiteBorder : RoyalColors.ivoryBorder);

    final labelColor = widget.isGold
        ? (isDark ? RoyalColors.champagne : const Color(0xFF0B1120))
        : (isDark ? RoyalColors.pearlWhite : RoyalColors.midnightNavy);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: EdgeInsets.symmetric(
              horizontal: widget.isCompact ? 14 : 20,
              vertical: widget.isCompact ? 8 : 12,
            ),
            decoration: BoxDecoration(
              color: bgFill,
              borderRadius: BorderRadius.circular(widget.isCompact ? 12 : 16),
              border: Border.all(color: borderColor, width: 1.2),
              boxShadow: _isHovered
                  ? (isDark
                      ? RoyalShadows.goldGlow
                      : [
                          BoxShadow(
                            color: const Color(0xFFC5A04A).withValues(alpha: 0.30),
                            blurRadius: 14,
                            offset: const Offset(0, 3),
                          ),
                        ])
                  : RoyalShadows.glassButton,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.icon,
                  size: widget.isCompact ? 16 : 18,
                  color: labelColor,
                ),
                const SizedBox(width: 8),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: widget.isCompact ? 12 : 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                    color: labelColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The Liquid Glass Search Bar featuring backdrop blur sigma 16,
/// gold focus glow, progress indicator, and clear button.
class LiquidGlassSearchBar extends StatefulWidget {
  const LiquidGlassSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    this.hintText = "Search by subject, acronym (e.g. 'WT', 'OS')...",
    this.isLoading = false,
    this.onClear,
    this.focusNode,
    this.onSubmitted,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String hintText;
  final bool isLoading;
  final VoidCallback? onClear;
  final FocusNode? focusNode;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;

  @override
  State<LiquidGlassSearchBar> createState() => _LiquidGlassSearchBarState();
}

class _LiquidGlassSearchBarState extends State<LiquidGlassSearchBar> {
  late final FocusNode _internalFocusNode;
  bool _isFocused = false;
  bool _isHovered = false;

  FocusNode get _effectiveFocusNode => widget.focusNode ?? _internalFocusNode;

  @override
  void initState() {
    super.initState();
    _internalFocusNode = FocusNode();
    _effectiveFocusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _effectiveFocusNode.removeListener(_handleFocusChange);
    if (widget.focusNode == null) {
      _internalFocusNode.dispose();
    }
    super.dispose();
  }

  void _handleFocusChange() {
    if (mounted) {
      setState(() {
        _isFocused = _effectiveFocusNode.hasFocus;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isActive = _isFocused || _isHovered;

    final bgFill = isDark
        ? (isActive ? const Color(0xE60D152A) : const Color(0xCC0B1120))
        : (isActive ? const Color(0xF2FFFFFF) : const Color(0xD9FFFFFF));

    final borderColor = isActive
        ? RoyalColors.royalGold
        : (isDark ? const Color(0x33C5A04A) : const Color(0x40C5A04A));

    final borderWidth = isActive ? 1.4 : 1.0;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              color: bgFill,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor, width: borderWidth),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: const Color(0xFFC5A04A).withValues(
                          alpha: isDark ? 0.25 : 0.18,
                        ),
                        blurRadius: 18,
                        spreadRadius: 1,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  child: Row(
                    children: [
                      Icon(
                        Icons.search_rounded,
                        size: 20,
                        color: isActive
                            ? RoyalColors.metallicGold
                            : (isDark ? const Color(0xFF8A99AD) : const Color(0xFF64748B)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: widget.controller,
                          focusNode: _effectiveFocusNode,
                          autofocus: widget.autofocus,
                          onChanged: widget.onChanged,
                          onSubmitted: widget.onSubmitted,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isDark ? RoyalColors.pearlWhite : RoyalColors.midnightNavy,
                          ),
                          cursorColor: RoyalColors.metallicGold,
                          decoration: InputDecoration(
                            hintText: widget.hintText,
                            hintStyle: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: isDark ? const Color(0xFF6B7A90) : const Color(0xFF7A8A9E),
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      if (widget.isLoading) ...[
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: RoyalColors.metallicGold,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ] else if (widget.controller.text.isNotEmpty) ...[
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18),
                          color: isDark ? const Color(0xFF8A99AD) : const Color(0xFF64748B),
                          onPressed: () {
                            widget.controller.clear();
                            widget.onChanged('');
                            widget.onClear?.call();
                          },
                          splashRadius: 16,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 4),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

