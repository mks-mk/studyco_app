import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:no_screenshot/no_screenshot.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../Utilities/variables/app_colors.dart';
import '../../bindings/bookmark_binding.dart';
import '../../controllers/downloads/save_controller.dart';
import '../../controllers/recentOpenings/recent_openings_controller.dart';
import '../../controllers/subjectController/getMaterialsWithSubjects.dart';
import '../../controllers/myMaterials/my_materials_controller.dart';
import '../../models/material_model.dart';
import '../../controllers/cart/cart_controller.dart';
import '../carts/cart_page.dart';
import '../downlod/downloads_page.dart';
import '../pdf_viewer/pdf_view_page.dart';
import 'my_bookmarks_page.dart';

class MaterialsPage extends StatefulWidget {
  final String subject;
  const MaterialsPage({super.key, required this.subject});

  @override
  State<MaterialsPage> createState() => _MaterialsPageState();
}

class _MaterialsPageState extends State<MaterialsPage> {
  Future<void> secureScreen() async {
    await NoScreenshot.instance.screenshotOn();
  }

  // Filter and search state
  String searchQuery = '';
  List<int> selectedModules = [];
  List<String> selectedTypes = [];
  String selectedPriceFilter = '';
  bool showBookmarkedOnly = false;

  // View toggle state
  bool isGridView = true; // true for grid, false for list

  // Controllers
  late TextEditingController searchController;
  late FocusNode searchFocusNode;
  late MaterialsWithSubjectsController materialsController;

  final GlobalKey<LiquidPullToRefreshState> refreshIndicatorKey =
      GlobalKey<LiquidPullToRefreshState>();

