import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/models/update_info_model.dart';
import '../../../core/services/update_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/file_utils.dart';

/// Royal Academic Glassmorphism update dialog presenting release notes,
/// download progress, and package installer handoff.
class UpdateDialog extends StatefulWidget {
  final UpdateInfoModel updateInfo;
  final String currentVersion;
  final UpdateService updateService;

  const UpdateDialog({
    super.key,
    required this.updateInfo,
    required this.currentVersion,
    required this.updateService,
  });

  /// Static helper to present the dialog modally.
  static Future<void> show(
    BuildContext context, {
    required UpdateInfoModel updateInfo,
    required String currentVersion,
    required UpdateService updateService,
  }) {
    UpdateService.markPromptedThisSession();
    return showDialog<void>(
      context: context,
      barrierDismissible: !updateInfo.forceUpdate,
      builder: (ctx) => UpdateDialog(
        updateInfo: updateInfo,
        currentVersion: currentVersion,
        updateService: updateService,
      ),
    );
  }

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  bool _isDownloading = false;
  double _progress = 0.0;
  int _receivedBytes = 0;
  int _totalBytes = 0;
  String? _errorMessage;
  String? _infoBannerMessage;
  CancelToken? _cancelToken;

  @override
  void dispose() {
    _cancelToken?.cancel();
    super.dispose();
  }

  Future<void> _startDownloadAndInstall() async {
    setState(() {
      _isDownloading = true;
      _progress = 0.0;
      _receivedBytes = 0;
      _totalBytes = 0;
      _errorMessage = null;
      _infoBannerMessage = null;
      _cancelToken = CancelToken();
    });

    final result = await widget.updateService.downloadAndInstall(
      update: widget.updateInfo,
      cancelToken: _cancelToken,
      onProgress: (received, total) {
        if (!mounted) return;
        setState(() {
          _receivedBytes = received;
          _totalBytes = total;
          if (total > 0) {
            _progress = (received / total).clamp(0.0, 1.0);
          }
        });
      },
    );

    if (!mounted) return;

    if (result.status == InstallLaunchStatus.launched) {
      if (!widget.updateInfo.forceUpdate) {
        Navigator.of(context).pop();
      } else {
        setState(() {
          _isDownloading = false;
          _infoBannerMessage = 'Package installer launched. Please follow the on-screen prompts to complete the update.';
        });
      }
    } else if (result.status == InstallLaunchStatus.permissionRequired) {
      setState(() {
        _isDownloading = false;
        _infoBannerMessage =
            'Permission needed: Please enable "Install unknown apps" for NOTEShub in Android Settings to apply the update.';
      });
    } else {
      setState(() {
        _isDownloading = false;
        _errorMessage = result.message;
      });
    }
  }

