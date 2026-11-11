import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/models/file_model.dart';
import '../../../core/repositories/file_repository.dart';
import '../../../core/repositories/subject_repository.dart';
import '../../../core/theme/animated_glass_background.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/royal_design_system.dart';
import '../../../shared/dialogs/download_options_sheet.dart';
import '../../../widgets/empty_state_view.dart';
import '../../../widgets/noteshub_app_bar.dart';
import '../../../widgets/noteshub_deck_cards.dart';
import '../../pdf_viewer/presentation/pdf_viewer_screen.dart';
import '../logic/search_cubit.dart';
import '../logic/search_state.dart';
import '../models/search_result_item.dart';

class SearchScreen extends StatelessWidget {
  final int? initialSemesterFilter;

  const SearchScreen({
    super.key,
    this.initialSemesterFilter,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final cubit = SearchCubit(
          fileRepository: context.read<FileRepository>(),
          subjectRepository: context.read<SubjectRepository>(),
        );
        cubit.loadCache().then((_) {
          if (initialSemesterFilter != null) {
            cubit.setSemesterFilter(initialSemesterFilter);
          }
        });
        return cubit;
      },
      child: const _SearchView(),
    );
  }
}

class _SearchView extends StatefulWidget {
  const _SearchView();

  @override
  State<_SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<_SearchView> {
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
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
                  // Top App Bar
                  const NotesHubAppBar(
                    title: 'Search Academic Notes',
                    subtitle: 'Full-text & acronym search across all subjects',
                  ),

                  // Search input & Filter row inside ResponsiveContainer
                  Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: AppConstants.maxWideContentWidth,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 10),

                          // Search Bar
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: LiquidGlassSearchBar(
                              controller: _controller,
                              focusNode: _focusNode,
                              hintText: "Search notes (e.g. 'WT mod 2', 'OS', 'DBMS')...",
                              onChanged: (val) {
                                context.read<SearchCubit>().setQuery(val);
                                setState(() {});
                              },
                              onClear: () {
                                _controller.clear();
                                context.read<SearchCubit>().clearQuery();
                                setState(() {});
                              },
                            ),
                          ),

                          const SizedBox(height: 10),

                          // Filter Pills Row
                          _buildFilterRow(context, isDark),

                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),

                  // Results Area
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: AppConstants.maxWideContentWidth,
                        ),
                        child: BlocBuilder<SearchCubit, SearchState>(
                          builder: (context, state) {
                            if (state is SearchLoading) {
                              return const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CircularProgressIndicator(
                                      color: RoyalColors.royalGold,
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'Loading notes catalog...',
                                      style: TextStyle(
                                        color: RoyalColors.textSlateMuted,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            if (state is SearchError) {
                              return EmptyStateView(
                                icon: Icons.error_outline_rounded,
                                title: 'Search Error',
                                message: state.message,
                                actionLabel: 'Retry',
                                onAction: () => context.read<SearchCubit>().loadCache(),
                              );
                            }

                            if (state is SearchLoaded) {
                              if (state.isInitialEmpty && state.query.trim().isEmpty) {
                                return _buildInitialTips(isDark);
                              }

                              if (state.results.isEmpty) {
                                return _buildNoResults(state.query);
                              }

                              return _buildResultsList(context, state.results);
                            }

                            return const SizedBox.shrink();
                          },
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

  Widget _buildFilterRow(BuildContext context, bool isDark) {
    return BlocBuilder<SearchCubit, SearchState>(
      builder: (context, state) {
        String? activeType;
        int? activeSem;

        if (state is SearchLoaded) {
          activeType = state.typeFilter;
          activeSem = state.semesterFilter;
        }

        final categories = [
          {'key': null, 'label': 'All Types'},
          {'key': FileCategory.notes, 'label': 'Lecture Notes'},
          {'key': FileCategory.qbank, 'label': 'Question Bank'},
          {'key': FileCategory.extra, 'label': 'Extra Resources'},
        ];

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              // Category Filter Pills
              ...categories.map((cat) {
                final key = cat['key'];
                final label = cat['label'] as String;
                final isSelected = activeType == key;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        context.read<SearchCubit>().setTypeFilter(key);
                      },
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
              }),

              // Divider
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Container(
                  height: 18,
                  width: 1,
                  color: isDark ? RoyalColors.glassGoldBorder : RoyalColors.ivoryBorder,
                ),
              ),

              // Semester 4 & 5 Pills
              ...[4, 5].map((sem) {
                final isSelected = activeSem == sem;
                return Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        context.read<SearchCubit>().setSemesterFilter(sem);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (isDark ? const Color(0xFF162248) : Colors.white)
                              : (isDark ? const Color(0x33101B3B) : const Color(0xB3FAF7F0)),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? (isDark ? RoyalColors.cyanInteractive : RoyalColors.royalGold)
                                : (isDark ? RoyalColors.glassGoldBorder : RoyalColors.ivoryBorder),
                            width: isSelected ? 1.4 : 1.0,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: isDark
                                        ? RoyalColors.cyanInteractive.withValues(alpha: 0.2)
                                        : RoyalColors.royalGold.withValues(alpha: 0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Text(
                          'Sem $sem',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: isSelected
                                ? (isDark ? RoyalColors.cyanInteractive : RoyalColors.royalGold)
                                : (isDark ? RoyalColors.textSlateMuted : RoyalColors.textNavyMuted),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInitialTips(bool isDark) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                gradient: RoyalGradients.metallicGold,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: RoyalColors.royalGold.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.search_rounded,
                size: 34,
                color: RoyalColors.midnightNavy,
              ),
            ),
            const SizedBox(height: 20),
            ShaderMask(
              shaderCallback: (bounds) => RoyalGradients.goldShimmer.createShader(bounds),
              child: const Text(
                'Search NOTEShub Catalog',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.4,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Search across all lecture notes, question banks, and modules by subject acronym or topic.',
              style: TextStyle(
                color: isDark ? RoyalColors.textSlateMuted : RoyalColors.textNavyMuted,
                fontSize: 13.5,
                height: 1.45,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _buildSearchChip('WT mod 2', isDark),
                _buildSearchChip('Operating Systems', isDark),
                _buildSearchChip('DBMS', isDark),
                _buildSearchChip('qbank module 1', isDark),
                _buildSearchChip('Computer Networks', isDark),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchChip(String label, bool isDark) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          _controller.text = label;
          context.read<SearchCubit>().setQuery(label);
          setState(() {});
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0x33101B3B) : const Color(0xF2FAF7F0),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? RoyalColors.glassGoldBorder : RoyalColors.ivoryBorder,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.search_rounded,
                size: 13,
                color: RoyalColors.royalGold,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isDark ? RoyalColors.pearlWhite : RoyalColors.midnightNavy,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoResults(String query) {
    return EmptyStateView(
      icon: Icons.search_off_rounded,
      title: 'No Documents Found',
      message: 'No study materials matched "$query". Try searching with subject acronyms (e.g. WT, OS, CN), module numbers, or topic names.',
    );
  }

  Widget _buildResultsList(BuildContext context, List<SearchResultItem> results) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: results.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = results[index];
        final file = item.file;

        return NotesHubResourceCard(
          title: file.name,
          moduleNumber: file.module,
          categoryType: file.type,
          fileMetadata: '${item.subjectDisplayName} • Sem ${file.semester}',
          onView: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PdfViewerScreen(
                  title: file.name,
                  pdfUrl: file.url,
                  fileModel: file,
                ),
              ),
            );
          },
          onDownload: () => DownloadOptionsSheet.show(context, file),
        );
      },
    );
  }
}
