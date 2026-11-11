import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/models/file_model.dart';
import '../../../core/models/subject_model.dart';
import '../../../core/repositories/file_repository.dart';
import '../../../core/repositories/subject_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../downloads/logic/download_cubit.dart';
import '../../pdf_viewer/presentation/pdf_viewer_screen.dart';
import 'upload_resource_screen.dart';
import 'widgets/delete_policy_dialog.dart';

/// Admin Resources Management Screen
/// Allows administrators to browse, filter, search, preview,
/// and rename uploaded academic resources across semesters.
class AdminResourcesScreen extends StatefulWidget {
  final int? initialSemester;
  final int? initialSubject;

  const AdminResourcesScreen({
    super.key,
    this.initialSemester,
    this.initialSubject,
  });

  @override
  State<AdminResourcesScreen> createState() => _AdminResourcesScreenState();
}

class _AdminResourcesScreenState extends State<AdminResourcesScreen> {
  final _searchController = TextEditingController();

  bool _isLoading = true;
  String? _error;
  List<FileModel> _allFiles = [];
  Map<String, String> _subjectNameMap = {};

  // Filter state
  int? _filterSemester; // null means 'All'
  int? _filterSubject; // null means 'All'
  int? _filterModule; // null means 'All'
  String? _filterCategory; // null means 'All'
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _filterSemester = widget.initialSemester;
    _filterSubject = widget.initialSubject;
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final fileRepo = context.read<FileRepository>();
      final subjectRepo = context.read<SubjectRepository>();

      final results = await Future.wait([
        fileRepo.getAllFiles(),
        subjectRepo.getAllSubjects(),
      ]);

      final files = results[0] as List<FileModel>;
      final subjects = results[1] as List<SubjectModel>;

      final map = <String, String>{};
      for (final s in subjects) {
        map['${s.semester}_${s.subject}'] = s.name;
      }

