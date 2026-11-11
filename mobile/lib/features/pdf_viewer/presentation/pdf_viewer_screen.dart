import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/models/file_model.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/royal_design_system.dart';
import '../../../core/utils/file_utils.dart';
import '../../../shared/dialogs/download_options_sheet.dart';
import '../../../widgets/noteshub_app_bar.dart';
import '../../downloads/logic/download_cubit.dart';
import '../../downloads/logic/download_state.dart';

// Platform-conditional file helper
import 'dart:io' if (dart.library.html) '../../../core/storage/web_storage_stub.dart' as io;

class PdfViewerScreen extends StatefulWidget {
  final String title;
  final String? pdfUrl;
  final String? localPath;
  final FileModel? fileModel;

  const PdfViewerScreen({
    super.key,
    required this.title,
    this.pdfUrl,
    this.localPath,
    this.fileModel,
  });

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  late final PdfViewerController _pdfViewerController;
  PdfTextSearcher? _textSearcher;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final FocusNode _keyboardFocusNode = FocusNode();

  int _pageCount = 0;
  int _currentPage = 1;
  double _zoomLevel = 1.0;
  int _quarterTurns = 0;

  bool _isLoading = true;
  bool _isFetchingNetwork = false;
  double _downloadProgress = 0.0;
  bool _hasError = false;
  String _errorMessage = '';
  Key _viewerKey = UniqueKey();

  bool _isFullScreen = false;
  bool _isSearchActive = false;
  bool _isOpeningExternal = false;

  Uint8List? _pdfBytes;

  String? get _resolvedLocalPath {
    if (widget.localPath != null && widget.localPath!.isNotEmpty) {
      return widget.localPath;
    }
    if (widget.fileModel != null) {
      try {
        final downloadState = context.read<DownloadCubit>().state;
        if (downloadState.isFileDownloaded(widget.fileModel!.id)) {
          final doc = downloadState.allDocuments.firstWhere((d) => d.id == widget.fileModel!.id);
          return doc.localPath;
        }
      } catch (_) {}
    }
    return null;
  }

  bool get _isLocalFileAvailable {
    if (kIsWeb) return false;
    final path = _resolvedLocalPath;
    if (path == null || path.isEmpty) return false;
    try {
      final f = io.File(path);
      return f.existsSync() && f.lengthSync() > 0;
    } catch (_) {
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    _pdfViewerController = PdfViewerController();
    _pdfViewerController.addListener(_onControllerChanged);

    if (!_isLocalFileAvailable) {
      _fetchRemotePdf();
    }
  }

  void _initSearcherIfNeeded() {
    if (_textSearcher == null && _pdfViewerController.isReady) {
      _textSearcher = PdfTextSearcher(_pdfViewerController)..addListener(_onSearchChanged);
    }
  }

  @override
  void dispose() {
    _pdfViewerController.removeListener(_onControllerChanged);
    _textSearcher?.removeListener(_onSearchChanged);
    _textSearcher?.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (!mounted) return;
    if (!_pdfViewerController.isReady) return;

    final newZoom = _pdfViewerController.currentZoom;
    final newPage = _pdfViewerController.pageNumber;

    if ((newZoom - _zoomLevel).abs() > 0.005 || (newPage != null && newPage != _currentPage)) {
      setState(() {
        _zoomLevel = newZoom;
        if (newPage != null) _currentPage = newPage;
      });
    }
  }

  void _onSearchChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _fetchRemotePdf() async {
    final rawUrl = widget.pdfUrl ?? widget.fileModel?.url ?? '';
    final effectiveUrl = ApiClient.getRawStreamingUrl(rawUrl);

    if (effectiveUrl.isEmpty) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isFetchingNetwork = false;
        _hasError = true;
        _errorMessage = 'No document URL was provided.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _isFetchingNetwork = true;
      _hasError = false;
      _errorMessage = '';
      _downloadProgress = 0.0;
    });

    try {
      final response = await ApiClient.client.get<List<int>>(
        effectiveUrl,
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
          validateStatus: (status) => status != null && status >= 200 && status < 300,
          headers: {
            'Accept': 'application/pdf, */*',
          },
        ),
        onReceiveProgress: (received, total) {
          if (mounted && total > 0) {
            setState(() {
              _downloadProgress = received / total;
            });
          }
        },
      );

