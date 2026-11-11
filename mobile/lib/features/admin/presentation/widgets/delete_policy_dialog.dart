import 'package:flutter/material.dart';
import '../../../../core/theme/royal_design_system.dart';

/// Confirmation dialog for deleting an academic resource from Firestore.
/// Uses Royal Academic Glassmorphism styling and prevents repeated
/// deletion requests while an operation is in progress.
class ConfirmDeleteResourceDialog extends StatefulWidget {
  final String resourceName;
  final Future<void> Function()? onConfirmDelete;

  const ConfirmDeleteResourceDialog({
    super.key,
    required this.resourceName,
    this.onConfirmDelete,
  });

  /// Displays the confirmation dialog.
  /// If [onConfirmDelete] is provided, executes it and returns true on success.
  /// If [onConfirmDelete] is omitted, returns true when the user confirms.
  static Future<bool?> show(
    BuildContext context, {
    required String resourceName,
    Future<void> Function()? onConfirmDelete,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ConfirmDeleteResourceDialog(
        resourceName: resourceName,
        onConfirmDelete: onConfirmDelete,
      ),
    );
  }

  @override
  State<ConfirmDeleteResourceDialog> createState() => _ConfirmDeleteResourceDialogState();
}

class _ConfirmDeleteResourceDialogState extends State<ConfirmDeleteResourceDialog> {
  bool _isDeleting = false;
  String? _errorMessage;

  Future<void> _handleDelete() async {
    if (_isDeleting) return;

    if (widget.onConfirmDelete != null) {
      setState(() {
        _isDeleting = true;
        _errorMessage = null;
      });

      try {
        await widget.onConfirmDelete!();
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isDeleting = false;
            _errorMessage = e.toString().replaceFirst('Exception: ', '');
          });
        }
      }
    } else {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor: isDark ? const Color(0xF00D1630) : const Color(0xF7FAF7F0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(
          color: isDark ? RoyalColors.glassGoldBorder : RoyalColors.ivoryBorder,
          width: 1.2,
        ),
      ),
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0x26EF4444),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0x59EF4444),
              ),
            ),
            child: const Icon(
              Icons.delete_outline_rounded,
              color: Color(0xFFEF4444),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Delete Resource',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: isDark ? RoyalColors.pearlWhite : RoyalColors.midnightNavy,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text.rich(
              TextSpan(
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? RoyalColors.pearlWhite : RoyalColors.midnightNavy,
                  height: 1.4,
                ),
                children: [
                  const TextSpan(text: 'Are you sure you want to delete '),
                  TextSpan(
                    text: '"${widget.resourceName}"',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const TextSpan(text: '?'),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0x33101B3B) : const Color(0x26C5A04A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? RoyalColors.glassGoldBorder : RoyalColors.ivoryBorder,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: Color(0xFFEAB308),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This will delete the document entry from NOTEShub Firestore. '
                      'The physical storage asset is preserved in Cloudinary.',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark ? RoyalColors.champagne : const Color(0xFF8A6715),
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0x26EF4444),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0x59EF4444)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, size: 16, color: Color(0xFFEF4444)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFFEF4444),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isDeleting ? null : () => Navigator.of(context).pop(false),
          child: Text(
            'Cancel',
            style: TextStyle(
              color: isDark ? RoyalColors.textSlateMuted : RoyalColors.textNavyMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFDC2626),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFDC2626).withValues(alpha: 0.35),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: _isDeleting ? null : _handleDelete,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: _isDeleting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Delete',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                  ),
          ),
        ),
      ],
    );
  }
}

/// Backwards compatibility alias
typedef DeletePolicyDialog = ConfirmDeleteResourceDialog;
