import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/models/file_model.dart';
import '../../../core/models/subject_model.dart';
import '../../../core/repositories/file_repository.dart';
import '../../../core/repositories/subject_repository.dart';
import '../../../core/services/cloudinary_upload_service.dart';
import '../../../core/theme/animated_glass_background.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/royal_design_system.dart';
import '../../../core/utils/file_utils.dart';
import '../../../widgets/noteshub_app_bar.dart';

class UploadResourceScreen extends StatefulWidget {
  final int? initialSemester;
  final int? initialSubject;
  final int? initialModule;
  final String? initialCategory;

  const UploadResourceScreen({
    super.key,
    this.initialSemester,
    this.initialSubject,
    this.initialModule,
    this.initialCategory,
  });

  @override
  State<UploadResourceScreen> createState() => _UploadResourceScreenState();
}

class _UploadResourceScreenState extends State<UploadResourceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  late int _selectedSemester;
  int? _selectedSubject;
  int _selectedModule = 1;
  String _selectedCategory = FileCategory.notes;

  List<SubjectModel> _availableSubjects = [];
  bool _isLoadingSubjects = false;

  PlatformFile? _selectedFile;
  List<int>? _fileBytes;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String _uploadStatus = '';
  CancelToken? _cancelToken;
  CloudinaryUploadResult? _cachedCloudinaryResult;

  final CloudinaryUploadService _uploadService = CloudinaryUploadService();

  @override
  void initState() {
    super.initState();
    _selectedSemester = widget.initialSemester ?? 4;
    _selectedSubject = widget.initialSubject;
    _selectedModule = widget.initialModule ?? 1;
    _selectedCategory = widget.initialCategory ?? FileCategory.notes;

    _loadSubjectsForSemester(_selectedSemester);
  }

  @override
  void dispose() {
    _cancelToken?.cancel('Upload cancelled by user navigation.');
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadSubjectsForSemester(int semester) async {
    setState(() {
      _isLoadingSubjects = true;
    });

    try {
      final repo = context.read<SubjectRepository>();
      final subjects = await repo.getSubjects(semester);
      subjects.sort((a, b) => a.subject.compareTo(b.subject));

      if (mounted) {
        setState(() {
          _availableSubjects = subjects;
          if (_selectedSubject != null &&
              !subjects.any((s) => s.subject == _selectedSubject)) {
            _selectedSubject = subjects.isNotEmpty ? subjects.first.subject : null;
          } else if (_selectedSubject == null && subjects.isNotEmpty) {
            _selectedSubject = subjects.first.subject;
          }
          _isLoadingSubjects = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingSubjects = false;
        });
      }
    }
  }

  Future<void> _pickPdfFile() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      final bytes = file.bytes;

      if (bytes == null || bytes.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not read the selected file bytes.'),
              backgroundColor: Color(0xFFDC2626),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      // Validate PDF signature & size
      try {
        CloudinaryUploadService.validatePdfFile(
          fileBytes: bytes,
          fileName: file.name,
        );
      } catch (err) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(err.toString()),
              backgroundColor: const Color(0xFFDC2626),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      setState(() {
        _selectedFile = file;
        _fileBytes = bytes;
        if (_nameController.text.trim().isEmpty) {
          _nameController.text = file.name;
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('File picker error: $e'),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _startUpload() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedFile == null || _fileBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a PDF document first.'),
          backgroundColor: Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_selectedSubject == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a valid subject.'),
          backgroundColor: Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final fileRepo = context.read<FileRepository>();
    final displayName = _nameController.text.trim();

    // Duplicate check
    final exists = await fileRepo.fileRecordExists(
      semester: _selectedSemester,
      subject: _selectedSubject!,
      module: _selectedModule,
      type: _selectedCategory,
      name: displayName,
    );

    if (exists && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'A resource named "$displayName" already exists in Semester $_selectedSemester, Module $_selectedModule.',
          ),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = _cachedCloudinaryResult != null ? 1.0 : 0.0;
      _uploadStatus = _cachedCloudinaryResult != null
          ? 'Saving record to Firestore (using uploaded asset)...'
          : 'Uploading to Cloudinary...';
      _cancelToken = CancelToken();
    });

    try {
      // 1. Upload to Cloudinary RAW storage if not already uploaded in a previous failed attempt
      CloudinaryUploadResult uploadResult;
      if (_cachedCloudinaryResult != null) {
        uploadResult = _cachedCloudinaryResult!;
      } else {
        uploadResult = await _uploadService.uploadPdf(
          fileBytes: _fileBytes!,
          fileName: _selectedFile!.name,
          cancelToken: _cancelToken,
          onProgress: (sent, total) {
            if (total > 0 && mounted) {
              setState(() {
                _uploadProgress = sent / total;
                _uploadStatus =
                    'Uploading: ${(_uploadProgress * 100).toStringAsFixed(0)}%';
              });
            }
          },
        );
        _cachedCloudinaryResult = uploadResult;
      }

      if (!mounted) return;

      setState(() {
        _uploadStatus = 'Saving record to Firestore...';
      });

      // 2. Save metadata to Firestore files collection
      await fileRepo.addFileRecord(
        semester: _selectedSemester,
        subject: _selectedSubject!,
        module: _selectedModule,
        type: _selectedCategory,
        name: displayName,
        url: uploadResult.secureUrl,
        publicId: uploadResult.publicId,
        preventDuplicates: false,
      );

      _cachedCloudinaryResult = null; // Cleared on full success

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully uploaded "$displayName"!'),
          backgroundColor: RoyalColors.emeraldActive,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });

        final isFirestoreError = _cachedCloudinaryResult != null;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isFirestoreError
                  ? 'Asset uploaded to Cloudinary, but failed to save in Firestore: $e'
                  : 'Upload failed: $e',
            ),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
            action: isFirestoreError
                ? SnackBarAction(
                    label: 'Retry Save',
                    textColor: Colors.white,
                    onPressed: _startUpload,
                  )
                : null,
            duration: const Duration(seconds: 6),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
                  // Royal App Bar
                  const NotesHubAppBar(
                    title: 'Upload Study Material',
                    subtitle: 'Secure Cloudinary RAW asset & metadata storage',
                  ),

                  // Form Content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 640),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // File Drop / Picker Zone
                                _buildFileDropZone(isDark),
                                const SizedBox(height: 20),

                                // Academic Coordinates Card
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                                    child: Container(
                                      padding: const EdgeInsets.all(22),
                                      decoration: BoxDecoration(
                                        color: isDark ? const Color(0xE60D1630) : const Color(0xF2FAF7F0),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: isDark ? RoyalColors.glassGoldBorder : RoyalColors.ivoryBorder,
                                        ),
                                        boxShadow: isDark
                                            ? const [
                                                BoxShadow(
                                                  color: Color(0x33000000),
                                                  blurRadius: 16,
                                                  offset: Offset(0, 4),
                                                ),
                                              ]
                                            : RoyalShadows.subtleCard,
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                width: 32,
                                                height: 32,
                                                decoration: BoxDecoration(
                                                  gradient: RoyalGradients.metallicGold,
                                                  borderRadius: BorderRadius.circular(9),
                                                ),
                                                child: const Icon(
                                                  Icons.explore_rounded,
                                                  size: 18,
                                                  color: RoyalColors.midnightNavy,
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Text(
                                                'Academic Coordinates',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w800,
                                                  color: isDark ? RoyalColors.pearlWhite : RoyalColors.midnightNavy,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 18),

                                          // Semester & Subject Selection Row
                                          Row(
                                            children: [
                                              // Semester Dropdown
                                              Expanded(
                                                flex: 2,
                                                child: DropdownButtonFormField<int>(
                                                  initialValue: _selectedSemester,
                                                  dropdownColor: isDark ? const Color(0xFF101B3B) : const Color(0xFFFAF7F0),
                                                  style: TextStyle(
                                                    color: isDark ? RoyalColors.pearlWhite : RoyalColors.midnightNavy,
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 13,
                                                  ),
                                                  decoration: InputDecoration(
                                                    labelText: 'Semester',
                                                    labelStyle: TextStyle(
                                                      color: isDark ? RoyalColors.champagne : const Color(0xFF8A6715),
                                                    ),
                                                    filled: true,
                                                    fillColor: isDark ? const Color(0x33090F22) : Colors.white,
                                                    enabledBorder: OutlineInputBorder(
                                                      borderRadius: BorderRadius.circular(12),
                                                      borderSide: BorderSide(
                                                        color: isDark ? RoyalColors.glassGoldBorder : RoyalColors.ivoryBorder,
                                                      ),
                                                    ),
                                                    focusedBorder: OutlineInputBorder(
                                                      borderRadius: BorderRadius.circular(12),
                                                      borderSide: const BorderSide(color: RoyalColors.royalGold, width: 1.5),
                                                    ),
                                                  ),
                                                  items: List.generate(8, (index) => index + 1)
                                                      .map((sem) => DropdownMenuItem(
                                                            value: sem,
                                                            child: Text('Semester $sem'),
                                                          ))
                                                      .toList(),
                                                  onChanged: _isUploading
                                                      ? null
                                                      : (val) {
                                                          if (val != null && val != _selectedSemester) {
                                                            setState(() {
                                                              _selectedSemester = val;
                                                            });
                                                            _loadSubjectsForSemester(val);
                                                          }
                                                        },
                                                ),
                                              ),
                                              const SizedBox(width: 12),

                                              // Subject Dropdown
                                              Expanded(
                                                flex: 3,
                                                child: _isLoadingSubjects
                                                    ? const Center(
                                                        child: SizedBox(
                                                          width: 22,
                                                          height: 22,
                                                          child: CircularProgressIndicator(
                                                            strokeWidth: 2,
                                                            color: RoyalColors.royalGold,
                                                          ),
                                                        ),
                                                      )
                                                    : DropdownButtonFormField<int>(
                                                        initialValue: _selectedSubject,
                                                        dropdownColor: isDark ? const Color(0xFF101B3B) : const Color(0xFFFAF7F0),
                                                        style: TextStyle(
                                                          color: isDark ? RoyalColors.pearlWhite : RoyalColors.midnightNavy,
                                                          fontWeight: FontWeight.w600,
                                                          fontSize: 13,
                                                        ),
                                                        decoration: InputDecoration(
                                                          labelText: 'Subject',
                                                          labelStyle: TextStyle(
                                                            color: isDark ? RoyalColors.champagne : const Color(0xFF8A6715),
                                                          ),
                                                          filled: true,
                                                          fillColor: isDark ? const Color(0x33090F22) : Colors.white,
                                                          enabledBorder: OutlineInputBorder(
                                                            borderRadius: BorderRadius.circular(12),
                                                            borderSide: BorderSide(
                                                              color: isDark ? RoyalColors.glassGoldBorder : RoyalColors.ivoryBorder,
                                                            ),
                                                          ),
                                                          focusedBorder: OutlineInputBorder(
                                                            borderRadius: BorderRadius.circular(12),
                                                            borderSide: const BorderSide(color: RoyalColors.royalGold, width: 1.5),
                                                          ),
                                                        ),
                                                        hint: Text(
                                                          'Select subject',
                                                          style: TextStyle(
                                                            color: isDark ? RoyalColors.textSlateMuted : RoyalColors.textNavyMuted,
                                                            fontSize: 13,
                                                          ),
                                                        ),
                                                        items: _availableSubjects.isEmpty
                                                            ? [
                                                                const DropdownMenuItem<int>(
                                                                  value: null,
                                                                  child: Text('No subjects added'),
                                                                ),
                                                              ]
                                                            : _availableSubjects
                                                                .map((s) => DropdownMenuItem(
                                                                      value: s.subject,
                                                                      child: Text(
                                                                        s.name,
                                                                        overflow: TextOverflow.ellipsis,
                                                                      ),
                                                                    ))
                                                                .toList(),
                                                        onChanged: _isUploading || _availableSubjects.isEmpty
                                                            ? null
                                                            : (val) {
                                                                setState(() {
                                                                  _selectedSubject = val;
                                                                });
                                                              },
                                                        validator: (val) => val == null
                                                            ? 'Please select a subject'
                                                            : null,
                                                      ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 18),

                                          // Module Selection (1 to 5)
                                          Text(
                                            'Module',
                                            style: TextStyle(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w700,
                                              color: isDark ? RoyalColors.pearlWhite : RoyalColors.midnightNavy,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: List.generate(5, (index) {
                                              final mod = index + 1;
                                              final isSelected = _selectedModule == mod;
                                              return Expanded(
                                                child: Padding(
                                                  padding: EdgeInsets.only(
                                                    right: index < 4 ? 8.0 : 0.0,
                                                  ),
                                                  child: Material(
                                                    color: Colors.transparent,
                                                    child: InkWell(
                                                      onTap: _isUploading
                                                          ? null
                                                          : () => setState(() => _selectedModule = mod),
                                                      borderRadius: BorderRadius.circular(10),
                                                      child: AnimatedContainer(
                                                        duration: const Duration(milliseconds: 180),
                                                        padding: const EdgeInsets.symmetric(vertical: 9),
                                                        decoration: BoxDecoration(
                                                          gradient: isSelected ? RoyalGradients.metallicGold : null,
                                                          color: isSelected
                                                              ? null
                                                              : (isDark ? const Color(0x33090F22) : Colors.white),
                                                          borderRadius: BorderRadius.circular(10),
                                                          border: Border.all(
                                                            color: isSelected
                                                                ? RoyalColors.royalGold
                                                                : (isDark ? RoyalColors.glassGoldBorder : RoyalColors.ivoryBorder),
                                                          ),
                                                        ),
                                                        alignment: Alignment.center,
                                                        child: Text(
                                                          'M$mod',
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            fontWeight: FontWeight.w800,
                                                            color: isSelected
                                                                ? RoyalColors.midnightNavy
                                                                : (isDark ? RoyalColors.pearlWhite : RoyalColors.midnightNavy),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              );
                                            }),
                                          ),
                                          const SizedBox(height: 18),

                                          // Category Selection (Notes, Question Bank, Extra)
                                          Text(
                                            'Category',
                                            style: TextStyle(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w700,
                                              color: isDark ? RoyalColors.pearlWhite : RoyalColors.midnightNavy,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Wrap(
                                            spacing: 8,
                                            runSpacing: 8,
                                            children: [
                                              _buildCategoryChip(
                                                label: 'Lecture Notes',
                                                category: FileCategory.notes,
                                                icon: Icons.menu_book_rounded,
                                                isDark: isDark,
                                              ),
                                              _buildCategoryChip(
                                                label: 'Question Bank',
                                                category: FileCategory.qbank,
                                                icon: Icons.quiz_rounded,
                                                isDark: isDark,
                                              ),
                                              _buildCategoryChip(
                                                label: 'Extra Resources',
                                                category: FileCategory.extra,
                                                icon: Icons.auto_stories_rounded,
                                                isDark: isDark,
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 20),

                                          // Resource Display Name
                                          TextFormField(
                                            controller: _nameController,
                                            enabled: !_isUploading,
                                            style: TextStyle(
                                              color: isDark ? RoyalColors.pearlWhite : RoyalColors.midnightNavy,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            decoration: InputDecoration(
                                              labelText: 'Document Title',
                                              labelStyle: TextStyle(
                                                color: isDark ? RoyalColors.champagne : const Color(0xFF8A6715),
                                              ),
                                              hintText: 'e.g. Module 1 Complete Notes.pdf',
                                              hintStyle: TextStyle(
                                                color: isDark ? RoyalColors.textDisabled : RoyalColors.textNavySubtle,
                                              ),
                                              prefixIcon: const Icon(Icons.description_outlined, size: 18, color: RoyalColors.royalGold),
                                              filled: true,
                                              fillColor: isDark ? const Color(0x33090F22) : Colors.white,
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(12),
                                                borderSide: BorderSide(
                                                  color: isDark ? RoyalColors.glassGoldBorder : RoyalColors.ivoryBorder,
                                                ),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(12),
                                                borderSide: const BorderSide(color: RoyalColors.royalGold, width: 1.5),
                                              ),
                                            ),
                                            validator: (value) {
                                              if (value == null || value.trim().isEmpty) {
                                                return 'Please enter a document title.';
                                              }
                                              return null;
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Upload Progress Indicator
                                if (_isUploading) ...[
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xE60D1630) : const Color(0xF2FAF7F0),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: isDark ? RoyalColors.glassGoldBorder : RoyalColors.ivoryBorder,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              _uploadStatus,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: RoyalColors.royalGold,
                                              ),
                                            ),
                                            Text(
                                              '${(_uploadProgress * 100).toStringAsFixed(0)}%',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w800,
                                                color: isDark ? RoyalColors.pearlWhite : RoyalColors.midnightNavy,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        LinearProgressIndicator(
                                          value: _uploadProgress > 0 ? _uploadProgress : null,
                                          backgroundColor: isDark ? const Color(0x33C5A04A) : const Color(0x1AC5A04A),
                                          color: RoyalColors.royalGold,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],

                                // Submit Button
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: RoyalGradients.metallicGold,
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: [
                                      BoxShadow(
                                        color: RoyalColors.royalGold.withValues(alpha: 0.4),
                                        blurRadius: 14,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: _isUploading ? null : _startUpload,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      foregroundColor: RoyalColors.midnightNavy,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    child: _isUploading
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: RoyalColors.midnightNavy,
                                            ),
                                          )
                                        : const Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.cloud_upload_rounded, size: 20),
                                              SizedBox(width: 8),
                                              Text(
                                                'Upload Document',
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w800,
                                                  letterSpacing: 0.3,
                                                ),
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
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
    );
  }

  Widget _buildFileDropZone(bool isDark) {
    final file = _selectedFile;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xE60D1630) : const Color(0xF2FAF7F0),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: file != null
                  ? RoyalColors.emeraldActive
                  : (isDark ? RoyalColors.glassGoldBorder : RoyalColors.ivoryBorder),
              width: file != null ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  gradient: file != null ? null : RoyalGradients.metallicGold,
                  color: file != null ? const Color(0x2610B981) : null,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: (file != null ? RoyalColors.emeraldActive : RoyalColors.royalGold)
                          .withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  file != null ? Icons.check_circle_rounded : Icons.cloud_upload_rounded,
                  size: 28,
                  color: file != null ? RoyalColors.emeraldActive : RoyalColors.midnightNavy,
                ),
              ),
              const SizedBox(height: 14),
              if (file != null) ...[
                Text(
                  file.name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: isDark ? RoyalColors.pearlWhite : RoyalColors.midnightNavy,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${FileUtils.formatBytes(file.size)} • PDF Verified',
                  style: const TextStyle(
                    fontSize: 12,
                    color: RoyalColors.emeraldActive,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: _isUploading ? null : _pickPdfFile,
                  icon: const Icon(Icons.refresh_rounded, size: 15),
                  label: const Text('Change File'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark ? RoyalColors.pearlWhite : RoyalColors.midnightNavy,
                    side: BorderSide(
                      color: isDark ? RoyalColors.glassGoldBorder : RoyalColors.ivoryBorder,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ] else ...[
                Text(
                  'Select a PDF Document',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isDark ? RoyalColors.pearlWhite : RoyalColors.midnightNavy,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Academic lecture notes, question banks, or reference material up to 50 MB',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? RoyalColors.textSlateMuted : RoyalColors.textNavyMuted,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _isUploading ? null : _pickPdfFile,
                  icon: const Icon(Icons.attach_file_rounded, size: 16),
                  label: const Text('Choose PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? const Color(0x33101B3B) : const Color(0xFFEFE8DB),
                    foregroundColor: isDark ? RoyalColors.pearlWhite : RoyalColors.midnightNavy,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(
                        color: isDark ? RoyalColors.glassGoldBorder : RoyalColors.ivoryBorder,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip({
    required String label,
    required String category,
    required IconData icon,
    required bool isDark,
  }) {
    final isSelected = _selectedCategory == category;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isUploading
            ? null
            : () => setState(() => _selectedCategory = category),
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            gradient: isSelected ? RoyalGradients.metallicGold : null,
            color: isSelected
                ? null
                : (isDark ? const Color(0x33090F22) : Colors.white),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? RoyalColors.royalGold
                  : (isDark ? RoyalColors.glassGoldBorder : RoyalColors.ivoryBorder),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 15,
                color: isSelected
                    ? RoyalColors.midnightNavy
                    : (isDark ? RoyalColors.textSlateMuted : RoyalColors.textNavyMuted),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected
                      ? RoyalColors.midnightNavy
                      : (isDark ? RoyalColors.pearlWhite : RoyalColors.midnightNavy),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
