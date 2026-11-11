import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/models/offline_document_model.dart';
import '../../../core/theme/animated_glass_background.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/royal_design_system.dart';
import '../../../widgets/empty_state_view.dart';
import '../../../widgets/noteshub_app_bar.dart';
import '../../../widgets/noteshub_deck_cards.dart';
import '../../pdf_viewer/presentation/pdf_viewer_screen.dart';
import '../logic/download_cubit.dart';
import '../logic/download_state.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<DownloadCubit>().loadLibrary();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _confirmDelete(BuildContext context, OfflineDocumentModel doc) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) {
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
              Text(
                'Remove Download?',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: isDark ? RoyalColors.pearlWhite : RoyalColors.midnightNavy,
                ),
              ),
            ],
          ),
          content: Text(
            'Remove "${doc.name}" from local offline storage? The local file will be deleted to free up disk space, but the original document remains safe in NOTEShub.',
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: isDark ? RoyalColors.textSlateMuted : RoyalColors.textNavyMuted,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: isDark ? RoyalColors.textSlateMuted : RoyalColors.textNavyMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                context.read<DownloadCubit>().deleteOfflineDocument(doc.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Removed "${doc.name}" from offline storage.'),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: isDark ? const Color(0xFF101B3B) : RoyalColors.midnightNavy,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              ),
              child: const Text('Remove', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        );
      },
    );
  }

  void _confirmClearAll(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) {
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
                  Icons.delete_sweep_rounded,
                  color: Color(0xFFEF4444),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Clear All Downloads?',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: isDark ? RoyalColors.pearlWhite : RoyalColors.midnightNavy,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'This will delete all locally downloaded documents from this device to free up storage. You can re-download them anytime from NOTEShub.',
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: isDark ? RoyalColors.textSlateMuted : RoyalColors.textNavyMuted,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: isDark ? RoyalColors.textSlateMuted : RoyalColors.textNavyMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                context.read<DownloadCubit>().clearAll();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('All local offline documents cleared.'),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: isDark ? const Color(0xFF101B3B) : RoyalColors.midnightNavy,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              ),
              child: const Text('Clear All', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // Ambient background
          const Positioned.fill(
            child: PremiumAnimatedGlassBackground(),
          ),

          // Content
          Positioned.fill(
            child: SafeArea(
              child: Column(
                children: [
                  // Royal Academic App Bar
                  NotesHubAppBar(
                    title: 'Offline Study Library',
                    subtitle: 'Locally cached documents available without internet',
                    actions: [
                      BlocBuilder<DownloadCubit, DownloadState>(
                        builder: (context, state) {
                          if (state.allDocuments.isEmpty) return const SizedBox.shrink();

                          return IconButton(
                            icon: const Icon(Icons.delete_sweep_rounded, size: 20),
                            color: const Color(0xFFEF4444),
                            tooltip: 'Clear all downloads',
                            onPressed: () => _confirmClearAll(context),
                          );
                        },
                      ),
                    ],
                  ),

                  // Main Content
                  Expanded(
                    child: BlocConsumer<DownloadCubit, DownloadState>(
                      listener: (context, state) {
                        if (state.error != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(state.error!),
                              backgroundColor: const Color(0xFFDC2626),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      builder: (context, state) {
                        if (state.isLoading) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: RoyalColors.royalGold,
                            ),
                          );
                        }

                        return Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: AppConstants.maxWideContentWidth,
                            ),
                            child: Column(
                              children: [
                                const SizedBox(height: 12),

                                // Storage Quota Metric Card
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: _buildStorageQuotaBar(context, state, isDark),
                                ),

                                const SizedBox(height: 12),

                                // Search & Filter controls
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: _buildFilterControls(context, state, isDark),
                                ),

                                const SizedBox(height: 10),

                                // Document list
                                Expanded(
                                  child: state.allDocuments.isEmpty
                                      ? _buildEmptyLibrary()
                                      : state.documents.isEmpty
                                          ? _buildNoFilterMatches()
                                          : _buildDocumentList(context, state.documents),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
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

  Widget _buildStorageQuotaBar(BuildContext context, DownloadState state, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xCC0B1224) : const Color(0xF2FAF7F0),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? RoyalColors.glassGoldBorder : RoyalColors.ivoryBorder,
        ),
        boxShadow: isDark
            ? const [
                BoxShadow(
                  color: Color(0x26000000),
                  blurRadius: 10,
                  offset: Offset(0, 3),
                ),
              ]
            : RoyalShadows.subtleCard,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
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
            child: const Center(
              child: Icon(
                Icons.folder_special_rounded,
                size: 22,
                color: RoyalColors.midnightNavy,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Offline Storage Used',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark ? RoyalColors.pearlWhite : RoyalColors.midnightNavy,
                      ),
                    ),
                    ShaderMask(
                      shaderCallback: (bounds) => RoyalGradients.goldShimmer.createShader(bounds),
                      child: Text(
                        state.formattedTotalStorage,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${state.allDocuments.length} document${state.allDocuments.length == 1 ? '' : 's'} available offline without an active internet connection.',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isDark ? RoyalColors.textSlateMuted : RoyalColors.textNavyMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterControls(BuildContext context, DownloadState state, bool isDark) {
    return Column(
      children: [
        // Filter input
        LiquidGlassSearchBar(
          controller: _searchController,
          hintText: 'Filter offline notes...',
          onChanged: (val) => context.read<DownloadCubit>().search(val),
          onClear: () {
            _searchController.clear();
            context.read<DownloadCubit>().search('');
          },
        ),

        const SizedBox(height: 10),

        // Semester pills
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _buildSemesterPill(
                label: 'All Semesters',
                isSelected: state.semesterFilter == null,
                onTap: () => context.read<DownloadCubit>().filterBySemester(null),
                isDark: isDark,
              ),
              ...[4, 5].map((sem) {
                return _buildSemesterPill(
                  label: 'Semester $sem',
                  isSelected: state.semesterFilter == sem,
                  onTap: () => context.read<DownloadCubit>().filterBySemester(sem),
                  isDark: isDark,
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSemesterPill({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              gradient: isSelected ? RoyalGradients.metallicGold : null,
              color: isSelected
                  ? null
                  : (isDark ? const Color(0x33101B3B) : const Color(0xB3FAF7F0)),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? RoyalColors.royalGold
                    : (isDark ? RoyalColors.glassGoldBorder : RoyalColors.ivoryBorder),
                width: isSelected ? 1.4 : 1.0,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: RoyalColors.royalGold.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected
                    ? RoyalColors.midnightNavy
                    : (isDark ? RoyalColors.pearlWhite : RoyalColors.midnightNavy),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentList(
      BuildContext context, List<OfflineDocumentModel> documents) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: documents.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final doc = documents[index];
        return NotesHubResourceCard(
          title: doc.name,
          moduleNumber: doc.module,
          categoryType: doc.type,
          isDownloaded: true,
          fileMetadata: 'Sem ${doc.semester} • ${doc.formattedSize}',
          onView: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PdfViewerScreen(
                  title: doc.name,
                  localPath: doc.localPath,
                  pdfUrl: doc.url,
                  fileModel: doc.toFileModel(),
                ),
              ),
            );
          },
          onDownload: () => _confirmDelete(context, doc),
          onDelete: () => _confirmDelete(context, doc),
        );
      },
    );
  }

  Widget _buildEmptyLibrary() {
    return const EmptyStateView(
      icon: Icons.cloud_download_outlined,
      title: 'No Offline Documents',
      message: 'Download lecture notes, question banks, and reference material from any subject to study offline without internet access.',
    );
  }

  Widget _buildNoFilterMatches() {
    return const EmptyStateView(
      icon: Icons.search_off_rounded,
      title: 'No Matching Offline Notes',
      message: 'Try adjusting your search query or semester filter to locate your saved notes.',
    );
  }
}
