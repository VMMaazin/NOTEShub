import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/models/subject_model.dart';
import '../../../core/repositories/subject_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/animated_glass_background.dart';
import '../../../widgets/app_footer.dart';
import '../../../widgets/empty_state_view.dart';
import '../../../widgets/noteshub_app_bar.dart';
import '../../../widgets/noteshub_deck_cards.dart';
import '../../../widgets/responsive_layout.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../subject/presentation/subject_detail_screen.dart';

class SemesterScreen extends StatelessWidget {
  final int semesterNumber;

  const SemesterScreen({
    super.key,
    required this.semesterNumber,
  });

  Future<void> _showAddSubjectDialog(BuildContext context, List<SubjectModel> existingSubjects) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final subjectRepo = context.read<SubjectRepository>();
    final messenger = ScaffoldMessenger.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    int selectedSlot = 1;
    for (int i = 1; i <= 8; i++) {
      if (!existingSubjects.any((s) => s.subject == i)) {
        selectedSlot = i;
        break;
      }
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: isDark
              ? RoyalColors.midnightNavySurface
              : RoyalColors.creamCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: BorderSide(
              color: isDark ? RoyalColors.glassGoldBorder : const Color(0x33C5A04A),
              width: 1.2,
            ),
          ),
          title: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: RoyalGradients.metallicGold,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x4DC5A04A),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: RoyalColors.midnightNavy,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Add Subject',
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Semester $semesterNumber Curriculum',
                  style: TextStyle(
                    color: isDark ? RoyalColors.champagne : const Color(0xFF8A6715),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  initialValue: selectedSlot,
                  decoration: const InputDecoration(labelText: 'Subject Slot (1-8)'),
                  items: List.generate(8, (i) => i + 1).map((slotNum) {
                    final existing = existingSubjects.where((s) => s.subject == slotNum);
                    final existsLabel = existing.isNotEmpty ? ' (${existing.first.name})' : ' (Available)';
                    return DropdownMenuItem(
                      value: slotNum,
                      child: Text('Slot $slotNum$existsLabel'),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() {
                        selectedSlot = val;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: nameController,
                  autofocus: true,
                  style: TextStyle(
                    color: isDark ? RoyalColors.pearlWhite : RoyalColors.midnightNavy,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Subject Name',
                    hintText: 'e.g. Distributed Operating Systems',
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter a subject name' : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: isDark ? RoyalColors.textMutedDark : RoyalColors.textNavyMuted,
                ),
              ),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.of(ctx).pop(true);
                }
              },
              child: const Text('Add Subject'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      final name = nameController.text.trim();
      try {
        await subjectRepo.addSubject(
          semester: semesterNumber,
          subjectId: selectedSlot,
          name: name,
        );
        messenger.showSnackBar(
          SnackBar(
            content: Text('Subject "$name" added to Slot $selectedSlot!'),
            backgroundColor: RoyalColors.emeraldActive,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } catch (e) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Error adding subject: $e'),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _showRenameSubjectDialog(
    BuildContext context,
    int subjectNum,
    String currentName,
    String? docId,
  ) async {
    final formKey = GlobalKey<FormState>();
    final controller = TextEditingController(text: currentName == 'Subject $subjectNum' ? '' : currentName);
    final subjectRepo = context.read<SubjectRepository>();
    final messenger = ScaffoldMessenger.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark
            ? RoyalColors.midnightNavySurface
            : RoyalColors.creamCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(
            color: isDark ? RoyalColors.glassGoldBorder : const Color(0x33C5A04A),
            width: 1.2,
          ),
        ),
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: RoyalGradients.metallicGold,
                borderRadius: BorderRadius.circular(10),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x4DC5A04A),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.edit_note_rounded,
                color: RoyalColors.midnightNavy,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Rename Subject $subjectNum',
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Semester $semesterNumber • Slot $subjectNum',
                style: TextStyle(
                  color: isDark ? RoyalColors.champagne : const Color(0xFF8A6715),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: controller,
                autofocus: true,
                style: TextStyle(
                  color: isDark ? RoyalColors.pearlWhite : RoyalColors.midnightNavy,
                ),
                decoration: InputDecoration(
                  labelText: 'Subject Name',
                  hintText: currentName,
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Name cannot be empty' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark ? RoyalColors.textMutedDark : RoyalColors.textNavyMuted,
              ),
            ),
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

    if (confirmed == true) {
      final newName = controller.text.trim();
      if (newName.isEmpty || newName == currentName) return;

      try {
        await subjectRepo.saveSubjectName(
          semester: semesterNumber,
          subjectId: subjectNum,
          newName: newName,
          existingDocId: docId,
        );
        messenger.showSnackBar(
          SnackBar(
            content: Text('Subject $subjectNum renamed to "$newName"'),
            backgroundColor: RoyalColors.emeraldActive,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } catch (e) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Error renaming subject: $e'),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final subjectRepo = context.read<SubjectRepository>();
    final authState = context.watch<AuthBloc>().state;
    final isAdmin = authState is Authenticated && authState.isAuthor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: NotesHubAppBar(
        title: 'Semester $semesterNumber',
        subtitle: 'Curriculum & Syllabus',
      ),
      body: PremiumAnimatedGlassBackground(
        isDark: isDark,
        child: SafeArea(
          child: StreamBuilder<List<SubjectModel>>(
            stream: subjectRepo.streamSubjects(semesterNumber),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: RoyalColors.royalGold),
                );
              }

              if (snapshot.hasError) {
                return EmptyStateView(
                  icon: Icons.error_outline_rounded,
                  title: 'Failed to load curriculum',
                  message: snapshot.error.toString(),
                  actionLabel: 'Retry',
                  onAction: () {},
                );
              }

              final subjects = snapshot.data ?? [];

              String getSubjectName(int num) {
                final found = subjects.where((s) => s.subject == num);
                if (found.isNotEmpty) {
                  return found.first.name;
                }
                return 'Subject $num';
              }

              String? getSubjectDocId(int num) {
                final found = subjects.where((s) => s.subject == num);
                if (found.isNotEmpty) {
                  return found.first.id;
                }
                return null;
              }

              return SingleChildScrollView(
                child: ResponsiveContainer(
                  maxWidth: AppConstants.maxWideContentWidth,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Section with Breadcrumb and Admin Action
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Curriculum & Syllabus',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1.1,
                                        color: isDark ? RoyalColors.champagne : const Color(0xFF8A6715),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      width: 4,
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: isDark ? RoyalColors.champagne : const Color(0xFF8A6715),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Semester $semesterNumber',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? RoyalColors.textSlateMuted : RoyalColors.textNavyMuted,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Select a Subject',
                                  style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.4,
                                    color: isDark ? RoyalColors.pearlWhite : RoyalColors.midnightNavy,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Browse lecture notes, question banks, and reference materials across Modules 1 to 5.',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    color: isDark ? RoyalColors.textMutedDark : RoyalColors.textNavyMuted,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isAdmin)
                            RoyalLiquidGlassButton(
                              label: 'Add Subject',
                              icon: Icons.add_rounded,
                              isCompact: true,
                              onTap: () => _showAddSubjectDialog(context, subjects),
                            ),
                        ],
                      ),

                      const SizedBox(height: 28),

                      // Responsive Subject Grid (4 subjects per row on tablets/desktops: 4 + 4 layout)
                      LayoutBuilder(
                        builder: (context, constraints) {
                          int crossAxisCount = 4;

                          if (constraints.maxWidth < 480) {
                            crossAxisCount = 1;
                          } else if (constraints.maxWidth < 720) {
                            crossAxisCount = 2;
                          } else {
                            // Sufficiently wide screens: exactly 4 subjects per row
                            crossAxisCount = 4;
                          }

                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              mainAxisExtent: 185,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                            itemCount: 8,
                            itemBuilder: (context, index) {
                              final subjectNum = index + 1;
                              final subjectName = getSubjectName(subjectNum);
                              final docId = getSubjectDocId(subjectNum);

                              return NotesHubAcademicCard(
                                title: subjectName,
                                subtitle: 'Modules 1–5 Syllabus',
                                leadingNumber: subjectNum,
                                // Remove 'Slot 1, Slot 2' label from student-facing UI
                                badgeText: null,
                                actionLabel: 'OPEN MODULES',
                                adminAction: isAdmin
                                    ? () => _showRenameSubjectDialog(
                                          context,
                                          subjectNum,
                                          subjectName,
                                          docId,
                                        )
                                    : null,
                                adminTooltip: 'Rename Subject',
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      settings: RouteSettings(
                                        name: '/semester/$semesterNumber/subject/$subjectNum/module/1',
                                      ),
                                      builder: (_) => SubjectDetailScreen(
                                        semester: semesterNumber,
                                        subject: subjectNum,
                                        initialSubjectName: subjectName,
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),

                      const AppFooter(),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
