import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/models/file_model.dart';
import '../../../core/models/subject_model.dart';
import '../../../core/repositories/file_repository.dart';
import '../../../core/repositories/subject_repository.dart';
import '../../../core/theme/animated_glass_background.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/royal_design_system.dart';
import '../../../shared/dialogs/download_options_sheet.dart';
import '../../../widgets/empty_state_view.dart';
import '../../../widgets/noteshub_app_bar.dart';
import '../../../widgets/noteshub_deck_cards.dart';
import '../../admin/presentation/upload_resource_screen.dart';
import '../../admin/presentation/widgets/delete_policy_dialog.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../downloads/logic/download_cubit.dart';
import '../../downloads/logic/download_state.dart';
import '../../pdf_viewer/presentation/pdf_viewer_screen.dart';

class SubjectDetailScreen extends StatefulWidget {
  final int semester;
  final int subject;
  final String initialSubjectName;
  final int initialModule;
  final String initialCategory;

  const SubjectDetailScreen({
    super.key,
    required this.semester,
    required this.subject,
    required this.initialSubjectName,
    this.initialModule = 1,
    this.initialCategory = FileCategory.notes,
  });

  @override
  State<SubjectDetailScreen> createState() => _SubjectDetailScreenState();
}

class _SubjectDetailScreenState extends State<SubjectDetailScreen> {
  late int _selectedModule;
  late Stream<List<FileModel>> _fileStream;
  late Stream<List<SubjectModel>> _subjectStream;

  @override
  void initState() {
    super.initState();
    _selectedModule = widget.initialModule;
    _initStreams();
  }

  void _initStreams() {
    final fileRepo = context.read<FileRepository>();
    _fileStream = fileRepo.streamModuleFiles(
      semester: widget.semester,
      subject: widget.subject,
      module: _selectedModule,
    );

    final subjectRepo = context.read<SubjectRepository>();
    _subjectStream = subjectRepo.streamSubjects(widget.semester);
  }

  void _onModuleChanged(int module) {
    if (_selectedModule == module) return;
    setState(() {
      _selectedModule = module;
      _initStreams();
    });
  }