      if (!mounted) return;
      setState(() {
        _allFiles = files;
        _subjectNameMap = map;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load resources: $e';
        _isLoading = false;
      });
    }
  }

  List<FileModel> get _filteredFiles {
    return _allFiles.where((file) {
      if (_filterSemester != null && file.semester != _filterSemester) {
        return false;
      }
      if (_filterSubject != null && file.subject != _filterSubject) {
        return false;
      }
      if (_filterModule != null && file.module != _filterModule) {
        return false;
      }
      if (_filterCategory != null &&
          file.type.toLowerCase() != _filterCategory!.toLowerCase()) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final nameMatch = file.name.toLowerCase().contains(query);
        final subName = _subjectNameMap['${file.semester}_${file.subject}']?.toLowerCase() ?? '';
        final subjectMatch = subName.contains(query);
        if (!nameMatch && !subjectMatch) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  Future<void> _showRenameDialog(FileModel file) async {
    final formKey = GlobalKey<FormState>();
    final controller = TextEditingController(text: file.name);

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.surfaceBorder),
        ),
        title: const Row(
          children: [
            Icon(LucideIcons.edit2, color: AppColors.primary, size: 20),
            SizedBox(width: 10),
            Text(
              'Rename Resource',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sem ${file.semester} • Subject ${file.subject} • Module ${file.module}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryLight,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: controller,
                autofocus: true,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Resource Name',
                  filled: true,
                  fillColor: AppColors.surfaceLight,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.surfaceBorder),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Resource name cannot be empty.';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(ctx).pop(true);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == true) {
      final newName = controller.text.trim();
      if (newName == file.name) return;
      if (!mounted) return;

      try {
        final repo = context.read<FileRepository>();
        await repo.updateFileName(docId: file.id, newName: newName);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Resource renamed successfully!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _loadData();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to rename resource: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
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
        await context.read<FileRepository>().deleteFileDoc(file.id);
        if (mounted) {
          try {
            final downloadCubit = context.read<DownloadCubit>();
            if (downloadCubit.state.isFileDownloaded(file.id)) {
              await downloadCubit.deleteOfflineDocument(file.id);
            }
          } catch (_) {}
        }
      },
    );

    if (confirmed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Resource deleted successfully.'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredFiles;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Manage Resources',
          style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 19),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(LucideIcons.uploadCloud, size: 20),
        label: const Text('Upload Resource', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            settings: const RouteSettings(name: '/admin/upload'),
            builder: (_) => UploadResourceScreen(
              initialSemester: _filterSemester,
              initialSubject: _filterSubject,
              initialModule: _filterModule,
              initialCategory: _filterCategory,
            ),
          ),
        ).then((_) => _loadData()),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: Column(
            children: [
              _buildSearchAndFilters(),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                    : _error != null
                        ? _buildErrorView()
                        : _buildFileList(filtered),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.surfaceBorder)),
      ),
      child: Column(
        children: [
          // Search TextField
          TextField(
            controller: _searchController,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search resources by name or subject...',
              hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
              prefixIcon: const Icon(LucideIcons.search, size: 18, color: AppColors.textMuted),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18, color: AppColors.textMuted),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
              filled: true,
              fillColor: AppColors.surfaceLight,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.surfaceBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.surfaceBorder),
              ),
            ),
            onChanged: (val) {
              setState(() {
                _searchQuery = val.trim();
              });
            },
          ),
          const SizedBox(height: 10),
          // Filter Chips Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Semester Filter Dropdown
                _buildFilterChip<int?>(
                  label: _filterSemester == null ? 'All Semesters' : 'Sem $_filterSemester',
                  icon: LucideIcons.layers,
                  isSelected: _filterSemester != null,
                  onTap: () => _pickSemesterFilter(),
                ),
                const SizedBox(width: 8),
                // Module Filter
                _buildFilterChip<int?>(
                  label: _filterModule == null ? 'All Modules' : 'Module $_filterModule',
                  icon: LucideIcons.bookOpen,
                  isSelected: _filterModule != null,
                  onTap: () => _pickModuleFilter(),
                ),
                const SizedBox(width: 8),
                // Category Filter
                _buildFilterChip<String?>(
                  label: _filterCategory == null ? 'All Categories' : _filterCategory!.toUpperCase(),
                  icon: LucideIcons.tag,
                  isSelected: _filterCategory != null,
                  onTap: () => _pickCategoryFilter(),
                ),
                if (_filterSemester != null || _filterModule != null || _filterCategory != null || _searchQuery.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(LucideIcons.rotateCcw, size: 14, color: AppColors.error),
                    label: const Text('Reset', style: TextStyle(color: AppColors.error, fontSize: 12)),
                    onPressed: () {
                      setState(() {
                        _filterSemester = null;
                        _filterSubject = null;
                        _filterModule = null;
                        _filterCategory = null;
                        _searchQuery = '';
                        _searchController.clear();
                      });
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip<T>({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withValues(alpha: 0.15) : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.surfaceBorder,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: isSelected ? AppColors.primaryLight : AppColors.textMuted),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? AppColors.primaryLight : AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.arrow_drop_down, size: 16, color: isSelected ? AppColors.primaryLight : AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }

  void _pickSemesterFilter() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                title: const Text('All Semesters'),
                selected: _filterSemester == null,
                onTap: () {
                  setState(() => _filterSemester = null);
                  Navigator.of(ctx).pop();
                },
              ),
              ...List.generate(8, (i) => i + 1).map((sem) => ListTile(
                    title: Text('Semester $sem'),
                    selected: _filterSemester == sem,
                    onTap: () {
                      setState(() => _filterSemester = sem);
                      Navigator.of(ctx).pop();
                    },
                  )),
            ],
          ),
        );
      },
    );
  }

  void _pickModuleFilter() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                title: const Text('All Modules'),
                selected: _filterModule == null,
                onTap: () {
                  setState(() => _filterModule = null);
                  Navigator.of(ctx).pop();
                },
              ),
              ...List.generate(5, (i) => i + 1).map((mod) => ListTile(
                    title: Text('Module $mod'),
                    selected: _filterModule == mod,
                    onTap: () {
                      setState(() => _filterModule = mod);
                      Navigator.of(ctx).pop();
                    },
                  )),
            ],
          ),
        );
      },
    );
  }

  void _pickCategoryFilter() {
    final categories = [
      {'val': null, 'label': 'All Categories'},
      {'val': FileCategory.notes, 'label': 'Notes (notes)'},
      {'val': FileCategory.qbank, 'label': 'Question Banks (qbank)'},
      {'val': FileCategory.extra, 'label': 'Extra Resources (extra)'},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: categories.map((cat) {
              final isSel = _filterCategory == cat['val'];
              return ListTile(
                title: Text(cat['label']!),
                selected: isSel,
                onTap: () {
                  setState(() => _filterCategory = cat['val']);
                  Navigator.of(ctx).pop();
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.alertTriangle, size: 44, color: AppColors.warning),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _loadData,
              icon: const Icon(LucideIcons.refreshCw, size: 16),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileList(List<FileModel> files) {
    if (files.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.surfaceBorder),
                ),
                child: const Icon(LucideIcons.fileX, size: 40, color: AppColors.textMuted),
              ),
              const SizedBox(height: 20),
              const Text(
                'No resources found',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Try adjusting your search or active filters.',
                style: TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      itemCount: files.length,
      itemBuilder: (context, index) {
        final file = files[index];
        final subKey = '${file.semester}_${file.subject}';
        final subjectName = _subjectNameMap[subKey] ?? 'Subject ${file.subject}';

        final categoryColor = switch (file.type.toLowerCase()) {
          'notes' => const Color(0xFF10B981),
          'qbank' => const Color(0xFFF59E0B),
          _ => const Color(0xFF8B5CF6),
        };

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.surfaceBorder),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: categoryColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(LucideIcons.fileText, size: 22, color: categoryColor),
            ),
            title: Text(
              file.name,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: categoryColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          file.type.toUpperCase(),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: categoryColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Sem ${file.semester} • $subjectName • Module ${file.module}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (file.publicId.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Public ID: ${file.publicId}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textMuted,
                        fontFamily: 'monospace',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            trailing: PopupMenuButton<String>(
              color: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.surfaceBorder),
              ),
              icon: const Icon(LucideIcons.moreVertical, size: 18, color: AppColors.textSecondary),
              onSelected: (action) {
                switch (action) {
                  case 'view':
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        settings: const RouteSettings(name: '/pdf-viewer'),
                        builder: (_) => PdfViewerScreen(
                          pdfUrl: file.url,
                          title: file.name,
                        ),
                      ),
                    );
                    break;
                  case 'rename':
                    _showRenameDialog(file);
                    break;
                  case 'delete':
                    _handleDeleteFile(file);
                    break;
                }
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                  value: 'view',
                  child: Row(
                    children: [
                      Icon(LucideIcons.eye, size: 16, color: AppColors.primaryLight),
                      SizedBox(width: 10),
                      Text('Preview PDF', style: TextStyle(color: AppColors.textPrimary, fontSize: 13)),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'rename',
                  child: Row(
                    children: [
                      Icon(LucideIcons.edit2, size: 16, color: Color(0xFF8B5CF6)),
                      SizedBox(width: 10),
                      Text('Rename Resource', style: TextStyle(color: AppColors.textPrimary, fontSize: 13)),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(LucideIcons.trash2, size: 16, color: AppColors.error),
                      SizedBox(width: 10),
                      Text('Delete Resource', style: TextStyle(color: AppColors.error, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  settings: const RouteSettings(name: '/pdf-viewer'),
                  builder: (_) => PdfViewerScreen(
                    pdfUrl: file.url,
                    title: file.name,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

