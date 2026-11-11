import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/models/file_model.dart';
import '../../core/services/device_download_service.dart';
import '../../core/theme/royal_design_system.dart';
import '../../features/downloads/logic/download_cubit.dart';
import '../../features/downloads/logic/download_state.dart';
import '../../features/pdf_viewer/presentation/pdf_viewer_screen.dart';

class DownloadOptionsSheet extends StatefulWidget {
  final FileModel file;

  const DownloadOptionsSheet({
    super.key,
    required this.file,
  });

  static Future<void> show(BuildContext context, FileModel file) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => DownloadOptionsSheet(file: file),
    );
  }

  @override
  State<DownloadOptionsSheet> createState() => _DownloadOptionsSheetState();
}

class _DownloadOptionsSheetState extends State<DownloadOptionsSheet> {
  bool _isDeviceDownloading = false;
  double _deviceProgress = 0.0;
  CancelToken? _deviceCancelToken;

  final DeviceDownloadService _deviceDownloadService = DeviceDownloadService();

  @override
  void dispose() {
    _deviceCancelToken?.cancel('Cancelled by user.');
    super.dispose();
  }

  Future<void> _handleDeviceDownload() async {
    if (_isDeviceDownloading) return;

    setState(() {
      _isDeviceDownloading = true;
      _deviceProgress = 0.0;
      _deviceCancelToken = CancelToken();
    });

    final messenger = ScaffoldMessenger.of(context);

    try {
      final message = await _deviceDownloadService.downloadToDevice(
        file: widget.file,
        cancelToken: _deviceCancelToken,
        onProgress: (received, total) {
          if (total > 0 && mounted) {
            setState(() {
              _deviceProgress = (received / total).clamp(0.0, 1.0);
            });
          }
        },
      );

      if (!mounted) return;
      Navigator.of(context).pop();

      messenger.showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: RoyalColors.emeraldActive,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isDeviceDownloading = false;
      });

      messenger.showSnackBar(
        SnackBar(
          content: Text('Device download failed: $e'),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _handleAppDownload(BuildContext context) {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'In-app offline storage is designed for Android & iOS mobile devices. Please choose "Download to Device" on Web.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    Navigator.of(context).pop();
    context.read<DownloadCubit>().startDownload(widget.file);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Downloading "${widget.file.name}" for offline study...'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openOfflineReader(BuildContext context, String localPath) {
    Navigator.of(context).pop();
    Navigator.of(context).push(
      MaterialPageRoute(
        settings: const RouteSettings(name: '/pdf-viewer'),
        builder: (_) => PdfViewerScreen(
          title: widget.file.name,
          localPath: localPath,
          pdfUrl: widget.file.url,
          fileModel: widget.file,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocBuilder<DownloadCubit, DownloadState>(
      builder: (context, downloadState) {
        final isDownloaded = downloadState.isFileDownloaded(widget.file.id);
        final isDownloading = downloadState.isFileDownloading(widget.file.id);
        final appProgress = downloadState.getDownloadProgress(widget.file.id) ?? 0.0;

        final offlineDoc = isDownloaded
            ? downloadState.allDocuments.firstWhere((d) => d.id == widget.file.id)
            : null;

        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xF20B1224) : const Color(0xF7FAF7F0),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(
                  top: BorderSide(
                    color: isDark ? RoyalColors.glassGoldBorder : RoyalColors.ivoryBorder,
                    width: 1.2,
                  ),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        gradient: RoyalGradients.metallicGold,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Title Row
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: RoyalGradients.metallicGold,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: RoyalColors.royalGold.withValues(alpha: 0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.download_rounded,
                          size: 20,
                          color: RoyalColors.midnightNavy,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Download Document',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: isDark ? RoyalColors.pearlWhite : RoyalColors.midnightNavy,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.file.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? RoyalColors.textSlateMuted : RoyalColors.textNavyMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  // 1. EXACT LABEL: Download in App
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: isDownloading
                          ? null
                          : isDownloaded && offlineDoc != null
                              ? () => _openOfflineReader(context, offlineDoc.localPath)
                              : () => _handleAppDownload(context),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0x33101B3B) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDownloaded
                                ? RoyalColors.emeraldActive.withValues(alpha: 0.5)
                                : (isDark ? RoyalColors.glassGoldBorder : RoyalColors.ivoryBorder),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: (isDownloaded ? RoyalColors.emeraldActive : RoyalColors.royalGold)
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                isDownloaded ? Icons.check_circle_rounded : Icons.offline_pin_rounded,
                                size: 22,
                                color: isDownloaded ? RoyalColors.emeraldActive : RoyalColors.royalGold,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Download in App',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: isDownloaded
                                          ? RoyalColors.emeraldActive
                                          : (isDark ? RoyalColors.pearlWhite : RoyalColors.midnightNavy),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    isDownloaded
                                        ? 'Already saved in Offline Library • Tap to read'
                                        : isDownloading
                                            ? 'Downloading (${(appProgress * 100).toInt()}%)...'
                                            : 'Save to in-app Offline Library for reading without internet',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: isDark ? RoyalColors.textSlateMuted : RoyalColors.textNavyMuted,
                                    ),
                                  ),
                                  if (isDownloading) ...[
                                    const SizedBox(height: 8),
                                    LinearProgressIndicator(
                                      value: appProgress > 0 ? appProgress : null,
                                      backgroundColor: isDark ? const Color(0x33C5A04A) : const Color(0x1AC5A04A),
                                      color: RoyalColors.royalGold,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Icon(
                              isDownloaded ? Icons.menu_book_rounded : Icons.arrow_forward_ios_rounded,
                              size: 15,
                              color: isDownloaded ? RoyalColors.emeraldActive : RoyalColors.royalGold,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 2. EXACT LABEL: Download to Device
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _isDeviceDownloading ? null : _handleDeviceDownload,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0x33101B3B) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? RoyalColors.glassGoldBorder : RoyalColors.ivoryBorder,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: (isDark ? RoyalColors.cyanInteractive : const Color(0xFF0284C7))
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.cloud_download_rounded,
                                size: 22,
                                color: isDark ? RoyalColors.cyanInteractive : const Color(0xFF0284C7),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Download to Device',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: isDark ? RoyalColors.pearlWhite : RoyalColors.midnightNavy,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _isDeviceDownloading
                                        ? 'Saving to device (${(_deviceProgress * 100).toInt()}%)...'
                                        : 'Save to device Downloads folder / Files app',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: isDark ? RoyalColors.textSlateMuted : RoyalColors.textNavyMuted,
                                    ),
                                  ),
                                  if (_isDeviceDownloading) ...[
                                    const SizedBox(height: 8),
                                    LinearProgressIndicator(
                                      value: _deviceProgress > 0 ? _deviceProgress : null,
                                      backgroundColor: isDark ? const Color(0x3338BDF8) : const Color(0x1A0284C7),
                                      color: isDark ? RoyalColors.cyanInteractive : const Color(0xFF0284C7),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 15,
                              color: RoyalColors.royalGold,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