  void _cancelDownload() {
    _cancelToken?.cancel();
    setState(() {
      _isDownloading = false;
      _progress = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMandatory = widget.updateInfo.forceUpdate;

    return PopScope(
      canPop: !isMandatory && !_isDownloading,
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 460),
              decoration: BoxDecoration(
                color: RoyalColors.midnightNavyDark.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isMandatory
                      ? RoyalColors.antiqueGold.withValues(alpha: 0.6)
                      : RoyalColors.glassGoldBorder,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.55),
                    blurRadius: 30,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Ambient Banner
                  _buildHeader(isMandatory),

                  // Scrollable Body
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Version Comparison Cards
                          _buildVersionBadges(),
                          const SizedBox(height: 16),

                          // Release Notes Section
                          const Text(
                            'What\'s New',
                            style: TextStyle(
                              color: RoyalColors.champagne,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildReleaseNotesContainer(),

                          // Status / Progress / Error banners
                          if (_isDownloading) ...[
                            const SizedBox(height: 16),
                            _buildProgressSection(),
                          ],
                          if (_infoBannerMessage != null) ...[
                            const SizedBox(height: 14),
                            _buildBanner(
                              icon: LucideIcons.info,
                              message: _infoBannerMessage!,
                              isWarning: true,
                            ),
                          ],
                          if (_errorMessage != null) ...[
                            const SizedBox(height: 14),
                            _buildBanner(
                              icon: LucideIcons.alertCircle,
                              message: _errorMessage!,
                              isWarning: false,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // Action Button Footer
                  _buildFooter(isMandatory),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isMandatory) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(
        color: RoyalColors.midnightNavy.withValues(alpha: 0.6),
        border: Border(
          bottom: BorderSide(
            color: RoyalColors.glassWhite,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isMandatory
                  ? const Color(0xFFF59E0B).withValues(alpha: 0.15)
                  : RoyalColors.royalGold.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isMandatory
                    ? const Color(0xFFF59E0B).withValues(alpha: 0.4)
                    : RoyalColors.royalGold.withValues(alpha: 0.4),
              ),
            ),
            child: Icon(
              isMandatory ? LucideIcons.alertTriangle : LucideIcons.sparkles,
              color: isMandatory ? const Color(0xFFF59E0B) : RoyalColors.royalGold,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    const Text(
                      'Update Available',
                      style: TextStyle(
                        color: RoyalColors.textWhite,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    if (isMandatory)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDC2626).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: const Color(0xFFDC2626).withValues(alpha: 0.5),
                          ),
                        ),
                        child: const Text(
                          'MANDATORY',
                          style: TextStyle(
                            color: Color(0xFFEF4444),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  isMandatory
                      ? 'A critical update is required to continue.'
                      : 'A new version of NOTEShub is ready to install.',
                  style: const TextStyle(
                    color: RoyalColors.textMutedDark,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVersionBadges() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: RoyalColors.midnightNavySurface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: RoyalColors.glassWhite),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildVersionCol('Current', 'v${widget.currentVersion}', false),
          const Icon(
            LucideIcons.arrowRight,
            color: RoyalColors.royalGold,
            size: 16,
          ),
          _buildVersionCol('Latest', 'v${widget.updateInfo.version}', true),
        ],
      ),
    );
  }

  Widget _buildVersionCol(String label, String value, bool isHighlight) {
    return Column(
      crossAxisAlignment: isHighlight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: RoyalColors.textSlateMuted,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: isHighlight ? RoyalColors.royalGold : RoyalColors.textWhite,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildReleaseNotesContainer() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxHeight: 160),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: RoyalColors.midnightNavySurface.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: RoyalColors.glassWhite),
      ),
      child: SingleChildScrollView(
        child: Text(
          widget.updateInfo.releaseNotes.isNotEmpty
              ? widget.updateInfo.releaseNotes
              : 'Performance optimizations and bug fixes.',
          style: const TextStyle(
            color: RoyalColors.textMutedDark,
            fontSize: 12.5,
            height: 1.45,
          ),
        ),
      ),
    );
  }

  Widget _buildProgressSection() {
    final receivedFormatted = FileUtils.formatBytes(_receivedBytes);
    final totalFormatted = _totalBytes > 0 ? FileUtils.formatBytes(_totalBytes) : '...';
    final percentage = (_progress * 100).toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Downloading update ($percentage%)...',
              style: const TextStyle(
                color: RoyalColors.champagne,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '$receivedFormatted / $totalFormatted',
              style: const TextStyle(
                color: RoyalColors.textSlateMuted,
                fontSize: 11,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: _progress > 0 ? _progress : null,
            minHeight: 6,
            backgroundColor: RoyalColors.midnightNavySurface,
            valueColor: const AlwaysStoppedAnimation<Color>(RoyalColors.royalGold),
          ),
        ),
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: _cancelDownload,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(50, 24),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Cancel Download',
              style: TextStyle(
                color: RoyalColors.errorRedDark,
                fontSize: 11,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBanner({
    required IconData icon,
    required String message,
    required bool isWarning,
  }) {
    final primaryColor = isWarning ? const Color(0xFFF59E0B) : RoyalColors.errorRedDark;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: primaryColor.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: primaryColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: primaryColor,
                fontSize: 11.5,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(bool isMandatory) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        color: RoyalColors.midnightNavy.withValues(alpha: 0.6),
        border: Border(
          top: BorderSide(
            color: RoyalColors.glassWhite,
            width: 1,
          ),
        ),
      ),
      child: Wrap(
        alignment: WrapAlignment.end,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 10,
        runSpacing: 8,
        children: [
          if (!isMandatory && !_isDownloading)
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: RoyalColors.textMutedDark,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
              child: const Text(
                'Remind Me Later',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ElevatedButton.icon(
            onPressed: _isDownloading ? null : _startDownloadAndInstall,
            icon: _isDownloading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(RoyalColors.midnightNavy),
                    ),
                  )
                : const Icon(LucideIcons.downloadCloud, size: 16),
            label: Text(
              _isDownloading
                  ? 'Downloading...'
                  : (_errorMessage != null ? 'Retry Update' : 'Download and Update'),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: RoyalColors.royalGold,
              foregroundColor: RoyalColors.midnightNavy,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
