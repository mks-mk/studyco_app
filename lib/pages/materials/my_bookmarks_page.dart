import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../Utilities/variables/app_colors.dart';
import '../../controllers/bookmark/bookmarkController.dart';
import '../../controllers/subjectController/getMaterialsWithSubjects.dart';
import '../../models/material_model.dart';
import '../pdf_viewer/pdf_view_page.dart';

class MyBookmarks extends StatefulWidget {
  final String subject; // Added subject parameter

  const MyBookmarks({
    super.key,
    this.subject = 'All', // Default to 'All' if no subject specified
  });

  @override
  State<MyBookmarks> createState() => _MyBookmarksState();
}

class _MyBookmarksState extends State<MyBookmarks> {
  // Filter and search state
  String searchQuery = '';
  String selectedSubject = 'All';
  List<int> selectedModules = [];
  List<String> selectedTypes = [];
  String selectedPriceFilter = '';
  bool isGridView = true;

  // Controllers
  late TextEditingController searchController;
  late FocusNode searchFocusNode;
  late BookmarkController bookmarkController;
  late MaterialsWithSubjectsController materialsController;

  // Bookmarked materials
  RxList<MaterialModel> bookmarkedMaterials = <MaterialModel>[].obs;
  RxBool isLoading = false.obs;

  @override
  void initState() {
    super.initState();

    // Initialize controllers
    searchController = TextEditingController();
    searchFocusNode = FocusNode();
    bookmarkController = Get.find<BookmarkController>();
    materialsController = Get.find<MaterialsWithSubjectsController>();

    // Set initial subject filter from parameter
    selectedSubject = widget.subject;

    // Fetch data after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchBookmarkedMaterials();
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> fetchBookmarkedMaterials() async {
    try {
      await Future.microtask(() async {
        isLoading.value = true;
        bookmarkedMaterials.clear();

        // Get all bookmarked subjects
        final bookmarkedSubjects = bookmarkController.getBookmarkedSubjects();

        for (String subject in bookmarkedSubjects) {
          // Get bookmark IDs for this subject
          final bookmarkIds = bookmarkController.getBookmarkedIds(subject: subject);

          if (bookmarkIds.isNotEmpty) {
            // Fetch materials for this subject
            await materialsController.fetchData(subject: subject);

            // Filter materials by bookmark IDs and add subject info
            final subjectMaterials = materialsController.materials
                .where((material) => bookmarkIds.contains(material.id))
                .map((material) => MaterialModelWithSubject.fromMaterial(material, subject))
                .toList();

            bookmarkedMaterials.addAll(subjectMaterials);
          }
        }

        print('Fetched ${bookmarkedMaterials.length} bookmarked materials');
      });
    } catch (e) {
      print('Error fetching bookmarked materials: $e');
      Future.delayed(Duration.zero, () {
        Get.snackbar(
          'Error',
          'Failed to load bookmarked materials: $e',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      });
    } finally {
      isLoading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final GlobalKey<LiquidPullToRefreshState> refreshIndicatorKey =
    GlobalKey<LiquidPullToRefreshState>();

    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.topLeft,
          radius: 1.6,
          colors: [Color(0xFFDDCFAF), Color(0xFFFFFFFF)],
          stops: [0.05, 0.80],
        ),
      ),
      child: LiquidPullToRefresh(
        key: refreshIndicatorKey,
        onRefresh: () async {
          await fetchBookmarkedMaterials();
        },
        backgroundColor: AppColor.backgroundColor,
        color: Colors.orange,
        springAnimationDurationInMilliseconds: 800,
        showChildOpacityTransition: false,
        height: 80,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Get.back(),
            ),
            title: Text(
              selectedSubject == 'All'
                  ? 'My Bookmarks'
                  : '$selectedSubject Bookmarks',
              style: TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              // Clear all bookmarks
              IconButton(
                icon: Icon(Icons.clear_all, color: Colors.red),
                onPressed: () => _showClearAllDialog(),
              ),
            ],
          ),
          body: SafeArea(
            child: Obx(
                  () => SingleChildScrollView( // Made the entire page scrollable
                physics: AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Enhanced Search Section
                      _buildEnhancedSearchSection(),

                      SizedBox(height: 12),

                      // Stats and Filter Section
                      _buildStatsAndFilters(),

                      // Filter Chips
                      if (_hasActiveFilters()) _buildActiveFilterChips(),

                      // Materials Grid/List
                      SizedBox(
                        height: Get.height * 0.6, // Fixed height for the content
                        child: Skeletonizer(
                          enabled: isLoading.value,
                          child: _getFilteredMaterials().isEmpty
                              ? _buildEmptyState()
                              : isGridView
                              ? _buildGridView()
                              : _buildListView(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Enhanced Search Section with different design
  Widget _buildEnhancedSearchSection() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search bar with enhanced design
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: TextField(
              controller: searchController,
              focusNode: searchFocusNode,
              onChanged: (value) {
                Future.microtask(() {
                  if (mounted) {
                    setState(() {
                      searchQuery = value;
                    });
                  }
                });
              },
              decoration: InputDecoration(
                hintText: selectedSubject == 'All'
                    ? "Search in all bookmarks..."
                    : "Search in $selectedSubject bookmarks...",
                hintStyle: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 16,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: Color(0xFFFFBB00),
                  size: 24,
                ),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    searchController.clear();
                    setState(() {
                      searchQuery = '';
                    });
                  },
                )
                    : null,
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
              ),
            ),
          ),

          SizedBox(height: 12),

          // Quick filter buttons
          Row(
            children: [
              Expanded(
                child: _buildQuickFilterButton(
                  'All Subjects',
                  selectedSubject == 'All',
                      () => setState(() => selectedSubject = 'All'),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _buildQuickFilterButton(
                  'Free Only',
                  selectedPriceFilter == 'free',
                      () => setState(() => selectedPriceFilter = selectedPriceFilter == 'free' ? '' : 'free'),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _buildQuickFilterButton(
                  'Paid Only',
                  selectedPriceFilter == 'paid',
                      () => setState(() => selectedPriceFilter = selectedPriceFilter == 'paid' ? '' : 'paid'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickFilterButton(String text, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFFFFBB00) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? Color(0xFFFFBB00) : Colors.grey.shade300,
          ),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  // Stats and Filters Section
  Widget _buildStatsAndFilters() {
    final filteredCount = _getFilteredMaterials().length;
    final totalCount = bookmarkedMaterials.length;
    final subjects = _getUniqueSubjects();

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Stats
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$filteredCount of $totalCount materials',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              Text(
                selectedSubject == 'All'
                    ? '${subjects.length} subjects'
                    : 'From $selectedSubject',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),

          // Action buttons
          Row(
            children: [
              // More filters
              GestureDetector(
                onTap: () => _showFilterBottomSheet(),
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _hasActiveFilters() ? Color(0xFFFFBB00) : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.filter_list,
                    color: _hasActiveFilters() ? Colors.white : Colors.grey[600],
                    size: 20,
                  ),
                ),
              ),

              SizedBox(width: 8),

              // View toggle
              GestureDetector(
                onTap: () => setState(() => isGridView = !isGridView),
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isGridView ? Icons.view_list : Icons.grid_view,
                    color: Colors.grey[600],
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Get unique subjects from bookmarked materials
  List<String> _getUniqueSubjects() {
    return bookmarkedMaterials
        .map((material) => (material as MaterialModelWithSubject).subject)
        .toSet()
        .toList();
  }

  // Filter materials based on search and filters
  List<MaterialModel> _getFilteredMaterials() {
    return bookmarkedMaterials.where((material) {
      final materialWithSubject = material as MaterialModelWithSubject;

      // Search filter
      bool matchesSearch = searchQuery.isEmpty ||
          material.noteName.toLowerCase().contains(searchQuery.toLowerCase());

      // Subject filter - ENHANCED for parameter support
      bool matchesSubject = selectedSubject == 'All' ||
          materialWithSubject.subject == selectedSubject;

      // Module filter
      bool matchesModule = selectedModules.isEmpty ||
          selectedModules.contains(material.module);

      // Type filter
      bool matchesType = selectedTypes.isEmpty ||
          selectedTypes.contains(material.type);

      // Price filter
      bool matchesPrice = selectedPriceFilter.isEmpty ||
          (selectedPriceFilter == 'free' && material.price == 0) ||
          (selectedPriceFilter == 'paid' && material.price > 0);

      return matchesSearch && matchesSubject && matchesModule && matchesType && matchesPrice;
    }).toList();
  }

  // Build Grid View
  Widget _buildGridView() {
    final filteredMaterials = _getFilteredMaterials();

    return GridView.builder(
      physics: AlwaysScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.65,
      ),
      itemCount: filteredMaterials.length,
      itemBuilder: (context, index) {
        final material = filteredMaterials[index] as MaterialModelWithSubject;

        return GestureDetector(
          onTap: () {
            if (material.type == "pdf" || material.type == "Pdf") {
              Get.to(() => PremiumPdfViewPage(
                url: material.source,
                title: material.noteName,
              ));
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: material.color,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: material.color.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image
                Expanded(
                  flex: 3,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                      color: material.color,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                      child: CachedNetworkImage(
                        imageUrl: material.thumbnail,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),

                // Content
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Subject badge
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color:material.color.computeLuminance() > 0.5
                                    ? Colors.white
                                    : Colors.black,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                material.subject,
                                style: TextStyle(
                                  color: material.color.computeLuminance() > 0.5
                                      ? Colors.black
                                      : Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: GestureDetector(
                                onTap: () async {
                                  Future.delayed(Duration.zero, () async {
                                    await bookmarkController.removeBookmarkedId(
                                      subject: material.subject,
                                      id: material.id,
                                    );
                                    await fetchBookmarkedMaterials();
                                  });
                                },
                                child: Icon(
                                  Icons.bookmark_remove,
                                  color: Colors.red,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 2),

                        // Title
                        Text(
                          material.noteName,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: material.color.computeLuminance() > 0.5
                                ? Colors.black
                                : Colors.white,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),

                        Spacer(),

                        // Price and bookmark
                        Container(
                          padding: EdgeInsets.symmetric(vertical: 2, horizontal: 6),
                          decoration: BoxDecoration(
                            color: material.price == 0 ? Colors.transparent : Colors.white,
                            borderRadius: BorderRadiusGeometry.circular(12)
                          ),
                          child: Text(
                            material.price == 0 ? '' : '₹${material.price}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.black
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Build List View
  Widget _buildListView() {
    final filteredMaterials = _getFilteredMaterials();

    return ListView.builder(
      physics: AlwaysScrollableScrollPhysics(),
      itemCount: filteredMaterials.length,
      itemBuilder: (context, index) {
        final material = filteredMaterials[index] as MaterialModelWithSubject;

        return Container(
          margin: EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                // Thumbnail
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: material.color,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: material.thumbnail,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                SizedBox(width: 16),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Subject and Module
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: material.color,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              material.subject,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Module ${material.module}',
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 8),

                      // Title
                      Text(
                        material.noteName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      SizedBox(height: 8),

                      // Type and Price
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.description, size: 16, color: Colors.grey[600]),
                              SizedBox(width: 4),
                              Text(
                                material.type,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              SizedBox(width: 16),
                              Text(
                                material.price == 0 ? '' : '₹${material.price}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: material.color,
                                ),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: () async {
                              Future.delayed(Duration.zero, () async {
                                await bookmarkController.removeBookmarkedId(
                                  subject: material.subject,
                                  id: material.id,
                                );
                                await fetchBookmarkedMaterials();
                              });
                            },
                            child: Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.red[50],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.bookmark_remove,
                                color: Colors.red,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Build Empty State
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bookmark_border,
            size: 80,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            searchQuery.isNotEmpty
                ? 'No bookmarks found'
                : selectedSubject == 'All'
                ? 'No bookmarks yet'
                : 'No $selectedSubject bookmarks',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            searchQuery.isNotEmpty
                ? 'Try adjusting your search or filters'
                : selectedSubject == 'All'
                ? 'Start bookmarking materials to see them here'
                : 'No bookmarked materials found for $selectedSubject',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          if (searchQuery.isNotEmpty || selectedSubject != 'All') ...[
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                searchController.clear();
                setState(() {
                  searchQuery = '';
                  selectedSubject = 'All';
                  selectedModules.clear();
                  selectedTypes.clear();
                  selectedPriceFilter = '';
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFFFBB00),
              ),
              child: Text('Show All Bookmarks', style: TextStyle(color: Colors.white)),
            ),
          ],
        ],
      ),
    );
  }

  // Build Active Filter Chips
  Widget _buildActiveFilterChips() {
    return Container(
      margin: EdgeInsets.only(bottom: 6,top: 8),
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // Subject filter chip
          if (selectedSubject != 'All')
            Container(
              margin: EdgeInsets.only(right: 8),
              child: Chip(
                label: Text(
                  selectedSubject,
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
                backgroundColor: Color(0xFFFFBB00),
                deleteIcon: Icon(Icons.close, color: Colors.white, size: 18),
                onDeleted: () => setState(() => selectedSubject = 'All'),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            ),

          // Module filter chips
          for (int module in selectedModules)
            Container(
              margin: EdgeInsets.only(right: 8),
              child: Chip(
                label: Text(
                  'Module $module',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
                backgroundColor: Color(0xFFFFBB00),
                deleteIcon: Icon(Icons.close, color: Colors.white, size: 18),
                onDeleted: () => setState(() => selectedModules.remove(module)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            ),

          // Type filter chips
          for (String type in selectedTypes)
            Container(
              margin: EdgeInsets.only(right: 8),
              child: Chip(
                label: Text(
                  type,
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
                backgroundColor: Color(0xFFFFBB00),
                deleteIcon: Icon(Icons.close, color: Colors.white, size: 18),
                onDeleted: () => setState(() => selectedTypes.remove(type)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            ),

          // Price filter chip
          if (selectedPriceFilter.isNotEmpty)
            Container(
              margin: EdgeInsets.only(right: 8),
              child: Chip(
                label: Text(
                  selectedPriceFilter == 'free' ? 'Free' : 'Paid',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
                backgroundColor: Color(0xFFFFBB00),
                deleteIcon: Icon(Icons.close, color: Colors.white, size: 18),
                onDeleted: () => setState(() => selectedPriceFilter = ''),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            ),

          // Clear all button
          if (_hasActiveFilters())
            GestureDetector(
              onTap: () {
                setState(() {
                  selectedSubject = widget.subject; // Reset to initial subject parameter
                  selectedModules.clear();
                  selectedTypes.clear();
                  selectedPriceFilter = '';
                });
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    'Clear All',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  bool _hasActiveFilters() {
    return selectedSubject != 'All' ||
        selectedModules.isNotEmpty ||
        selectedTypes.isNotEmpty ||
        selectedPriceFilter.isNotEmpty;
  }

  // Show Subject Filter Dialog
  void _showSubjectFilter() {
    final subjects = ['All'] + _getUniqueSubjects();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Filter by Subject'),
        content: Container(
          width: double.maxFinite,
          height: 300,
          child: ListView(
            children: subjects.map((subject) => RadioListTile<String>(
              title: Text(subject),
              subtitle: subject != 'All'
                  ? Text('${bookmarkedMaterials.where((m) => (m as MaterialModelWithSubject).subject == subject).length} materials')
                  : Text('All bookmarked materials'),
              value: subject,
              groupValue: selectedSubject,
              onChanged: (value) {
                setState(() {
                  selectedSubject = value!;
                });
                Navigator.pop(context);
              },
            )).toList(),
          ),
        ),
      ),
    );
  }

  // Show Filter Bottom Sheet with Subject Filter
  void _showFilterBottomSheet() {
    Set<String> availableTypes = bookmarkedMaterials.map((m) => m.type).toSet();
    final subjects = ['All'] + _getUniqueSubjects();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: Get.height * 0.8,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(25),
              topRight: Radius.circular(25),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Filter Bookmarks',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    GestureDetector(
                      onTap: () {
                        setModalState(() {
                          selectedSubject = 'All';
                          selectedModules.clear();
                          selectedTypes.clear();
                          selectedPriceFilter = '';
                        });
                      },
                      child: Text(
                        'Clear All',
                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Subject Filter Section (NEW)
                      Text(
                        'Subject',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: subjects.map((subject) {
                          bool isSelected = selectedSubject == subject;
                          return GestureDetector(
                            onTap: () {
                              setModalState(() {
                                selectedSubject = subject;
                              });
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected ? Color(0xFFFFBB00) : Colors.grey[100],
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected ? Color(0xFFFFBB00) : Colors.grey[300]!,
                                ),
                              ),
                              child: Text(
                                subject,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.black,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      SizedBox(height: 24),

                      // Module Filter Section
                      Text(
                        'Modules',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [1, 2, 3, 4].map((module) {
                          bool isSelected = selectedModules.contains(module);
                          return GestureDetector(
                            onTap: () {
                              setModalState(() {
                                if (isSelected) {
                                  selectedModules.remove(module);
                                } else {
                                  selectedModules.add(module);
                                }
                              });
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected ? Color(0xFFFFBB00) : Colors.grey[100],
                                borderRadius: BorderRadius.circular(25),
                                border: Border.all(
                                  color: isSelected ? Color(0xFFFFBB00) : Colors.grey[300]!,
                                ),
                              ),
                              child: Text(
                                'Module $module',
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.black,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      SizedBox(height: 24),

                      // Type Filter Section
                      Text(
                        'Material Type',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: availableTypes.map((type) {
                          bool isSelected = selectedTypes.contains(type);
                          return GestureDetector(
                            onTap: () {
                              setModalState(() {
                                if (isSelected) {
                                  selectedTypes.remove(type);
                                } else {
                                  selectedTypes.add(type);
                                }
                              });
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected ? Color(0xFFFFBB00) : Colors.grey[100],
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected ? Color(0xFFFFBB00) : Colors.grey[300]!,
                                ),
                              ),
                              child: Text(
                                type,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.black,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      SizedBox(height: 24),

                      // Price Filter Section
                      Text(
                        'Price',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setModalState(() {
                                  selectedPriceFilter = selectedPriceFilter == 'free' ? '' : 'free';
                                });
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: selectedPriceFilter == 'free' ? Color(0xFFFFBB00) : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: selectedPriceFilter == 'free' ? Color(0xFFFFBB00) : Colors.grey[300]!,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    'Free',
                                    style: TextStyle(
                                      color: selectedPriceFilter == 'free' ? Colors.white : Colors.black,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setModalState(() {
                                  selectedPriceFilter = selectedPriceFilter == 'paid' ? '' : 'paid';
                                });
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: selectedPriceFilter == 'paid' ? Color(0xFFFFBB00) : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: selectedPriceFilter == 'paid' ? Color(0xFFFFBB00) : Colors.grey[300]!,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    'Paid',
                                    style: TextStyle(
                                      color: selectedPriceFilter == 'paid' ? Colors.white : Colors.black,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 40),
                    ],
                  ),
                ),
              ),

              // Apply Button
              Container(
                padding: EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {});
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFFFBB00),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Apply Filters (${_getFilteredMaterials().length} results)',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Show Clear All Dialog
  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clear All Bookmarks'),
        backgroundColor: Colors.white,
        content: Text('Are you sure you want to remove all bookmarks? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Future.delayed(Duration.zero, () async {
                await bookmarkController.clearAllBookmarks();
                await fetchBookmarkedMaterials();
              });
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Clear All'),
          ),
        ],
      ),
    );
  }
}

// Extended MaterialModel to include subject information
class MaterialModelWithSubject extends MaterialModel {
  final String subject;

  MaterialModelWithSubject({
    required super.id,
    required super.noteName,
    required super.thumbnail,
    required super.source,
    required super.price,
    required super.type,
    required super.color,
    required super.module,
    required this.subject,
  });

  factory MaterialModelWithSubject.fromMaterial(MaterialModel material, String subject) {
    return MaterialModelWithSubject(
      id: material.id,
      noteName: material.noteName,
      thumbnail: material.thumbnail,
      source: material.source,
      price: material.price,
      type: material.type,
      color: material.color,
      module: material.module,
      subject: subject,
    );
  }
}
