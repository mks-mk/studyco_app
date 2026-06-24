import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:no_screenshot/no_screenshot.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:get/get.dart';
import 'package:studyco_app/controllers/bookmark/bookmarkController.dart';
import 'package:url_launcher/url_launcher.dart';

class PremiumPdfViewPage extends StatefulWidget {
  final String url;
  final String? title;
  final bool isOfflineFile;
  final String materialId;
  final String subject;

  const PremiumPdfViewPage({
    super.key,
    required this.url,
    this.title,
    this.materialId = 'null',
    this.subject = 'null',
    this.isOfflineFile = false,
  });

  @override
  State<PremiumPdfViewPage> createState() => _PremiumPdfViewPageState();
}

class _PremiumPdfViewPageState extends State<PremiumPdfViewPage> {
  late PdfViewerController _controller;
  bool _showControls = true;
  int _currentPage = 1;
  int _totalPages = 0;
  String? _searchText;
  bool _isSearching = false;
  final _noScreenshot = NoScreenshot.instance;

  // ADD: Variables for offline file handling
  Uint8List? _documentBytes;
  bool _isLoadingOfflineFile = false;

  final bookmarkController = Get.find<BookmarkController>();

  Future<void> secureScreen() async {
    await _noScreenshot.screenshotOff();
  }

  @override
  void initState() {
    super.initState();
    _controller = PdfViewerController();
    secureScreen();

    // ADD: Load offline file if needed
    if (widget.isOfflineFile) {
      _loadOfflineFile();
    }
  }

