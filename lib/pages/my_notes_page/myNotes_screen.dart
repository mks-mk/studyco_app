import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../Utilities/variables/app_colors.dart';
import '../../controllers/downloads/save_controller.dart';
import '../../controllers/myMaterials/my_materials_controller.dart';
import '../../controllers/recentOpenings/recent_openings_controller.dart';
import '../../controllers/subjectController/getMaterialsWithSubjects.dart';
import '../../controllers/bookmark/bookmarkController.dart';
import '../../models/material_model.dart';
import '../downlod/downloads_page.dart';
import '../pdf_viewer/pdf_view_page.dart';

class MyNotesScreen extends StatefulWidget {
  const MyNotesScreen({super.key});

  @override
  State<MyNotesScreen> createState() => _MyNotesScreenState();
}

class _MyNotesScreenState extends State<MyNotesScreen> {
  // Filter state
  String selectedSubject = 'All';
  bool showBookmarkedOnly = false;
  bool isGridView = true;

  // Controllers
  late MyMaterialsController myMaterialsController;
  late MaterialsWithSubjectsController materialsController;
  late BookmarkController bookmarkController;
  late RecentMaterialsController recentController;

  // Purchased materials with full details
  final RxList<MaterialModel> purchasedMaterials = <MaterialModel>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void initState() {
    super.initState();

    // Initialize controllers
    myMaterialsController = Get.find<MyMaterialsController>();
    materialsController = Get.find<MaterialsWithSubjectsController>();
    bookmarkController = Get.find<BookmarkController>();
    recentController = Get.put(RecentMaterialsController());

    // Fetch purchased materials
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchPurchasedMaterials();
    });
  }

  // Fetch full material details for purchased items
  Future<void> fetchPurchasedMaterials() async {
    try {
      isLoading.value = true;
      purchasedMaterials.clear();

      // Get all purchased subjects and their material IDs
      final purchasedSubjects = myMaterialsController.getPurchasedSubjects();

      for (String subject in purchasedSubjects) {
        // Get purchased material IDs for this subject
        final materialIds = myMaterialsController.getMaterialsBySubject(subject);

        if (materialIds.isNotEmpty) {
          // Refresh materials data for this subject
          await materialsController.refreshMaterials(subject: subject);

          // Filter materials by purchased IDs and add subject info
          final subjectMaterials = materialsController.materials
              .where((material) => materialIds.contains(material.id))
              .map((material) => PurchasedMaterialWithSubject.fromMaterial(material, subject))
              .toList();

          purchasedMaterials.addAll(subjectMaterials);
        }
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load purchased materials: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final GlobalKey<LiquidPullToRefreshState> refreshIndicatorKey =
    GlobalKey<LiquidPullToRefreshState>();

    return Container(
      decoration: const BoxDecoration(
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
          await myMaterialsController.refreshMyMaterials();
          await fetchPurchasedMaterials();
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
            leading: null,
            title: const Text(
              'My Materials',
              style: TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              // --- NEW: Filter button that opens the bottom sheet ---
              IconButton(
                icon: const Icon(Icons.filter_list, color: Colors.black),
                onPressed: _showFilterSheet,
              ),
              // View toggle
              IconButton(
                icon: Icon(
                  isGridView ? Icons.view_list : Icons.grid_view,
                  color: Colors.black,
                ),
                onPressed: () => setState(() => isGridView = !isGridView),
              ),
            ],
          ),
          body: SafeArea(
            child: Obx(() => Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- REMOVED: Filter Section is no longer here ---

                  if (_hasActiveFilters()) _buildActiveFilters(),

                  const SizedBox(height: 12),

                  Expanded(
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
            )),
          ),
        ),
      ),
    );
  }

  void _showFilterSheet() {
    Get.bottomSheet(
      StatefulBuilder(
        builder: (context, setSheetState) {
          final subjects = ['All'] + _getUniqueSubjects();

          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Wrap(
                runSpacing: 16,
                children: [
                  const Text('Filter Materials', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Divider(height: 20),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: subjects.map((subject) {
                      return ChoiceChip(
                        label: Text(subject),
                        selected: selectedSubject == subject,
                        onSelected: (isSelected) {
                          setState(() => selectedSubject = subject);
                          setSheetState(() {});
                        },
                        selectedColor: const Color(0xFFFFBB00),
                        labelStyle: TextStyle(
                            color: selectedSubject == subject ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.w600),
                        backgroundColor: Colors.grey[100],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: selectedSubject == subject ? Colors.transparent : Colors.grey[300]!,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Show Bookmarked Only', style: TextStyle(fontWeight: FontWeight.w600)),
                    value: showBookmarkedOnly,
                    onChanged: (newValue) {
                      setState(() => showBookmarkedOnly = newValue);
                      setSheetState(() {});
                    },
                    activeThumbColor: const Color(0xFFFFBB00),
                    secondary: const Icon(Icons.bookmark_border_rounded),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      isScrollControlled: true,
    );
  }

  // --- MOVED: The old filter section is now inside _showFilterSheet ---

  Widget _buildActiveFilters() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      height: 40,
      width: Get.width,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          if (selectedSubject != 'All')
            Container(
              margin: const EdgeInsets.only(right: 8),
              child: Chip(
                label: Text(
                  selectedSubject,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
                backgroundColor: const Color(0xFFFFBB00),
                deleteIcon: const Icon(Icons.close, color: Colors.white, size: 18),
                onDeleted: () => setState(() => selectedSubject = 'All'),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            ),
          if (showBookmarkedOnly)
            Container(
              margin: const EdgeInsets.only(right: 8),
              child: Chip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.bookmark, color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'Bookmarked (${_getBookmarkedCount()})',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                backgroundColor: const Color(0xFFFFBB00),
                deleteIcon: const Icon(Icons.close, color: Colors.white, size: 18),
                onDeleted: () => setState(() => showBookmarkedOnly = false),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            ),
          if (_hasActiveFilters())
            GestureDetector(
              onTap: () {
                setState(() {
                  selectedSubject = 'All';
                  showBookmarkedOnly = false;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Center(
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

  Widget _buildGridView() {
    final filteredMaterials = _getFilteredMaterials();
    final downloadManager = Get.find<SecureDownloadManager>();

    return GridView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.7,
      ),
      itemCount: filteredMaterials.length,
      itemBuilder: (context, index) {
        final material = filteredMaterials[index] as PurchasedMaterialWithSubject;

        return GestureDetector(
          onTap: () {
            if (material.type == "pdf" || material.type == "Pdf") {
              recentController.addRecentMaterial(
                materialId: material.id,
                title: material.noteName,
                subject: material.subject,
                type: material.type,
                thumbnail: material.thumbnail,
                source: material.source,
                price: material.price.toDouble(),
              );

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
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      child: CachedNetworkImage(
                        imageUrl: material.thumbnail,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                material.subject,
                                style: TextStyle(
                                  color: material.color,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                if (material.type.toLowerCase() != 'link')
                                  Obx(() {
                                    final isDownloaded = downloadManager.isMaterialDownloaded(material.id);
                                    final activeDownload = downloadManager.activeDownloads
                                        .firstWhereOrNull((d) => d.materialId == material.id);

                                    return GestureDetector(
                                      onTap: () async {
                                        if (isDownloaded) {
                                          Get.to(() => const OfflineMaterialsPage());
                                        } else if (activeDownload == null) {
                                          await downloadManager.downloadMaterial(
                                            materialId: material.id,
                                            title: material.noteName,
                                            subject: material.subject,
                                            downloadUrl: material.source,
                                            materialType: material.type,
                                            thumbnailUrl: material.thumbnail,
                                          );
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        margin: const EdgeInsets.only(right: 8),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(100),
                                        ),
                                        child: activeDownload != null
                                            ? SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            value: activeDownload.progress,
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(material.color),
                                          ),
                                        )
                                            : Icon(
                                          isDownloaded ? Icons.download_done : Icons.download,
                                          size: 16,
                                          color: isDownloaded ? Colors.green : material.color,
                                        ),
                                      ),
                                    );
                                  }),
                                GestureDetector(
                                  onTap: () async {
                                    await bookmarkController.toggleBookmark(
                                      subject: material.subject,
                                      id: material.id,
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(100),
                                    ),
                                    child: Obx(() => Icon(
                                      bookmarkController.isBookmarked(
                                        subject: material.subject,
                                        id: material.id,
                                      ) ? Icons.bookmark : Icons.bookmark_border,
                                      color: bookmarkController.isBookmarked(
                                        subject: material.subject,
                                        id: material.id,
                                      ) ? const Color(0xFFFFBB00) : Colors.grey,
                                      size: 20,
                                    )),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: Text(
                            material.noteName,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
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

  Widget _buildListView() {
    final filteredMaterials = _getFilteredMaterials();

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: filteredMaterials.length,
      itemBuilder: (context, index) {
        final material = filteredMaterials[index] as PurchasedMaterialWithSubject;
        final isBookmarked = bookmarkController.isBookmarked(
          subject: material.subject,
          id: material.id,
        );

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: GestureDetector(
            onTap: () {
              if (material.type == "pdf" || material.type == "Pdf") {
                recentController.addRecentMaterial(
                  materialId: material.id,
                  title: material.noteName,
                  subject: material.subject,
                  type: material.type,
                  thumbnail: material.thumbnail,
                  source: material.source,
                  price: material.price.toDouble(),
                );

                Get.to(() => PremiumPdfViewPage(
                  url: material.source,
                  title: material.noteName,
                ));
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
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
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: material.color,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                material.subject,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                        const SizedBox(height: 8),
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
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.description, size: 16, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Text(
                                  material.type,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.check_circle, size: 14, color: Colors.white),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Purchased ₹${material.price}',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isBookmarked ? const Color(0xFFFFBB00).withValues(alpha: 0.1) : Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                                color: isBookmarked ? const Color(0xFFFFBB00) : Colors.grey,
                                size: 20,
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
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_bag_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _hasActiveFilters() ? 'No materials found' : 'No purchased materials yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _hasActiveFilters()
                ? 'Try adjusting your filters'
                : 'Purchase some materials to see them here',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          if (_hasActiveFilters()) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  selectedSubject = 'All';
                  showBookmarkedOnly = false;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFBB00),
              ),
              child: const Text('Show All Materials', style: TextStyle(color: Colors.white)),
            ),
          ],
        ],
      ),
    );
  }

  List<String> _getUniqueSubjects() {
    return purchasedMaterials
        .map((material) => (material as PurchasedMaterialWithSubject).subject)
        .toSet()
        .toList();
  }

  List<MaterialModel> _getFilteredMaterials() {
    return purchasedMaterials.where((material) {
      final materialWithSubject = material as PurchasedMaterialWithSubject;

      bool matchesSubject = selectedSubject == 'All' ||
          materialWithSubject.subject == selectedSubject;

      bool matchesBookmark = !showBookmarkedOnly ||
          bookmarkController.isBookmarked(
            subject: materialWithSubject.subject,
            id: material.id,
          );

      return matchesSubject && matchesBookmark;
    }).toList();
  }

  int _getBookmarkedCount() {
    return _getFilteredMaterials()
        .where((material) => bookmarkController.isBookmarked(
      subject: (material as PurchasedMaterialWithSubject).subject,
      id: material.id,
    ))
        .length;
  }

  bool _hasActiveFilters() {
    return selectedSubject != 'All' || showBookmarkedOnly;
  }
}

class PurchasedMaterialWithSubject extends MaterialModel {
  final String subject;

  PurchasedMaterialWithSubject({
    required super.id,
    required super.noteName,
    required super.thumbnail,
    required super.source,
    required super.price,
    required super.type,
    required super.color,
    required super.module,
    required this.subject, required super.description,
  });

  factory PurchasedMaterialWithSubject.fromMaterial(MaterialModel material, String subject) {
    return PurchasedMaterialWithSubject(
      id: material.id,
      noteName: material.noteName,
      thumbnail: material.thumbnail,
      source: material.source,
      price: material.price,
      type: material.type,
      color: material.color,
      module: material.module,
      subject: subject,
      description: material.description,
    );
  }
}