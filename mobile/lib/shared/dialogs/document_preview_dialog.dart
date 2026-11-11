import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/models/file_model.dart';
import '../../core/theme/royal_design_system.dart';
import '../../features/downloads/logic/download_cubit.dart';
import '../../features/pdf_viewer/presentation/pdf_viewer_screen.dart';
import 'download_options_sheet.dart';

class DocumentPreviewDialog extends StatelessWidget {
  final FileModel file;

  const DocumentPreviewDialog({
    super.key,
    required this.file,
  });

  static Future<void> show(BuildContext context, FileModel file) {
    return showDialog(
      context: context,
      builder: (_) => DocumentPreviewDialog(file: file),
    );
  }

  void _openInApp(BuildContext context) {
    Navigator.of(context).pop();

    final downloadCubit = context.read<DownloadCubit>();
    final isDownloaded = downloadCubit.state.isFileDownloaded(file.id);
    String? localPath;

    if (isDownloaded) {
      final offlineDoc = downloadCubit.state.allDocuments.firstWhere((d) => d.id == file.id);
      localPath = offlineDoc.localPath;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PdfViewerScreen(
          title: file.name,
          pdfUrl: file.url,
          localPath: localPath,
          fileModel: file,
        ),
      ),
    );
  }

  Future<void> _openExternal(BuildContext context) async {
    Navigator.of(context).pop();
    final uri = Uri.parse(file.url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open document URL.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
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
              gradient: RoyalGradients.metallicGold,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: RoyalColors.royalGold.withValues(alpha: 0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.description_rounded,
              color: RoyalColors.midnightNavy,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Document Details',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: isDark ? RoyalColors.pearlWhite : RoyalColors.midnightNavy,
                  ),
                ),
                Text(
                  'Semester ${file.semester} • Module ${file.module}',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? RoyalColors.champagne : const Color(0xFF8A6715),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _openExternal(context),
            icon: const Icon(Icons.open_in_browser_rounded, size: 18),
            color: RoyalColors.royalGold,
            tooltip: 'Open in browser',
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0x33101B3B) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? RoyalColors.glassGoldBorder : RoyalColors.ivoryBorder,
              ),
            ),
            child: Text(
              file.name,
              style: TextStyle(
                color: isDark ? RoyalColors.pearlWhite : RoyalColors.midnightNavy,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
      actions: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  DownloadOptionsSheet.show(context, file);
                },
                icon: const Icon(Icons.download_rounded, size: 16),
                label: const Text('Download'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: isDark ? RoyalColors.pearlWhite : RoyalColors.midnightNavy,
                  side: BorderSide(
                    color: isDark ? RoyalColors.glassGoldBorder : RoyalColors.ivoryBorder,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
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
                child: ElevatedButton.icon(
                  onPressed: () => _openInApp(context),
                  icon: const Icon(Icons.visibility_rounded, size: 16),
                  label: const Text('Read PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: RoyalColors.midnightNavy,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
