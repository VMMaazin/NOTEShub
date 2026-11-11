import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/models/subject_model.dart';
import '../../../core/repositories/subject_repository.dart';
import '../../../core/theme/app_colors.dart';

/// Admin Screen for viewing, adding, and renaming subjects across semesters 1–8.
class AdminSubjectsScreen extends StatefulWidget {
  final int? initialSemester;

  const AdminSubjectsScreen({super.key, this.initialSemester});

  @override
  State<AdminSubjectsScreen> createState() => _AdminSubjectsScreenState();
}

class _AdminSubjectsScreenState extends State<AdminSubjectsScreen> {
  late int _selectedSemester;
  bool _isLoading = true;
  String? _error;
  List<SubjectModel> _subjects = [];

  final List<int> _allSemesters = List.generate(8, (i) => i + 1);

  @override
  void initState() {
    super.initState();
    _selectedSemester = widget.initialSemester ?? 4;
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repo = context.read<SubjectRepository>();
      final subjects = await repo.getSubjects(_selectedSemester);
      subjects.sort((a, b) => a.subject.compareTo(b.subject));

      if (!mounted) return;
      setState(() {
        _subjects = subjects;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load subjects: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _showAddSubjectDialog() async {
    final existingSlots = _subjects.map((s) => s.subject).toSet();
    // Find first available slot between 1 and 8
    int suggestedSlot = 1;
    while (existingSlots.contains(suggestedSlot) && suggestedSlot <= 8) {
      suggestedSlot++;
    }
    if (suggestedSlot > 8) suggestedSlot = 1;

    final formKey = GlobalKey<FormState>();
    int selectedSlot = suggestedSlot;
    final nameController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: AppColors.surfaceBorder),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(LucideIcons.bookPlus, size: 20, color: AppColors.primaryLight),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Add New Subject',
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
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Target: Semester $_selectedSemester',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryLight,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Subject Slot (1–8)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        initialValue: selectedSlot,
                        dropdownColor: AppColors.surface,
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.surfaceLight,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.surfaceBorder),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.surfaceBorder),
                          ),
                        ),
                        items: List.generate(8, (i) {
                          final slot = i + 1;
                          final isTaken = existingSlots.contains(slot);
                          return DropdownMenuItem<int>(
                            value: slot,
                            child: Row(
                              children: [
                                Text('Slot $slot'),
                                if (isTaken)
                                  const Text(
                                    ' (Occupied)',
                                    style: TextStyle(color: AppColors.error, fontSize: 12),
                                  ),
                              ],
                            ),
                          );
                        }),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => selectedSlot = val);
                          }
                        },
                        validator: (val) {
                          if (val == null) return 'Select a slot';
                          if (existingSlots.contains(val)) {
                            return 'Slot $val is already assigned in Semester $_selectedSemester';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Subject Name',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: nameController,
                        autofocus: true,
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'e.g. Distributed Database Systems',
                          hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                          filled: true,
                          fillColor: AppColors.surfaceLight,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.surfaceBorder),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.surfaceBorder),
                          ),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Subject name cannot be empty.';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
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
                  child: const Text('Add Subject'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true) {
      if (!mounted) return;
      try {
        final repo = context.read<SubjectRepository>();
        await repo.addSubject(
          semester: _selectedSemester,
          subjectId: selectedSlot,
          name: nameController.text.trim(),
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Subject added to Semester $_selectedSemester Slot $selectedSlot!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _loadSubjects();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add subject: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _showRenameDialog(SubjectModel subject) async {
    final formKey = GlobalKey<FormState>();
    final controller = TextEditingController(text: subject.name);

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.surfaceBorder),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(LucideIcons.edit3, size: 20, color: Color(0xFF8B5CF6)),
            ),
            const SizedBox(width: 12),
            const Text(
              'Rename Subject',
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
                'Semester ${subject.semester} • Slot ${subject.subject}',
                style: const TextStyle(
                  fontSize: 13,
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
                  labelText: 'Subject Name',
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
                    return 'Subject name cannot be empty.';
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
      if (newName == subject.name) return;
      if (!mounted) return;
      try {
        final repo = context.read<SubjectRepository>();
        await repo.saveSubjectName(
          semester: subject.semester,
          subjectId: subject.subject,
          newName: newName,
          existingDocId: subject.id,
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Subject name updated!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _loadSubjects();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update subject: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Manage Subjects',
          style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 19),
            onPressed: _loadSubjects,
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(LucideIcons.plus, size: 20),
        label: const Text('Add Subject', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: _showAddSubjectDialog,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: Column(
            children: [
              _buildSemesterSelector(),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                    : _error != null
                        ? _buildErrorView()
                        : _buildSubjectList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSemesterSelector() {
    return Container(
      height: 52,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _allSemesters.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final sem = _allSemesters[index];
          final isSelected = sem == _selectedSemester;
          return ChoiceChip(
            label: Text('Sem $sem'),
            selected: isSelected,
            selectedColor: AppColors.primary,
            backgroundColor: AppColors.surface,
            side: BorderSide(
              color: isSelected ? AppColors.primary : AppColors.surfaceBorder,
            ),
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 13,
            ),
            onSelected: (selected) {
              if (selected && _selectedSemester != sem) {
                setState(() {
                  _selectedSemester = sem;
                });
                _loadSubjects();
              }
            },
          );
        },
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
            const Icon(LucideIcons.alertTriangle, size: 44, color: AppColors.warning),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _loadSubjects,
              icon: const Icon(LucideIcons.refreshCw, size: 16),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectList() {
    if (_subjects.isEmpty) {
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
                child: const Icon(LucideIcons.bookX, size: 40, color: AppColors.textMuted),
              ),
              const SizedBox(height: 20),
              Text(
                'No subjects defined for Semester $_selectedSemester',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Click "+ Add Subject" below to add slot 1 through 8.',
                style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: _showAddSubjectDialog,
                icon: const Icon(LucideIcons.plus, size: 18),
                label: const Text('Add Subject Slot'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      itemCount: _subjects.length,
      itemBuilder: (context, index) {
        final subject = _subjects[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.surfaceBorder),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(
                '#${subject.subject}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Color(0xFF8B5CF6),
                ),
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    subject.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                if (subject.acronym.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.surfaceBorder),
                    ),
                    child: Text(
                      subject.acronym,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryLight,
                      ),
                    ),
                  ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Doc ID: ${subject.id} • Slot: ${subject.subject}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ),
            trailing: IconButton(
              icon: const Icon(LucideIcons.edit2, size: 18, color: AppColors.textSecondary),
              tooltip: 'Rename Subject',
              onPressed: () => _showRenameDialog(subject),
            ),
          ),
        );
      },
    );
  }
}