  @override
  void initState() {
    super.initState();
    secureScreen();

    // Initialize controllers
    searchController = TextEditingController();
    searchFocusNode = FocusNode();

    // Initialize materials controller with proper singleton pattern
    materialsController = Get.put(MaterialsWithSubjectsController(), tag: widget.subject);

    // Initialize download and cart managers
    Get.put(SecureDownloadManager());
    Get.find<MyMaterialsController>();

    // Use addPostFrameCallback to ensure proper initialization
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Only fetch if data is empty
      if (materialsController.materials.isEmpty) {
        materialsController.fetchData(subject: widget.subject);
      }
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

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
          materialsController.refreshMaterials(subject: widget.subject);
          await Get.find<MyMaterialsController>().fetchMyMaterials();
        },
        backgroundColor: AppColor.backgroundColor,
        color: Colors.orange,
        springAnimationDurationInMilliseconds: 800,
        showChildOpacityTransition: false,
        height: 80,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          resizeToAvoidBottomInset: false,
          floatingActionButton: Obx(() {
            final cartCount = Get.put(CartController()).cartItemCount;
            if (cartCount > 0) {
              return FloatingActionButton(
                onPressed: () => Get.to(() => CartPage()),
                backgroundColor: Color(0xFFFFBB00),
                child: Icon(Icons.shopping_cart, color: Colors.white),
              );
            }
            return SizedBox.shrink();
          }),
          body: SafeArea(
            child: Obx(
                  () => Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Section
                    SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Text(
                                widget.subject.toUpperCase(),
                                maxLines: 2,
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: Get.height * 0.05,
                                  overflow: TextOverflow.ellipsis,
                                  fontFamily: GoogleFonts.leagueSpartan(
                                    fontWeight: FontWeight.bold,
                                  ).fontFamily,
                                ),
                              ),
                            ),
                            // Bookmarked toggle button
                            GestureDetector(
                              onTap: () {
                                Get.to(() => MyBookmarks(
                                  subject: widget.subject,
                                ), binding: MyBookmarksBinding());
                              },
                              child: Icon(
                                Icons.collections_bookmark_rounded,
                                color: Colors.black,
                                size: 28,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Search and Filter Section
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            height: 40,
                            width: 40,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.white,
                            ),
                            child: Icon(Icons.search_rounded),
                          ),
                          SizedBox(width: 6),
                          Container(
                            height: 40,
                            width: Get.width * 0.5,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.white,
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
                              enableInteractiveSelection: true,
                              autocorrect: false,
                              enableSuggestions: false,
                              cursorOpacityAnimates: true,
                              textAlignVertical: TextAlignVertical.center,
                              cursorColor: AppColor.primary_1,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                              decoration: InputDecoration(
                                hintText: "Search Materials...",
                                hintStyle: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey,
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: AppColor.primary_1,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 4),
                          // Filter Button
                          GestureDetector(
                            onTap: () {
                              _showFilterBottomSheet();
                            },
                            child: Container(
                              height: 40,
                              width: 40,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: _hasActiveFilters() ? Color(0xFFFFBB00) : Colors.white,
                              ),
                              child: Icon(
                                Icons.filter_list,
                                color: _hasActiveFilters() ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                          SizedBox(width: 4),
                          // Dashboard toggle button
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                isGridView = !isGridView;
                              });
                            },
                            child: Container(
                              height: 40,
                              width: 40,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.white,
                                border: Border.all(
                                  color: isGridView ? Colors.grey.shade300 : Color(0xFFFFBB00),
                                  width: isGridView ? 1 : 2,
                                ),
                              ),
                              child: Icon(
                                isGridView ? Icons.view_list : Icons.grid_view,
                                color: isGridView ? Colors.black : Color(0xFFFFBB00),
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Filter Chips
                    if (_hasActiveFilters() || showBookmarkedOnly) _buildActiveFilterChips(),

                    // Materials Grid/List with skeleton control
                    Expanded(
                      child: Skeletonizer(
                        enabled: materialsController.isLoading.value,
                        child: materialsController.isLoading.value
                            ? _buildSkeletonView()
                            : (isGridView ? _buildGridView() : _buildListView()),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Build skeleton view that matches your layout
  Widget _buildSkeletonView() {
    return isGridView ? _buildSkeletonGrid() : _buildSkeletonList();
  }

  // Build skeleton grid
  Widget _buildSkeletonGrid() {
    return GridView.builder(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
      shrinkWrap: true,
      physics: AlwaysScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 0,
        mainAxisSpacing: 0,
        mainAxisExtent: 260,
      ),
      itemCount: 6, // Show 6 skeleton items
      itemBuilder: (context, index) {
        return SizedBox(
          width: 190,
          height: 200,
          child: Card(
            color: Colors.grey[100],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    width: double.infinity,
                    margin: EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      Container(
                        width: 120,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(7),
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            width: 40,
                            height: 20,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(10),
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

  // Build skeleton list
  Widget _buildSkeletonList() {
    return ListView.builder(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
      physics: AlwaysScrollableScrollPhysics(),
      itemCount: 5, // Show 5 skeleton items
      itemBuilder: (context, index) {
        return Container(
          margin: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: EdgeInsets.all(10),
            child: Row(
              children: [
                // Thumbnail skeleton
                Container(
                  width: 80,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                SizedBox(width: 16),
                // Content skeleton
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 150,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            width: 60,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          SizedBox(width: 8),
                          Container(
                            width: 80,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            width: 60,
                            height: 30,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          Container(
                            width: 40,
                            height: 30,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(15),
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

  // UPDATED: Build Grid View with purchase check and cart integration
  Widget _buildGridView() {
    final downloadManager = Get.find<SecureDownloadManager>();
    final myMaterialsController = Get.find<MyMaterialsController>();
    final cartController = Get.put(CartController());
    final recentController = Get.put(RecentMaterialsController());

    return GridView.builder(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
      shrinkWrap: true,
      physics: AlwaysScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 0,
        mainAxisSpacing: 0,
        mainAxisExtent: 260,
      ),
      itemCount: _getFilteredMaterials().length,
      itemBuilder: (context, index) {
        final filteredMaterials = _getFilteredMaterials();
        final material = filteredMaterials[index];

        return Obx(() {
          // ADDED: Check if material is purchased
          final isPurchased = myMaterialsController.isMaterialPurchased(widget.subject, material.id);

          return GestureDetector(
            onTap: () {
              if (material.price > 0 && !isPurchased) {
                cartController.addToCart(
                  materialId: material.id,
                  title: material.noteName,
                  subject: widget.subject,
                  price: material.price.toDouble(),
                  thumbnail: material.thumbnail,
                  type: material.type,
                );
              } else {
                // For free materials OR purchased materials, open PDF
                if (material.type == "pdf" || material.type == "Pdf") {
                  recentController.addRecentMaterial(
                    materialId: material.id,
                    title: material.noteName,
                    subject: widget.subject,
                    type: material.type,
                    thumbnail: material.thumbnail,
                    source: material.source,
                    price: material.price.toDouble(),
                  );
                  Get.to(
                        () => PremiumPdfViewPage(
                      url: material.source,
                      title: material.noteName,
                          materialId: material.id,
                          subject: widget.subject,
                    ),
                  );
                }
              }
            },
            child: SizedBox(
              width: 190,
              height: 200,
              child: Card(
                color: material.color,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        margin: EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: CachedNetworkImage(
                            imageUrl: material.thumbnail,
                            fit: BoxFit.fill,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                        top: 2.0,
                        left: 8,
                        right: 8,
                      ),
                      child: Text(
                        material.noteName,
                        maxLines: 2,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: material.color.computeLuminance() > 0.5
                              ? Colors.black
                              : Colors.white,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: material.price != 0
                          ? MainAxisAlignment.spaceBetween
                          : MainAxisAlignment.end,
                      children: [
                        // UPDATED: Price container or purchased badge
                        Flexible(
                          child: material.price != 0
                              ? Container(
                            decoration: BoxDecoration(
                              color: isPurchased ? Colors.green : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            margin: EdgeInsets.only(
                              left: 8,
                              right: 8,
                              bottom: 8,
                              top: 4,
                            ),
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: isPurchased
                                    ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.shopping_bag_rounded,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ],
                                )
                                    : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      " ₹${material.price} ",
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                              : SizedBox.shrink(),
                        ),

                        // Action buttons row
                        Row(
                          children: [
                            // UPDATED: Download button (for free materials OR purchased materials, not links)
                            if ((material.price == 0 || isPurchased) && material.type.toLowerCase() != 'link')
                              Obx(() {
                                final isDownloaded = downloadManager.isMaterialDownloaded(material.id);
                                final activeDownload = downloadManager.activeDownloads
                                    .firstWhereOrNull((d) => d.materialId == material.id);

                                return GestureDetector(
                                  onTap: () async {
                                    if (isDownloaded) {
                                      // Navigate to offline materials
                                      Get.to(() => OfflineMaterialsPage());
                                    } else if (activeDownload == null) {
                                      // Start download
                                      await downloadManager.downloadMaterial(
                                        materialId: material.id,
                                        title: material.noteName,
                                        subject: widget.subject,
                                        downloadUrl: material.source,
                                        materialType: material.type,
                                        thumbnailUrl: material.thumbnail,
                                      );
                                    }
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(100),
                                    ),
                                    margin: EdgeInsets.only(
                                      left: 4,
                                      right: 4,
                                      bottom: 8,
                                    ),
                                    child: Center(
                                      child: Padding(
                                        padding: const EdgeInsets.all(4.0),
                                        child: activeDownload != null
                                            ? SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            value: activeDownload.progress,
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                                          ),
                                        )
                                            : Icon(
                                          isDownloaded ? Icons.download_done : Icons.download,
                                          size: 20,
                                          color: isDownloaded ? Colors.green : Colors.black,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),

                            // Bookmark button
                            GestureDetector(
                              onTap: () async {
                                await materialsController.toggleBookmark(
                                  subject: widget.subject,
                                  id: material.id,
                                );
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                margin: EdgeInsets.only(
                                  left: 4,
                                  right: 8,
                                  bottom: 8,
                                ),
                                child: Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(4.0),
                                    child: Obx(() => Icon(
                                      materialsController.isBookmarked(
                                        subject: widget.subject,
                                        id: material.id,
                                      )
                                          ? Icons.bookmark_added_rounded
                                          : Icons.bookmark_add_outlined,
                                      size: 20,
                                    )),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        });
      },
    );
  }

  // UPDATED: Build List View with purchase check and cart integration
  Widget _buildListView() {
    final downloadManager = Get.find<SecureDownloadManager>();
    final myMaterialsController = Get.find<MyMaterialsController>(); // ADD THIS
    final cartController = Get.put(CartController());
    final recentController = Get.put(RecentMaterialsController());

    return ListView.builder(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
      physics: AlwaysScrollableScrollPhysics(),
      itemCount: _getFilteredMaterials().length,
      itemBuilder: (context, index) {
        final filteredMaterials = _getFilteredMaterials();
        final material = filteredMaterials[index];

        return Obx(() {
          // ADDED: Check if material is purchased
          final isPurchased = myMaterialsController.isMaterialPurchased(widget.subject, material.id);

          return GestureDetector(
            onTap: () {
              // UPDATED: Handle different material states
              if (material.price > 0 && !isPurchased) {
                // For unpurchased paid materials, add to cart
                cartController.addToCart(
                  materialId: material.id,
                  title: material.noteName,
                  subject: widget.subject,
                  price: material.price.toDouble(),
                  thumbnail: material.thumbnail,
                  type: material.type,
                );
              } else {
                // For free materials OR purchased materials, open PDF
                if (material.type == "pdf" || material.type == "Pdf") {
                  recentController.addRecentMaterial(
                    materialId: material.id,
                    title: material.noteName,
                    subject: widget.subject,
                    type: material.type,
                    thumbnail: material.thumbnail,
                    source: material.source,
                    price: material.price.toDouble(),
                  );
                  Get.to(
                        () => PremiumPdfViewPage(
                      url: material.source,
                      title: material.noteName,
                    ),
                  );
                }
              }
            },
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: material.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: material.color.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Padding(
                padding: EdgeInsets.all(10),
                child: Row(
                  children: [
                    // Thumbnail
                    Container(
                      width: 80,
                      height: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: material.color,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: material.thumbnail,
                          fit: BoxFit.fill,
                          placeholder: (context, url) => Container(
                            color: material.color.withValues(alpha: 0.3),
                            child: Icon(
                              Icons.image,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: material.color.withValues(alpha: 0.3),
                            child: Icon(
                              Icons.error,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(width: 16),

                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title
                          Text(
                            material.noteName,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: material.color,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),

                          SizedBox(height: 4),

                          // Type and Module
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: material.color.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  material.type,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: material.color,
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
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: 8),

                          // Price and Actions
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // UPDATED: Price or purchased badge
                              material.price != 0
                                  ? Container(
                                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isPurchased ? Colors.green : material.color,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: isPurchased
                                    ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'PURCHASED',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                )
                                    : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '₹${material.price}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                                  : Container(),

                              // Action buttons
                              Row(
                                children: [
                                  // UPDATED: Download button (for free materials OR purchased materials, not links)
                                  if ((material.price == 0 || isPurchased) && material.type.toLowerCase() != 'link')
                                    Obx(() {
                                      final isDownloaded = downloadManager.isMaterialDownloaded(material.id);
                                      final activeDownload = downloadManager.activeDownloads
                                          .firstWhereOrNull((d) => d.materialId == material.id);

                                      return GestureDetector(
                                        onTap: () async {
                                          if (isDownloaded) {
                                            // Navigate to offline materials
                                            Get.to(() => OfflineMaterialsPage());
                                          } else if (activeDownload == null) {
                                            // Start download
                                            await downloadManager.downloadMaterial(
                                              materialId: material.id,
                                              title: material.noteName,
                                              subject: widget.subject,
                                              downloadUrl: material.source,
                                              materialType: material.type,
                                              thumbnailUrl: material.thumbnail,
                                            );
                                          }
                                        },
                                        child: Container(
                                          padding: EdgeInsets.all(8),
                                          margin: EdgeInsets.only(right: 8),
                                          decoration: BoxDecoration(
                                            color: material.color.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: material.color.withValues(alpha: 0.3),
                                            ),
                                          ),
                                          child: activeDownload != null
                                              ? SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              value: activeDownload.progress,
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(material.color),
                                            ),
                                          )
                                              : Icon(
                                            isDownloaded ? Icons.download_done : Icons.download,
                                            size: 20,
                                            color: isDownloaded ? Colors.green : material.color,
                                          ),
                                        ),
                                      );
                                    }),

                                  // Bookmark button
                                  GestureDetector(
                                    onTap: () async {
                                      await materialsController.toggleBookmark(
                                        subject: widget.subject,
                                        id: material.id,
                                      );
                                    },
                                    child: Container(
                                      padding: EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: material.color.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: material.color.withValues(alpha: 0.3),
                                        ),
                                      ),
                                      child: Obx(() => Icon(
                                        materialsController.isBookmarked(
                                          subject: widget.subject,
                                          id: material.id,
                                        )
                                            ? Icons.bookmark_added_rounded
                                            : Icons.bookmark_add_outlined,
                                        size: 20,
                                        color: material.color,
                                      )),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        });
      },
    );
  }

  // Get filtered materials
  List<MaterialModel> _getFilteredMaterials() {
    return materialsController.getFilteredMaterials(
      searchQuery: searchQuery,
      modules: selectedModules.isNotEmpty ? selectedModules : null,
      types: selectedTypes.isNotEmpty ? selectedTypes : null,
      priceFilter: selectedPriceFilter.isNotEmpty ? selectedPriceFilter : null,
      showBookmarkedOnly: showBookmarkedOnly,
      subject: widget.subject,
    );
  }

  // Build Active Filter Chips
  Widget _buildActiveFilterChips() {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // Bookmarked filter chip
          if (showBookmarkedOnly)
            Container(
              margin: EdgeInsets.only(right: 8),
              child: Chip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bookmark, color: Colors.white, size: 16),
                    SizedBox(width: 4),
                    Text(
                      'Bookmarked (${materialsController.getBookmarkCount(subject: widget.subject)})',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                backgroundColor: Color(0xFFFFBB00),
                deleteIcon: Icon(Icons.close, color: Colors.white, size: 18),
                onDeleted: () {
                  setState(() {
                    showBookmarkedOnly = false;
                  });
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),

          // Module filter chips
          for (int module in selectedModules)
            Container(
              margin: EdgeInsets.only(right: 8),
              child: Chip(
                label: Text(
                  'Module $module',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                backgroundColor: Color(0xFFFFBB00),
                deleteIcon: Icon(Icons.close, color: Colors.white, size: 18),
                onDeleted: () {
                  setState(() {
                    selectedModules.remove(module);
                  });
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),

          // Type filter chips
          for (String type in selectedTypes)
            Container(
              margin: EdgeInsets.only(right: 8),
              child: Chip(
                label: Text(
                  type,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                backgroundColor: Color(0xFFFFBB00),
                deleteIcon: Icon(Icons.close, color: Colors.white, size: 18),
                onDeleted: () {
                  setState(() {
                    selectedTypes.remove(type);
                  });
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),

          // Price filter chip
          if (selectedPriceFilter.isNotEmpty)
            Container(
              margin: EdgeInsets.only(right: 8),
              child: Chip(
                label: Text(
                  selectedPriceFilter == 'free' ? 'Free' : 'Paid',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                backgroundColor: Color(0xFFFFBB00),
                deleteIcon: Icon(Icons.close, color: Colors.white, size: 18),
                onDeleted: () {
                  setState(() {
                    selectedPriceFilter = '';
                  });
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),

          // Clear all button
          if (_hasActiveFilters() || showBookmarkedOnly)
            GestureDetector(
              onTap: () {
                setState(() {
                  selectedModules.clear();
                  selectedTypes.clear();
                  selectedPriceFilter = '';
                  showBookmarkedOnly = false;
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
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  bool _hasActiveFilters() {
    return selectedModules.isNotEmpty ||
        selectedTypes.isNotEmpty ||
        selectedPriceFilter.isNotEmpty;
  }

  // Show Filter Bottom Sheet
  void _showFilterBottomSheet() {
    Set<String> availableTypes = materialsController.materials.map((m) => m.type).toSet();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
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
                      'Filter Materials',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            setModalState(() {
                              selectedModules.clear();
                              selectedTypes.clear();
                              selectedPriceFilter = '';
                              showBookmarkedOnly = false;
                            });
                          },
                          child: Text(
                            'Clear All',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
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
                      // Bookmarked Filter Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Show Only',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                          Text(
                            '${materialsController.getBookmarkCount(subject: widget.subject)} bookmarked',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      GestureDetector(
                        onTap: () {
                          setModalState(() {
                            showBookmarkedOnly = !showBookmarkedOnly;
                          });
                        },
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                          decoration: BoxDecoration(
                            color: showBookmarkedOnly ? Color(0xFFFFBB00) : Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: showBookmarkedOnly ? Color(0xFFFFBB00) : Colors.grey[300]!,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.bookmark,
                                color: showBookmarkedOnly ? Colors.white : Colors.grey[600],
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Bookmarked Materials Only',
                                style: TextStyle(
                                  color: showBookmarkedOnly ? Colors.white : Colors.black,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Spacer(),
                              if (showBookmarkedOnly)
                                Icon(Icons.check, color: Colors.white),
                            ],
                          ),
                        ),
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
                      setState(() {
                        // Apply filters
                      });
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
}