  Future<void> _showRenameSubjectDialog(String currentName, String? docId) async {
    final formKey = GlobalKey<FormState>();
    final controller = TextEditingController(text: currentName);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
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
                Icons.edit_note_rounded,
                color: RoyalColors.midnightNavy,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Rename Subject',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: isDark ? RoyalColors.pearlWhite : RoyalColors.midnightNavy,
              ),
            ),
          ],
        ),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            style: TextStyle(
              color: isDark ? RoyalColors.pearlWhite : RoyalColors.midnightNavy,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              labelText: 'Subject Name',
              labelStyle: TextStyle(
                color: isDark ? RoyalColors.champagne : const Color(0xFF8A6715),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: isDark ? RoyalColors.glassGoldBorder : RoyalColors.ivoryBorder,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: RoyalColors.royalGold,
                  width: 1.8,
                ),
              ),
            ),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Cannot be empty' : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
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
            child: ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) Navigator.of(ctx).pop(true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: RoyalColors.midnightNavy,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: const Text(
                'Save',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );

    if (result == true) {
      final newName = controller.text.trim();
      if (newName == currentName) return;
      if (!mounted) return;
      try {
        await context.read<SubjectRepository>().saveSubjectName(
              semester: widget.semester,
              subjectId: widget.subject,
              newName: newName,
              existingDocId: docId,
            );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Subject renamed successfully!'),
            backgroundColor: RoyalColors.emeraldActive,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error renaming subject: $e'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  Future<void> _showRenameFileDialog(FileModel file) async {
    final formKey = GlobalKey<FormState>();
    final controller = TextEditingController(text: file.name);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
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
                Icons.edit_note_rounded,
                color: RoyalColors.midnightNavy,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Rename Resource',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: isDark ? RoyalColors.pearlWhite : RoyalColors.midnightNavy,
              ),
            ),
          ],
        ),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            style: TextStyle(
              color: isDark ? RoyalColors.pearlWhite : RoyalColors.midnightNavy,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              labelText: 'Resource Name',
              labelStyle: TextStyle(
                color: isDark ? RoyalColors.champagne : const Color(0xFF8A6715),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: isDark ? RoyalColors.glassGoldBorder : RoyalColors.ivoryBorder,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: RoyalColors.royalGold,
                  width: 1.8,
                ),
              ),
            ),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Cannot be empty' : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
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
            child: ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) Navigator.of(ctx).pop(true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: RoyalColors.midnightNavy,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: const Text(
                'Save',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );

    if (result == true) {
      final newName = controller.text.trim();
      if (newName == file.name) return;
      if (!mounted) return;
      try {
        await context.read<FileRepository>().updateFileName(
              docId: file.id,
              newName: newName,
            );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Resource renamed successfully!'),
            backgroundColor: RoyalColors.emeraldActive,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error renaming resource: $e'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  Future<void> _handleDeleteFile(FileModel file) async {
    final confirmed = await ConfirmDeleteResourceDialog.show(
      context,
      resourceName: file.name,
      onConfirmDelete: () async {
        // 1. Delete document from Firestore
        await context.read<FileRepository>().deleteFileDoc(file.id);

        // 2. Consistent Offline Library cleanup
        if (mounted) {
          final downloadCubit = context.read<DownloadCubit>();
          if (downloadCubit.state.isFileDownloaded(file.id)) {
            await downloadCubit.deleteOfflineDocument(file.id);
          }
        }
      },
    );

    if (confirmed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Resource deleted successfully.'),
          backgroundColor: RoyalColors.emeraldActive,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return StreamBuilder<List<SubjectModel>>(
      stream: _subjectStream,
      builder: (context, snapshot) {
        String displayName = widget.initialSubjectName;
        String? docId;
        if (snapshot.hasData && snapshot.data != null) {
          for (final s in snapshot.data!) {
            if (s.subject == widget.subject) {
              displayName = s.name;
              docId = s.id;
              break;
            }
          }
        }

        return Scaffold(
          body: Stack(
            children: [
              // Atmospheric animated background
              const Positioned.fill(
                child: PremiumAnimatedGlassBackground(),
              ),

              // Content Layout
              Positioned.fill(
                child: SafeArea(
                  child: Column(
                    children: [
                      // Royal Academic App Bar
                      NotesHubAppBar(
                        title: displayName,
                        subtitle: 'Semester ${widget.semester} • Subject ${widget.subject}',
                        actions: [
                          BlocBuilder<AuthBloc, AuthState>(
                            builder: (context, authState) {
                              if (authState is Authenticated && authState.isOwner) {
                                return IconButton(
                                  icon: const Icon(Icons.edit_note_rounded, size: 20),
                                  color: RoyalColors.royalGold,
                                  tooltip: 'Rename Subject',
                                  onPressed: () => _showRenameSubjectDialog(displayName, docId),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ],
                      ),

                      // Module & Category selectors + Resource list
                      Expanded(
                        child: Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: AppConstants.maxWideContentWidth,
                            ),
                            child: Column(
                              children: [
                                const SizedBox(height: 12),

                                // 1. Module Selector Tabs (Modules 1 to 5)
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: _buildModuleSelector(isDark),
                                ),

                                const SizedBox(height: 8),

                                // 2. File Listing for selected module (Lecture Notes, Question Bank, Extra Resources one below the other)
                                Expanded(
                                  child: _buildFileList(isDark),
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
            ],
          ),

          // Contextual Admin Upload FAB
          floatingActionButton: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, authState) {
              if (authState is Authenticated && authState.isAuthor) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: RoyalGradients.metallicGold,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: RoyalColors.royalGold.withValues(alpha: 0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: FloatingActionButton.extended(
                    elevation: 0,
                    backgroundColor: Colors.transparent,
                    foregroundColor: RoyalColors.midnightNavy,
                    icon: const Icon(Icons.cloud_upload_rounded, size: 20),
                    label: Text(
                      'Upload to M$_selectedModule',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => UploadResourceScreen(
                            initialSemester: widget.semester,
                            initialSubject: widget.subject,
                            initialModule: _selectedModule,
                            initialCategory: FileCategory.notes,
                          ),
                        ),
                      );
                    },
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        );
      },
    );
  }

  Widget _buildModuleSelector(bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: List.generate(5, (index) {
          final moduleNum = index + 1;
          final isSelected = _selectedModule == moduleNum;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _onModuleChanged(moduleNum),
                borderRadius: BorderRadius.circular(14),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                  decoration: BoxDecoration(
                    gradient: isSelected ? RoyalGradients.metallicGold : null,
                    color: isSelected
                        ? null
                        : (isDark ? const Color(0x33101B3B) : const Color(0xB3FAF7F0)),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? RoyalColors.royalGold
                          : (isDark ? RoyalColors.glassGoldBorder : RoyalColors.ivoryBorder),
                      width: isSelected ? 1.5 : 1.0,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: RoyalColors.royalGold.withValues(alpha: 0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? RoyalColors.midnightNavy
                              : (isDark ? const Color(0x33C5A04A) : const Color(0x1AC5A04A)),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: Text(
                            'M$moduleNum',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: isSelected
                                  ? RoyalColors.champagne
                                  : (isDark ? RoyalColors.champagne : const Color(0xFF8A6715)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Module $moduleNum',
                        style: TextStyle(
                          color: isSelected
                              ? RoyalColors.midnightNavy
                              : (isDark ? RoyalColors.pearlWhite : RoyalColors.midnightNavy),
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildFileList(bool isDark) {
    return StreamBuilder<List<FileModel>>(
      stream: _fileStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: RoyalColors.royalGold,
            ),
          );
        }

        if (snapshot.hasError) {
          return EmptyStateView(
            icon: Icons.error_outline_rounded,
            title: 'Failed to load study files',
            message: snapshot.error.toString(),
            actionLabel: 'Retry',
            onAction: () => setState(() => _initStreams()),
          );
        }

        final files = snapshot.data ?? [];

        if (files.isEmpty) {
          return EmptyStateView(
            icon: Icons.folder_open_rounded,
            title: 'No Documents Yet',
            message: 'There are no uploaded materials for Module $_selectedModule yet.',
          );
        }

        final notesFiles = files
            .where((f) => f.type.toLowerCase() == FileCategory.notes || f.type.toLowerCase() == 'notes')
            .toList();
        final qbankFiles = files
            .where((f) => f.type.toLowerCase() == FileCategory.qbank || f.type.toLowerCase() == 'qbank')
            .toList();
        final extraFiles = files
            .where((f) => f.type.toLowerCase() == FileCategory.extra || f.type.toLowerCase() == 'extra')
            .toList();

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
          children: [
            // 1. Lecture Notes Section
            _buildCategorySection(
              title: 'Lecture Notes',
              icon: Icons.menu_book_rounded,
              accentColor: RoyalColors.royalGold,
              files: notesFiles,
              categoryKey: FileCategory.notes,
              isDark: isDark,
            ),

            const SizedBox(height: 20),

            // 2. Question Bank Section
            _buildCategorySection(
              title: 'Question Bank',
              icon: Icons.quiz_rounded,
              accentColor: isDark ? RoyalColors.cyanInteractive : const Color(0xFF0284C7),
              files: qbankFiles,
              categoryKey: FileCategory.qbank,
              isDark: isDark,
            ),

            const SizedBox(height: 20),

            // 3. Extra Resources Section
            _buildCategorySection(
              title: 'Extra Resources',
              icon: Icons.auto_stories_rounded,
              accentColor: RoyalColors.emeraldActive,
              files: extraFiles,
              categoryKey: FileCategory.extra,
              isDark: isDark,
            ),
          ],
        );
      },
    );
  }

  Widget _buildCategorySection({
    required String title,
    required IconData icon,
    required Color accentColor,
    required List<FileModel> files,
    required String categoryKey,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header Row
        BlocBuilder<AuthBloc, AuthState>(
          builder: (context, authState) {
            final isAuthor = authState is Authenticated && authState.isAuthor;

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: accentColor.withValues(alpha: 0.35),
                            width: 1.0,
                          ),
                        ),
                        child: Icon(icon, size: 15, color: accentColor),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: isDark ? RoyalColors.pearlWhite : RoyalColors.midnightNavy,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: accentColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          '${files.length}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: accentColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (isAuthor)
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => UploadResourceScreen(
                                initialSemester: widget.semester,
                                initialSubject: widget.subject,
                                initialModule: _selectedModule,
                                initialCategory: categoryKey,
                              ),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add_rounded, size: 15, color: accentColor),
                              const SizedBox(width: 3),
                              Text(
                                'Add',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: accentColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),

        // Files List or Empty placeholder
        if (files.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0x14101B3B) : const Color(0x66FFFFFF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark
                    ? RoyalColors.glassGoldBorder.withValues(alpha: 0.25)
                    : RoyalColors.ivoryBorder,
              ),
            ),
            child: Text(
              'No $title uploaded for Module $_selectedModule yet',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark ? RoyalColors.textSlateMuted : RoyalColors.textNavyMuted,
              ),
            ),
          )
        else
          ...files.map((file) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _buildFileItemCard(file),
              )),
      ],
    );
  }

  Widget _buildFileItemCard(FileModel file) {
    return BlocBuilder<DownloadCubit, DownloadState>(
      builder: (context, downloadState) {
        final isDownloaded = downloadState.isFileDownloaded(file.id);
        final isDownloading = downloadState.isFileDownloading(file.id);
        final downloadProgress = downloadState.getDownloadProgress(file.id);

        String? localPath;
        if (isDownloaded) {
          final offlineDoc = downloadState.allDocuments.firstWhere((d) => d.id == file.id);
          localPath = offlineDoc.localPath;
        }

        void openPdf() {
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

        return BlocBuilder<AuthBloc, AuthState>(
          builder: (context, authState) {
            final isAuthor = authState is Authenticated && authState.isAuthor;

            return NotesHubResourceCard(
              title: file.name,
              moduleNumber: file.module,
              categoryType: file.type,
              isDownloaded: isDownloaded,
              isDownloading: isDownloading,
              downloadProgress: downloadProgress,
              onView: openPdf,
              onDownload: () => DownloadOptionsSheet.show(context, file),
              onRename: isAuthor ? () => _showRenameFileDialog(file) : null,
              onDelete: isAuthor ? () => _handleDeleteFile(file) : null,
            );
          },
        );
      },
    );
  }
}