  // ADD: Method to load offline file into memory
  Future<void> _loadOfflineFile() async {
    try {
      setState(() {
        _isLoadingOfflineFile = true;
      });

      final file = File(widget.url);
      if (await file.exists()) {
        _documentBytes = await file.readAsBytes();
      } else {
        throw Exception('Offline file not found');
      }

      setState(() {
        _isLoadingOfflineFile = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingOfflineFile = false;
      });
      print('Error loading offline file: $e');
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: PreferredSize(
        preferredSize: Size(double.infinity, 50),
        child: AppBar(
          title: Text(
            widget.title ?? 'Premium PDF Viewer',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.grey[900],
          foregroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () => Get.back(),
          ),
          actions: [
            // Search Button
            IconButton(
              icon: Icon(_isSearching ? Icons.search_off : Icons.search),
              onPressed: () {
                setState(() {
                  _isSearching = !_isSearching;
                });
              },
            ),
            // Controls Toggle
            IconButton(
              icon: Icon(
                _showControls ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: () {
                setState(() {
                  _showControls = !_showControls;
                });
              },
            ),
            // Page Counter
            if (_totalPages > 0)
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: GestureDetector(
                    onTap: _showPageJumpDialog,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '$_currentPage / $_totalPages',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      body: Stack(
        children: [
          _buildPdfViewer(),

          // Premium Control Overlay
          if (_showControls) _buildPremiumControls(),

          // Search Overlay
          if (_isSearching) _buildSearchOverlay(),
        ],
      ),
    );
  }

  // ADD: Method to build appropriate PDF viewer
  Widget _buildPdfViewer() {
    if (widget.isOfflineFile) {
      if (_isLoadingOfflineFile) {
        return _buildOfflineLoadingIndicator();
      } else if (_documentBytes != null) {
        // Load from memory for offline files
        return PdfViewer.data(
          _documentBytes!,
          controller: _controller,
          params: _getPdfViewerParams(),
          sourceName: widget.title ?? "Material",
        );
      } else {
        return _buildPremiumErrorView('Failed to load offline file');
      }
    } else {
      // Load from URL for online files (your existing code)
      return PdfViewer.uri(
        Uri.parse(widget.url),
        controller: _controller,
        params: _getPdfViewerParams(),
      );
    }
  }

  // ADD: Extract PDF viewer parameters to reuse
  PdfViewerParams _getPdfViewerParams() {
    return PdfViewerParams(
      textSelectionParams: PdfTextSelectionParams(enabled: true),
      // Premium Features Configuration
      maxScale: 8.0,
      minScale: 0.25,
      linkHandlerParams: PdfLinkHandlerParams(
        onLinkTap: (link) async {
          if (link.url != null) {
            launchUrl(link.url!);
          } else if (link.dest != null) {
            _controller.goToDest(link.dest);
          }
        },
      ),
      panEnabled: true,
      scaleEnabled: true,
      pageAnchor: PdfPageAnchor.top,
      margin: 10,
      backgroundColor: Colors.grey[850]!,

      // Loading and error builders
      loadingBannerBuilder: (context, bytesDownloaded, totalBytes) {
        return _buildPremiumLoadingIndicator(bytesDownloaded, totalBytes);
      },
      errorBannerBuilder: (context, error, stackTrace, documentRef) {
        return _buildPremiumErrorView(error);
      },

      // Document ready callback
      onViewerReady: (document, controller) {
        setState(() {
          _totalPages = document.pages.length;
        });
      },

      // Page change tracking
      onPageChanged: (pageNumber) {
        setState(() {
          _currentPage = pageNumber ?? 1;
        });
      },
    );
  }

  // ADD: Offline loading indicator
  Widget _buildOfflineLoadingIndicator() {
    return Container(
      color: Colors.black87,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: CircularProgressIndicator(
                strokeWidth: 6,
                backgroundColor: Colors.grey[700],
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Loading Offline Material...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.offline_pin, color: Colors.green, size: 16),
                SizedBox(width: 4),
                Text(
                  'Secure Offline Access',
                  style: TextStyle(color: Colors.green, fontSize: 14),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Your existing methods remain exactly the same...
  Widget _buildPremiumLoadingIndicator(int bytesDownloaded, int? totalBytes) {
    final progress =
        totalBytes != null && totalBytes > 0
            ? bytesDownloaded / totalBytes
            : null;

    return Container(
      color: Colors.black87,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 6,
                backgroundColor: Colors.grey[700],
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Loading Material...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            if (progress != null)
              Text(
                '${(progress * 100).toStringAsFixed(1)}% Complete',
                style: TextStyle(color: Colors.grey[300], fontSize: 14),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumErrorView(Object error) {
    return Container(
      color: Colors.grey[900],
      padding: EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red[900]?.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red[400],
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Unable to Load Material',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 12),
            Text(
              widget.isOfflineFile
                  ? 'The offline file may be corrupted or moved.'
                  : 'Please check your internet connection and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[400]),
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                if (widget.isOfflineFile) {
                  _loadOfflineFile();
                } else {
                  setState(() {});
                }
              },
              icon: Icon(Icons.refresh),
              label: Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumControls() {
    return Positioned(
      bottom: 20,
      left: 10,
      right: 10,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Previous Page
            _buildControlButton(
              icon: Icons.navigate_before, 
              label: '',
              onPressed:
                  _currentPage > 1 ? () => _goToPage(_currentPage - 1) : null,
            ),

            // Zoom Controls
            if (widget.isOfflineFile == false)
              Obx(
                ()=> _buildControlButton(
                  icon:
                      bookmarkController.isBookmarked(
                            subject: widget.subject,
                            id: widget.materialId,
                          )
                          ? Icons.bookmark_added_rounded
                          : Icons.bookmark_add_outlined,
                  label: 'Bookmark',
                  onPressed: () async {
                    await bookmarkController.toggleBookmark(
                      subject: widget.subject,
                      id: widget.materialId,
                    );
                  },
                ),
              ),
            _buildControlButton(
              icon: Icons.zoom_out,
              label: 'Zoom Out',
              onPressed: () => _controller.zoomDown(),
            ),
            _buildControlButton(
              icon: Icons.zoom_in,
              label: 'Zoom In',
              onPressed: () => _controller.zoomUp(),
            ),

            // Fit to Width
            _buildControlButton(
              icon: Icons.vertical_align_top,
              label: 'scroll to top',
              onPressed: () => _goToPage(1),
            ),

            // Next Page
            _buildControlButton(
              icon: Icons.navigate_next,
              label: '',
              onPressed:
                  _currentPage < _totalPages
                      ? () => _goToPage(_currentPage + 1)
                      : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color:
              onPressed != null
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: onPressed != null ? Colors.white : Colors.grey,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchOverlay() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        color: Colors.black.withValues(alpha: 0.9),
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search in Material...',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[600]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[600]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.blue),
                  ),
                  prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchText = value;
                  });
                  // Implement search functionality
                  if (value.isNotEmpty) {
                    // Use pdfrx search capabilities
                  }
                },
              ),
            ),
            SizedBox(width: 12),
            IconButton(
              icon: Icon(Icons.close, color: Colors.white),
              onPressed: () {
                setState(() {
                  _isSearching = false;
                  _searchText = null;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  void _goToPage(int pageNumber) {
    if (pageNumber >= 1 && pageNumber <= _totalPages) {
      _controller.goToPage(pageNumber: pageNumber);
      setState(() {
        _currentPage = pageNumber;
      });
    }
  }

  void _showPageJumpDialog() {
    final TextEditingController pageController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.grey[800],
            title: Text('Go to Page', style: TextStyle(color: Colors.white)),
            content: TextField(
              controller: pageController,
              keyboardType: TextInputType.number,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Page Number (1-$_totalPages)',
                labelStyle: TextStyle(color: Colors.grey[400]),
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey[600]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey[400]),
                ),
              ),
              TextButton(
                onPressed: () {
                  final pageNumber = int.tryParse(pageController.text);
                  if (pageNumber != null &&
                      pageNumber >= 1 &&
                      pageNumber <= _totalPages) {
                    _goToPage(pageNumber);
                    Navigator.pop(context);
                  }
                },
                child: Text('Go', style: TextStyle(color: Colors.blue)),
              ),
            ],
          ),
    );
  }
}
