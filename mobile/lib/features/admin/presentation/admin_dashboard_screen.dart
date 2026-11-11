import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/models/file_model.dart';
import '../../../core/models/subject_model.dart';
import '../../../core/models/user_model.dart';
import '../../../core/repositories/file_repository.dart';
import '../../../core/repositories/subject_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../pdf_viewer/presentation/pdf_viewer_screen.dart';
import 'admin_resources_screen.dart';
import 'admin_subjects_screen.dart';
import 'upload_resource_screen.dart';
import 'widgets/admin_stat_card.dart';

/// Admin Dashboard Screen
/// Displays live Firestore metrics, quick action shortcuts,
/// recent uploads, and current administrator identity.
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _isLoading = true;
  String? _error;

  int _totalSemesters = 0;
  int _totalSubjects = 0;
  int _totalFiles = 0;
  List<FileModel> _recentFiles = [];
  Map<String, String> _subjectNameMap = {};

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final subjectRepo = context.read<SubjectRepository>();
      final fileRepo = context.read<FileRepository>();

      final results = await Future.wait([
        subjectRepo.getAvailableSemesters(),
        subjectRepo.getAllSubjects(),
        fileRepo.getAllFiles(),
      ]);

      final semesters = results[0] as List<int>;
      final subjects = results[1] as List<SubjectModel>;
      final files = results[2] as List<FileModel>;

      // Build subject name lookup map (semester_subject -> name)
      final map = <String, String>{};
      for (final s in subjects) {
        map['${s.semester}_${s.subject}'] = s.name;
      }

      // Sort files by createdAt descending if available, else recent additions
      final sortedFiles = List<FileModel>.from(files)
        ..sort((a, b) {
          if (a.createdAt != null && b.createdAt != null) {
            return b.createdAt!.compareTo(a.createdAt!);
          }
          if (a.createdAt != null) return -1;
          if (b.createdAt != null) return 1;
          return b.id.compareTo(a.id);
        });

      if (!mounted) return;

      setState(() {
        _totalSemesters = semesters.length;
        _totalSubjects = subjects.length;
        _totalFiles = files.length;
        _recentFiles = sortedFiles.take(5).toList();
        _subjectNameMap = map;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load dashboard metrics: $e';
        _isLoading = false;
      });
    }
  }

  void _handleSignOut() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.surfaceBorder),
        ),
        title: const Text(
          'Sign Out',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        content: const Text(
          'Are you sure you want to exit the Admin Portal?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<AuthBloc>().add(const SignOutRequested());
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Unauthenticated) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'Admin Portal',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.3,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(LucideIcons.refreshCw, size: 19),
              tooltip: 'Refresh Metrics',
              onPressed: _loadDashboardData,
            ),
            IconButton(
              icon: const Icon(LucideIcons.logOut, size: 20, color: AppColors.error),
              tooltip: 'Sign Out',
              onPressed: _handleSignOut,
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _loadDashboardData,
          color: AppColors.primary,
          backgroundColor: AppColors.surface,
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                )
              : _error != null
                  ? _buildErrorView()
                  : _buildDashboardContent(),
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.alertTriangle, size: 48, color: AppColors.warning),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _loadDashboardData,
              icon: const Icon(LucideIcons.refreshCw, size: 16),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardContent() {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        UserModel? user;
        if (authState is Authenticated) {
          user = authState.user;
        }

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                _buildProfileCard(user),
                const SizedBox(height: 20),
                _buildStatsSection(),
                const SizedBox(height: 24),
                _buildQuickActions(),
                const SizedBox(height: 28),
                _buildRecentFilesSection(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileCard(UserModel? user) {
    final isOwner = user?.isOwner ?? false;
    final role = user?.role != null ? user!.role!.toUpperCase() : (isOwner ? 'OWNER' : 'ADMIN');
    final displayName = (user?.name != null && user!.name!.isNotEmpty)
        ? user.name!
        : (isOwner ? 'Platform Owner' : 'Administrator');

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceBorder),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            (isOwner ? const Color(0xFFF59E0B) : AppColors.primary).withValues(alpha: 0.10),
            AppColors.surface,
          ],
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: (isOwner ? const Color(0xFFF59E0B) : AppColors.primary).withValues(alpha: 0.2),
            child: Icon(
              isOwner ? LucideIcons.shieldAlert : LucideIcons.userCheck,
              color: isOwner ? const Color(0xFFF59E0B) : AppColors.primary,
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        displayName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: (isOwner ? const Color(0xFFF59E0B) : AppColors.primary).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        role,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isOwner ? const Color(0xFFF59E0B) : AppColors.primaryLight,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'UID: ${user?.uid ?? "Authenticated"}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                    fontFamily: 'monospace',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 500;
        if (isWide) {
          return Row(
            children: [
              Expanded(
                child: AdminStatCard(
                  label: 'Semesters',
                  value: '$_totalSemesters',
                  icon: LucideIcons.layers,
                  accentColor: const Color(0xFF3B82F6),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      settings: const RouteSettings(name: '/admin/subjects'),
                      builder: (_) => const AdminSubjectsScreen(),
                    ),
                  ).then((_) => _loadDashboardData()),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AdminStatCard(
                  label: 'Subjects',
                  value: '$_totalSubjects',
                  icon: LucideIcons.bookOpen,
                  accentColor: const Color(0xFF8B5CF6),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      settings: const RouteSettings(name: '/admin/subjects'),
                      builder: (_) => const AdminSubjectsScreen(),
                    ),
                  ).then((_) => _loadDashboardData()),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AdminStatCard(
                  label: 'Resources',
                  value: '$_totalFiles',
                  icon: LucideIcons.fileText,
                  accentColor: const Color(0xFF10B981),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      settings: const RouteSettings(name: '/admin/resources'),
                      builder: (_) => const AdminResourcesScreen(),
                    ),
                  ).then((_) => _loadDashboardData()),
                ),
              ),
            ],
          );
        }

        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: AdminStatCard(
                    label: 'Semesters',
                    value: '$_totalSemesters',
                    icon: LucideIcons.layers,
                    accentColor: const Color(0xFF3B82F6),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        settings: const RouteSettings(name: '/admin/subjects'),
                        builder: (_) => const AdminSubjectsScreen(),
                      ),
                    ).then((_) => _loadDashboardData()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AdminStatCard(
                    label: 'Subjects',
                    value: '$_totalSubjects',
                    icon: LucideIcons.bookOpen,
                    accentColor: const Color(0xFF8B5CF6),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        settings: const RouteSettings(name: '/admin/subjects'),
                        builder: (_) => const AdminSubjectsScreen(),
                      ),
                    ).then((_) => _loadDashboardData()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AdminStatCard(
              label: 'Total Uploaded Resources',
              value: '$_totalFiles',
              icon: LucideIcons.fileText,
              accentColor: const Color(0xFF10B981),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  settings: const RouteSettings(name: '/admin/resources'),
                  builder: (_) => const AdminResourcesScreen(),
                ),
              ).then((_) => _loadDashboardData()),
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        // Primary Upload Button
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                settings: const RouteSettings(name: '/admin/upload'),
                builder: (_) => const UploadResourceScreen(),
              ),
            ).then((_) => _loadDashboardData()),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Row(
                children: [
                  Icon(LucideIcons.uploadCloud, color: Colors.white, size: 24),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Upload New Resource',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Upload PDF notes, q-banks, or extra resources',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSecondaryActionCard(
                title: 'Manage Subjects',
                subtitle: 'Add or rename subjects',
                icon: LucideIcons.bookPlus,
                color: const Color(0xFF8B5CF6),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    settings: const RouteSettings(name: '/admin/subjects'),
                    builder: (_) => const AdminSubjectsScreen(),
                  ),
                ).then((_) => _loadDashboardData()),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSecondaryActionCard(
                title: 'Manage Files',
                subtitle: 'Browse and rename',
                icon: LucideIcons.folderKanban,
                color: const Color(0xFF3B82F6),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    settings: const RouteSettings(name: '/admin/resources'),
                    builder: (_) => const AdminResourcesScreen(),
                  ),
                ).then((_) => _loadDashboardData()),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSecondaryActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.surfaceBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentFilesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Uploads',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AdminResourcesScreen()),
              ).then((_) => _loadDashboardData()),
              child: const Text('View All', style: TextStyle(color: AppColors.primaryLight)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_recentFiles.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.surfaceBorder),
            ),
            child: const Text(
              'No resources found in Firestore.',
              style: TextStyle(color: AppColors.textMuted),
            ),
          )
        else
          ..._recentFiles.map(_buildRecentFileItem),
      ],
    );
  }

  Widget _buildRecentFileItem(FileModel file) {
    final subKey = '${file.semester}_${file.subject}';
    final subjectName = _subjectNameMap[subKey] ?? 'Subject ${file.subject}';
    final categoryColor = switch (file.type.toLowerCase()) {
      'notes' => const Color(0xFF10B981),
      'qbank' => const Color(0xFFF59E0B),
      _ => const Color(0xFF8B5CF6),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: categoryColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(LucideIcons.fileText, size: 20, color: categoryColor),
        ),
        title: Text(
          file.name,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
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
                  'Sem ${file.semester} • $subjectName • M${file.module}',
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
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
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
  }
}