      final bytes = response.data;
      if (bytes == null || bytes.isEmpty) {
        throw Exception('The server returned empty document data.');
      }

      if (!mounted) return;

      setState(() {
        _pdfBytes = Uint8List.fromList(bytes);
        _isFetchingNetwork = false;
        _viewerKey = UniqueKey();
      });
    } on DioException catch (dioErr) {
      if (!mounted) return;

      String friendlyMessage = 'Failed to download the document.';
      if (dioErr.type == DioExceptionType.connectionTimeout ||
          dioErr.type == DioExceptionType.receiveTimeout) {
        friendlyMessage = 'Connection timed out while loading the document.';
      } else if (dioErr.response?.statusCode == 404) {
        friendlyMessage = 'The requested document was not found (HTTP 404).';
      } else if (dioErr.type == DioExceptionType.connectionError) {
        friendlyMessage = 'Unable to connect to document server. Please check your internet connection.';
      }

      setState(() {
        _isLoading = false;
        _isFetchingNetwork = false;
        _hasError = true;
        _errorMessage = friendlyMessage;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isFetchingNetwork = false;
        _hasError = true;
        _errorMessage = 'Could not load PDF document: $e';
      });
    }
  }

  void _retryLoading() {
    if (_isLocalFileAvailable) {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _errorMessage = '';
        _viewerKey = UniqueKey();
      });
    } else {
      _fetchRemotePdf();
    }
  }

  // --- Zoom Controls ---
  void _zoomIn() {
    if (_pdfViewerController.isReady) {
      _pdfViewerController.zoomUp();
    }
  }

  void _zoomOut() {
    if (_pdfViewerController.isReady) {
      _pdfViewerController.zoomDown();
    }
  }

  void _resetZoom() {
    if (_pdfViewerController.isReady) {
      _pdfViewerController.setZoom(_pdfViewerController.centerPosition, 1.0);
    }
  }

  void _fitToWidth() {
    if (_pdfViewerController.isReady) {
      final fitScale = _pdfViewerController.alternativeFitScale ?? 1.0;
      _pdfViewerController.setZoom(_pdfViewerController.centerPosition, fitScale);
    }
  }

  void _rotateClockwise() {
    setState(() {
      _quarterTurns = (_quarterTurns + 1) % 4;
    });
  }

  void _toggleFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
      if (_isFullScreen) _isSearchActive = false;
    });
  }

  // --- Text Search ---
  void _onSearchQueryChanged(String query) {
    _initSearcherIfNeeded();
    if (_textSearcher == null) return;

    if (query.trim().isEmpty) {
      _textSearcher!.resetTextSearch();
      return;
    }
    _textSearcher!.startTextSearch(query.trim(), caseInsensitive: true);
  }

  void _nextSearchResult() {
    _textSearcher?.goToNextMatch();
  }

  void _previousSearchResult() {
    _textSearcher?.goToPrevMatch();
  }

  void _closeSearch() {
    _textSearcher?.resetTextSearch();
    _searchController.clear();
    setState(() {
      _isSearchActive = false;
    });
  }

  // --- External App Handoff (Open In) ---
  Future<void> _handleOpenIn() async {
    if (_isOpeningExternal) return;
    setState(() => _isOpeningExternal = true);

    try {
      final rawUrl = widget.pdfUrl ?? widget.fileModel?.url ?? '';
      final effectiveUrl = ApiClient.getRawStreamingUrl(rawUrl);

      // On Web: Open document in a new browser tab / native viewer window
      if (kIsWeb) {
        if (effectiveUrl.isNotEmpty) {
          final uri = Uri.parse(effectiveUrl);
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
        return;
      }

      // Native mobile & desktop flow
      String? filePath = _resolvedLocalPath;

      // If viewing online without local storage, write memory bytes to cache file
      if ((filePath == null || filePath.isEmpty || !io.File(filePath).existsSync()) && _pdfBytes != null) {
        try {
          final tempDir = await getTemporaryDirectory();
          final safeName = FileUtils.sanitizeFileName(widget.title.endsWith('.pdf') ? widget.title : '${widget.title}.pdf');
          final targetPath = '${tempDir.path}/$safeName';
          final tempFile = io.File(targetPath);
          await tempFile.writeAsBytes(_pdfBytes!, flush: true);
          filePath = targetPath;
        } catch (_) {
          // Fall through to direct URL launch if temp file write fails
        }
      }

      if (filePath != null && io.File(filePath).existsSync()) {
        final openResult = await OpenFilex.open(filePath, type: 'application/pdf');

        if (openResult.type != ResultType.done && mounted) {
          // Fallback to native share sheet (e.g. Save to Files on iOS or app chooser on Android)
          final xFile = XFile(filePath, name: widget.title, mimeType: 'application/pdf');
          await Share.shareXFiles([xFile], text: widget.title);
        }
      } else if (effectiveUrl.isNotEmpty) {
        await launchUrl(Uri.parse(effectiveUrl), mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open external application: $e'),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isOpeningExternal = false);
    }
  }

  void _showJumpToPageDialog() {
    if (_pageCount <= 1) return;

    final controller = TextEditingController(text: '$_currentPage');
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
                  Icons.auto_stories_rounded,
                  color: RoyalColors.midnightNavy,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Jump to Page',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: isDark ? RoyalColors.pearlWhite : RoyalColors.midnightNavy,
                ),
              ),
            ],
          ),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            autofocus: true,
            style: TextStyle(
              color: isDark ? RoyalColors.pearlWhite : RoyalColors.midnightNavy,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              labelText: 'Page Number (1 - $_pageCount)',
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
                  final page = int.tryParse(controller.text.trim());
                  if (page != null && page >= 1 && page <= _pageCount) {
                    Navigator.of(ctx).pop();
                    _pdfViewerController.goToPage(pageNumber: page);
                  }
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
                  'Go',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Keyboard shortcut listener for desktop / laptop
  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    final isCtrlPressed = HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed;

    if (isCtrlPressed && event.logicalKey == LogicalKeyboardKey.keyF) {
      setState(() {
        _isSearchActive = true;
        _isFullScreen = false;
      });
      _searchFocusNode.requestFocus();
    } else if (event.logicalKey == LogicalKeyboardKey.arrowRight ||
        event.logicalKey == LogicalKeyboardKey.pageDown) {
      if (_searchFocusNode.hasFocus) return;
      if (_currentPage < _pageCount) {
        _pdfViewerController.goToPage(pageNumber: _currentPage + 1);
      }
    } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
        event.logicalKey == LogicalKeyboardKey.pageUp) {
      if (_searchFocusNode.hasFocus) return;
      if (_currentPage > 1) {
        _pdfViewerController.goToPage(pageNumber: _currentPage - 1);
      }
    } else if (event.logicalKey == LogicalKeyboardKey.equal && isCtrlPressed) {
      _zoomIn();
    } else if (event.logicalKey == LogicalKeyboardKey.minus && isCtrlPressed) {
      _zoomOut();
    } else if (event.logicalKey == LogicalKeyboardKey.digit0 && isCtrlPressed) {
      _resetZoom();
    } else if (event.logicalKey == LogicalKeyboardKey.escape) {
      if (_isSearchActive) {
        _closeSearch();
      } else if (_isFullScreen) {
        _toggleFullScreen();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final file = widget.fileModel;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final viewerParams = PdfViewerParams(
      margin: 12.0,
      backgroundColor: isDark ? const Color(0xFF070B18) : const Color(0xFFF5F0E6),
      minScale: 0.1,
      maxScale: 6.0,
      useAlternativeFitScaleAsMinScale: false,
      boundaryMargin: const EdgeInsets.all(80),
      enableKeyboardNavigation: true,
      pagePaintCallbacks: [
        (canvas, pageRect, page) {
          _textSearcher?.pageTextMatchPaintCallback(canvas, pageRect, page);
        },
      ],
      onViewerReady: (document, controller) {
        if (!mounted) return;
        _initSearcherIfNeeded();
        setState(() {
          _isLoading = false;
          _hasError = false;
          _pageCount = document.pages.length;
          _currentPage = controller.pageNumber ?? 1;
          _zoomLevel = controller.currentZoom;
        });
      },
      onPageChanged: (pageNumber) {
        if (!mounted || pageNumber == null) return;
        setState(() {
          _currentPage = pageNumber;
        });
      },
      errorBannerBuilder: (context, error, stackTrace, documentRef) {
        return _buildErrorScreen(isDark, customMessage: error.toString());
      },
    );

    return KeyboardListener(
      focusNode: _keyboardFocusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF070B18) : const Color(0xFFF5F0E6),
        body: SafeArea(
          child: Column(
            children: [
              // 1. Top App Bar (Hidden in Full-Screen reading mode)
              if (!_isFullScreen)
                NotesHubAppBar(
                  title: widget.title,
                  subtitle: _pageCount > 0
                      ? 'Page $_currentPage of $_pageCount • ${(_zoomLevel * 100).toInt()}%'
                      : 'Loading document...',
                  showAdminControls: false,
                  showDownloadsButton: false,
                  actions: [
                    // Search in Document Button
                    IconButton(
                      icon: Icon(
                        _isSearchActive ? Icons.search_off_rounded : Icons.search_rounded,
                        size: 20,
                      ),
                      color: _isSearchActive ? RoyalColors.cyanInteractive : RoyalColors.royalGold,
                      tooltip: 'Search text (Ctrl+F)',
                      onPressed: () {
                        setState(() {
                          _isSearchActive = !_isSearchActive;
                          if (_isSearchActive) {
                            _searchFocusNode.requestFocus();
                          } else {
                            _closeSearch();
                          }
                        });
                      },
                    ),

                    // Rotate document
                    IconButton(
                      icon: const Icon(Icons.rotate_right_rounded, size: 20),
                      color: RoyalColors.royalGold,
                      tooltip: 'Rotate 90°',
                      onPressed: _rotateClockwise,
                    ),

                    // Open In external app
                    IconButton(
                      icon: _isOpeningExternal
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: RoyalColors.royalGold,
                              ),
                            )
                          : const Icon(Icons.open_in_new_rounded, size: 20),
                      color: RoyalColors.royalGold,
                      tooltip: 'Open in external PDF reader',
                      onPressed: _handleOpenIn,
                    ),

                    // Full-screen mode toggle
                    IconButton(
                      icon: const Icon(Icons.fullscreen_rounded, size: 21),
                      color: RoyalColors.royalGold,
                      tooltip: 'Full-screen mode',
                      onPressed: _toggleFullScreen,
                    ),

                    // Download / Offline Status badge
                    if (file != null)
                      BlocBuilder<DownloadCubit, DownloadState>(
                        builder: (context, downloadState) {
                          final isDownloaded = downloadState.isFileDownloaded(file.id);
                          final isDownloading = downloadState.isFileDownloading(file.id);

                          if (isDownloading) {
                            final progress = downloadState.getDownloadProgress(file.id) ?? 0.0;
                            return Container(
                              margin: const EdgeInsets.only(right: 8),
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                value: progress > 0 ? progress : null,
                                strokeWidth: 2.2,
                                color: RoyalColors.royalGold,
                              ),
                            );
                          }

                          if (isDownloaded) {
                            return Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0x2610B981),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: RoyalColors.emeraldActive.withValues(alpha: 0.4),
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_circle_rounded, size: 12, color: RoyalColors.emeraldActive),
                                  SizedBox(width: 4),
                                  Text(
                                    'Offline',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: RoyalColors.emeraldActive,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          return IconButton(
                            icon: const Icon(Icons.download_rounded, size: 20),
                            color: RoyalColors.royalGold,
                            tooltip: 'Download options',
                            onPressed: () => DownloadOptionsSheet.show(context, file),
                          );
                        },
                      ),
                  ],
                ),

              // 2. Active Search Bar Overlay
              if (_isSearchActive && !_isFullScreen)
                _buildSearchBar(isDark),

              // 3. Document Canvas Area
              Expanded(
                child: Stack(
                  children: [
                    // Hardware-accelerated pdfrx rendering canvas
                    if (!_hasError)
                      Positioned.fill(
                        child: _buildViewerWithRotation(viewerParams),
                      ),

                    // Loading overlay
                    if (_isLoading && !_hasError)
                      Container(
                        color: isDark ? const Color(0xFF070B18) : const Color(0xFFF5F0E6),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const CircularProgressIndicator(
                                color: RoyalColors.royalGold,
                              ),
                              const SizedBox(height: 18),
                              Text(
                                _isFetchingNetwork
                                    ? (_downloadProgress > 0
                                        ? 'Streaming document (${(_downloadProgress * 100).toInt()}%)...'
                                        : 'Connecting to document server...')
                                    : (_isLocalFileAvailable
                                        ? 'Opening offline copy...'
                                        : 'Rendering PDF pages...'),
                                style: TextStyle(
                                  color: isDark ? RoyalColors.pearlWhite : RoyalColors.midnightNavy,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Error Screen
                    if (_hasError) _buildErrorScreen(isDark),

                    // Floating Bottom Controls Pill (Zoom, Pages, Search, Full-screen)
                    if (!_hasError && !_isLoading)
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 16,
                        child: Center(
                          child: _buildBottomToolbar(isDark),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildViewerWithRotation(PdfViewerParams params) {
    final viewer = _buildPdfViewer(params);
    if (_quarterTurns == 0) return viewer;
    return RotatedBox(quarterTurns: _quarterTurns, child: viewer);
  }

  Widget _buildPdfViewer(PdfViewerParams params) {
    // 1. If physical local file is present on native, load offline file
    final localPath = _resolvedLocalPath;
    if (_isLocalFileAvailable && !kIsWeb && localPath != null) {
      return PdfViewer.file(
        localPath,
        key: _viewerKey,
        controller: _pdfViewerController,
        params: params,
      );
    }

    // 2. In-memory bytes loaded reliably via Dio (Web and Native)
    if (_pdfBytes != null) {
      return PdfViewer.data(
        _pdfBytes!,
        sourceName: widget.title,
        key: _viewerKey,
        controller: _pdfViewerController,
        params: params,
      );
    }

    // 3. Fallback to direct URI streaming
    final rawUrl = widget.pdfUrl ?? widget.fileModel?.url ?? '';
    final effectiveUrl = ApiClient.getRawStreamingUrl(rawUrl);
    if (effectiveUrl.isNotEmpty) {
      return PdfViewer.uri(
        Uri.parse(effectiveUrl),
        key: _viewerKey,
        controller: _pdfViewerController,
        params: params,
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildSearchBar(bool isDark) {
    final searcher = _textSearcher;
    final totalMatches = searcher?.matches.length ?? 0;
    final currentMatch = (searcher != null && searcher.currentIndex != null && totalMatches > 0)
        ? searcher.currentIndex! + 1
        : 0;
    final isSearching = searcher?.isSearching ?? false;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xF20D1630) : const Color(0xF7FAF7F0),
        border: Border(
          bottom: BorderSide(
            color: isDark ? RoyalColors.glassGoldBorder : RoyalColors.ivoryBorder,
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, size: 18, color: RoyalColors.royalGold),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              autofocus: true,
              style: TextStyle(
                color: isDark ? RoyalColors.pearlWhite : RoyalColors.midnightNavy,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: 'Search text inside document...',
                hintStyle: TextStyle(
                  color: isDark ? RoyalColors.textDisabled : RoyalColors.textNavySubtle,
                  fontSize: 13,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
              onChanged: _onSearchQueryChanged,
            ),
          ),
          if (totalMatches > 0) ...[
            Text(
              '$currentMatch of $totalMatches',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isDark ? RoyalColors.champagne : const Color(0xFF8A6715),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.keyboard_arrow_up_rounded, size: 20),
              color: RoyalColors.royalGold,
              tooltip: 'Previous match',
              onPressed: _previousSearchResult,
            ),
            IconButton(
              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
              color: RoyalColors.royalGold,
              tooltip: 'Next match',
              onPressed: _nextSearchResult,
            ),
          ] else if (_searchController.text.isNotEmpty) ...[
            Text(
              isSearching ? 'Searching...' : 'No matches',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark ? RoyalColors.textSlateMuted : RoyalColors.textNavyMuted,
              ),
            ),
          ],
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 18),
            color: isDark ? RoyalColors.textSlateMuted : RoyalColors.textNavyMuted,
            tooltip: 'Close search',
            onPressed: _closeSearch,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomToolbar(bool isDark) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xE60D1630) : const Color(0xF2FAF7F0),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? RoyalColors.glassGoldBorder : RoyalColors.ivoryBorder,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Previous Page
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded, size: 22),
                color: isDark ? RoyalColors.pearlWhite : RoyalColors.midnightNavy,
                tooltip: 'Previous page',
                onPressed: _currentPage > 1
                    ? () => _pdfViewerController.goToPage(pageNumber: _currentPage - 1)
                    : null,
              ),

              // Page tracker badge (Clickable to jump)
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _showJumpToPageDialog,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0x33101B3B) : const Color(0x33C5A04A),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark ? RoyalColors.glassGoldBorder : const Color(0xFFC5A04A),
                      ),
                    ),
                    child: Text(
                      '$_currentPage / $_pageCount',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: isDark ? RoyalColors.champagne : const Color(0xFF8A6715),
                      ),
                    ),
                  ),
                ),
              ),

              // Next Page
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded, size: 22),
                color: isDark ? RoyalColors.pearlWhite : RoyalColors.midnightNavy,
                tooltip: 'Next page',
                onPressed: _currentPage < _pageCount
                    ? () => _pdfViewerController.goToPage(pageNumber: _currentPage + 1)
                    : null,
              ),

              // Vertical divider
              Container(
                height: 18,
                width: 1,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                color: isDark ? RoyalColors.glassGoldBorder : RoyalColors.ivoryBorder,
              ),

              // Zoom Out
              IconButton(
                icon: const Icon(Icons.remove_rounded, size: 18),
                color: isDark ? RoyalColors.pearlWhite : RoyalColors.midnightNavy,
                tooltip: 'Zoom out (-)',
                onPressed: _zoomLevel > 0.15 ? _zoomOut : null,
              ),

              // Current Zoom indicator (Clickable to reset to 100%)
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _resetZoom,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Text(
                      '${(_zoomLevel * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isDark ? RoyalColors.champagne : const Color(0xFF8A6715),
                      ),
                    ),
                  ),
                ),
              ),

              // Zoom In
              IconButton(
                icon: const Icon(Icons.add_rounded, size: 18),
                color: isDark ? RoyalColors.pearlWhite : RoyalColors.midnightNavy,
                tooltip: 'Zoom in (+)',
                onPressed: _zoomLevel < 5.8 ? _zoomIn : null,
              ),

              // Fit to Width
              IconButton(
                icon: const Icon(Icons.fit_screen_rounded, size: 18),
                color: RoyalColors.royalGold,
                tooltip: 'Fit to width',
                onPressed: _fitToWidth,
              ),

              // Full-screen Toggle
              IconButton(
                icon: Icon(
                  _isFullScreen ? Icons.fullscreen_exit_rounded : Icons.fullscreen_rounded,
                  size: 20,
                ),
                color: RoyalColors.royalGold,
                tooltip: _isFullScreen ? 'Exit full-screen' : 'Full-screen mode',
                onPressed: _toggleFullScreen,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorScreen(bool isDark, {String? customMessage}) {
    final file = widget.fileModel;
    final message = customMessage ?? _errorMessage;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0x26EF4444),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: const Color(0x59EF4444),
                ),
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                size: 32,
                color: Color(0xFFEF4444),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Could not open PDF',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: isDark ? RoyalColors.pearlWhite : RoyalColors.midnightNavy,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message.isNotEmpty
                  ? message
                  : 'The PDF document could not be loaded. Please verify your internet connection or try again.',
              style: TextStyle(
                color: isDark ? RoyalColors.textSlateMuted : RoyalColors.textNavyMuted,
                fontSize: 13,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: _retryLoading,
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Retry'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark ? RoyalColors.pearlWhite : RoyalColors.midnightNavy,
                    side: BorderSide(
                      color: isDark ? RoyalColors.glassGoldBorder : RoyalColors.ivoryBorder,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  ),
                ),
                if (file != null) ...[
                  const SizedBox(width: 12),
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
                    child: ElevatedButton.icon(
                      onPressed: () => DownloadOptionsSheet.show(context, file),
                      icon: const Icon(Icons.download_rounded, size: 16),
                      label: const Text('Download Options'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: RoyalColors.midnightNavy,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        textStyle: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
