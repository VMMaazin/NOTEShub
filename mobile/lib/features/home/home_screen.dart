import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_constants.dart';
import '../../core/repositories/subject_repository.dart';
import '../../core/services/update_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/animated_glass_background.dart';
import '../../widgets/app_footer.dart';
import '../../widgets/noteshub_app_bar.dart';
import '../../widgets/noteshub_deck_cards.dart';
import '../../widgets/responsive_layout.dart';
import '../downloads/presentation/downloads_screen.dart';
import '../search/presentation/search_screen.dart';
import '../semester/presentation/semester_screen.dart';
import '../update/presentation/update_dialog.dart';

class HomeScreen extends StatefulWidget {
  final bool? showAndroidDownload;

  const HomeScreen({
    super.key,
    this.showAndroidDownload,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<int>> _availableSemestersFuture;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchSemesters();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForInAppUpdates();
    });
  }

  Future<void> _checkForInAppUpdates() async {
    if (UpdateService.hasPromptedThisSession) return;
    try {
      UpdateService? updateService;
      try {
        updateService = context.read<UpdateService>();
      } catch (_) {
        updateService = UpdateService();
      }
      final result = await updateService.checkForUpdate();
      if (!mounted || result == null || !result.isUpdateAvailable) return;
      if (UpdateService.hasPromptedThisSession) return;

      await UpdateDialog.show(
        context,
        updateInfo: result.updateInfo,
        currentVersion: result.currentVersion,
        updateService: updateService,
      );
    } catch (e) {
      debugPrint('Automatic in-app update check error: $e');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _fetchSemesters() {
    final subjectRepo = context.read<SubjectRepository>();
    _availableSemestersFuture = subjectRepo.getAvailableSemesters();
  }

  Future<void> _downloadAndroidApk() async {
    final uri = Uri.parse(AppConstants.androidApkDownloadUrl);
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open APK download URL. Please visit GitHub Releases.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('APK download launch error: $e');
    }
  }

  void _navigateToSemester(int semesterNumber) {
    Navigator.of(context).push(
      MaterialPageRoute(
        settings: RouteSettings(name: '/semester/$semesterNumber'),
        builder: (_) => SemesterScreen(semesterNumber: semesterNumber),
      ),
    );
  }

  void _navigateToSearch() {
    Navigator.of(context).push(
      MaterialPageRoute(
        settings: const RouteSettings(name: '/search'),
        builder: (_) => const SearchScreen(),
      ),
    );
  }

  String _getSemesterSubtitle(int semNum) {
    switch (semNum) {
      case 5:
        return 'Current Syllabus • Active Semester';
      case 4:
        return 'Previous Syllabus';
      default:
        return 'Academic Syllabus';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: const NotesHubAppBar(),
      body: PremiumAnimatedGlassBackground(
        isDark: isDark,
        child: SafeArea(
          child: SingleChildScrollView(
            child: ResponsiveContainer(
              maxWidth: AppConstants.maxWideContentWidth,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 12),

                  // 1. Hero Tagline Sub-Badge
                  SubtleEntranceAnimation(
                    delayMs: 50,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0x33C5A04A) : const Color(0x26C5A04A),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark ? RoyalColors.glassGoldBorder : const Color(0xFFC5A04A),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.school_rounded,
                            size: 14,
                            color: isDark ? RoyalColors.champagne : const Color(0xFF8A6715),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${AppConstants.appName} • Curated Academic Deck',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                              color: isDark ? RoyalColors.champagne : const Color(0xFF8A6715),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 2. Grand Display Headline
                  SubtleEntranceAnimation(
                    delayMs: 120,
                    child: Column(
                      children: [
                        Text(
                          'Your Notes,',
                          style: TextStyle(
                            fontSize: ResponsiveContainer.isMobile(context) ? 36 : 48,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1.2,
                            height: 1.1,
                            color: isDark ? RoyalColors.pearlWhite : RoyalColors.midnightNavy,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        ShaderMask(
                          blendMode: BlendMode.srcIn,
                          shaderCallback: (bounds) => (isDark
                              ? const LinearGradient(
                                  colors: [
                                    Color(0xFFFFE082),
                                    Color(0xFFD4AF37),
                                    Color(0xFFE5CCA0),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : const LinearGradient(
                                  colors: [
                                    Color(0xFFD4AF37),
                                    Color(0xFFA88434),
                                    Color(0xFF8C6D26),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )).createShader(bounds),
                          child: Text(
                            'Simplified.',
                            style: TextStyle(
                              fontSize: ResponsiveContainer.isMobile(context) ? 36 : 48,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1.2,
                              height: 1.1,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 14),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 580),
                          child: Text(
                            'Pick a semester below to browse organized lecture notes, question banks, and reference materials across Modules 1 to 5.',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w500,
                              height: 1.5,
                              color: isDark ? RoyalColors.textMutedDark : RoyalColors.textNavyMuted,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // 3. Liquid Glass Search Bar
                  SubtleEntranceAnimation(
                    delayMs: 180,
                    child: GestureDetector(
                      onTap: _navigateToSearch,
                      child: AbsorbPointer(
                        child: LiquidGlassSearchBar(
                          controller: _searchController,
                          onChanged: (_) {},
                          hintText: "Search by subject, acronym (e.g. 'WT', 'OS')...",
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 4. Quick Action Buttons
                  SubtleEntranceAnimation(
                    delayMs: 220,
                    child: Builder(
                      builder: (context) {
                        final showDownload = widget.showAndroidDownload ??
                            (kIsWeb || defaultTargetPlatform != TargetPlatform.android);

                        return Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 12,
                          runSpacing: 10,
                          children: [
                            if (showDownload)
                              RoyalLiquidGlassButton(
                                label: 'Download for Android',
                                icon: Icons.android_rounded,
                                isCompact: true,
                                isGold: true,
                                onTap: _downloadAndroidApk,
                              ),
                            RoyalLiquidGlassButton(
                              label: 'Offline Library',
                              icon: Icons.download_for_offline_rounded,
                              isCompact: true,
                              isGold: !showDownload,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    settings: const RouteSettings(name: '/downloads'),
                                    builder: (_) => const DownloadsScreen(),
                                  ),
                                );
                              },
                            ),
                          ],
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 36),

                  // 5. Section Header
                  SubtleEntranceAnimation(
                    delayMs: 260,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 4,
                              height: 20,
                              decoration: BoxDecoration(
                                gradient: RoyalGradients.metallicGold,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Academic Semesters',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.4,
                                color: isDark ? RoyalColors.pearlWhite : RoyalColors.midnightNavy,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0x33C5A04A) : const Color(0x26C5A04A),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark ? RoyalColors.glassGoldBorder : const Color(0xFFC5A04A),
                            ),
                          ),
                          child: Text(
                            '2 Available',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isDark ? RoyalColors.champagne : const Color(0xFF8A6715),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // 6. Dynamic Responsive Semester Grid (Semester 5 first, Semester 4 second)
                  FutureBuilder<List<int>>(
                    future: _availableSemestersFuture,
                    builder: (context, snapshot) {
                      final availableSemesters = snapshot.data ?? [5, 4];

                      return LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = constraints.maxWidth >= 600;
                          final crossAxisCount = isWide ? 2 : 1;

                          // Only Semester 5 and Semester 4, strictly in that order
                          const semesterList = [5, 4];

                          return Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 680),
                              child: GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  mainAxisExtent: 185,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                ),
                                itemCount: semesterList.length,
                                itemBuilder: (context, index) {
                                  final semNum = semesterList[index];
                                  final isAvailable = availableSemesters.contains(semNum) || semNum == 5 || semNum == 4;
                                  final badgeLabel = semNum == 5 ? 'ACTIVE' : 'Available';

                                  return NotesHubAcademicCard(
                                    title: 'Semester $semNum',
                                    subtitle: _getSemesterSubtitle(semNum),
                                    leadingNumber: semNum,
                                    isActive: isAvailable,
                                    badgeText: badgeLabel,
                                    actionLabel: 'VIEW NOTES',
                                    onTap: () => _navigateToSemester(semNum),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),

                  // 7. Footer
                  const AppFooter(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
