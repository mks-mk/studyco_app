import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:studyco_app/pages/forYouExpanded/for_you_full.dart';
import '../../Utilities/components/widget_components/bottom_nav_bar.dart';
import '../../Utilities/components/widget_components/for_you_widget.dart';
import '../../Utilities/components/widget_components/subject_card.dart';
import '../../Utilities/variables/app_colors.dart';
import '../../controllers/navController.dart';
import '../../controllers/recentOpenings/recent_openings_controller.dart';
import '../../controllers/scrollController.dart';
import '../../controllers/subjectController/fetch_subjects.dart';
import '../../controllers/subjectController/for_you_controller.dart';
import '../alerts_page/Alerts_Screen.dart';
import '../my_notes_page/myNotes_screen.dart';
import '../pdf_viewer/pdf_view_page.dart';
import '../profile_page/profile_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final SubjectController subjectController = Get.put(SubjectController());
    final ForYouController forYouController = Get.put(ForYouController());
    final ScrollerController scrollControl = Get.find<ScrollerController>();
    final NavbarController navbarController = Get.put(NavbarController());

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: AppColor.backgroundColor,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: AppColor.backgroundColor,
      ),
    );

    List pages = <Widget>[
      BaseHome(
        scrollControl: scrollControl,
        subjectController: subjectController,
        forYouController: forYouController,
      ),
      MyNotesScreen(),
      AlertsScreen(),
      ProfileScreen(scrollControl: scrollControl),
    ];

    return Obx(
      () => Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topLeft,
            radius: 1.6,
            colors: [Color(0xFFDDCFAF), Color(0xFFFFFFFF)],
            stops: [0.05, 0.80],
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            fit: StackFit.expand,
            children: [
              pages[navbarController.selectedIndex.value],
              Positioned(
                bottom: 8,
                left: 0,
                right: 0,
                child: bottomNavigationBar(
                  context,
                  Get.put(NavbarController()),
                  scrollControl,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BaseHome extends StatefulWidget {
  const BaseHome({
    super.key,
    required this.scrollControl,
    required this.subjectController,
    required this.forYouController,
  });

  final ScrollerController scrollControl;
  final SubjectController subjectController;
  final ForYouController forYouController;

  @override
  State<BaseHome> createState() => _BaseHomeState();
}

class _BaseHomeState extends State<BaseHome> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.subjectController.subjects.isEmpty) {
        widget.subjectController.fetchSubjects();
      }
      if (widget.forYouController.forYouItems.isEmpty) {
        widget.forYouController.fetchForYou();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final GlobalKey<LiquidPullToRefreshState> refreshIndicatorKey =
        GlobalKey<LiquidPullToRefreshState>();
    RecentMaterialsController recentController =
        Get.find<RecentMaterialsController>();

    return LiquidPullToRefresh(
      key: refreshIndicatorKey,
      onRefresh: () async {
        widget.subjectController.refreshSubjects();
        await widget.forYouController.refreshForYou();
      },
      backgroundColor: AppColor.backgroundColor,
      color: Colors.orange,
      springAnimationDurationInMilliseconds: 800,
      showChildOpacityTransition: false,
      height: 80,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14.0),
            child: SingleChildScrollView(
              controller: widget.scrollControl.scrollController,
              child: Obx(
                () => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "studyco.",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: Get.height * 0.07,
                        fontFamily:
                            GoogleFonts.leagueSpartan(
                              fontWeight: FontWeight.bold,
                            ).fontFamily,
                      ),
                    ),

                    // FIXED: Proper skeleton control for subjects
                    Skeletonizer(
                      enabled: widget.subjectController.isLoading.value,
                      child:
                          widget.subjectController.isLoading.value
                              ? _buildSubjectsSkeletonGrid()
                              : _buildSubjectsGrid(),
                    ),
                    recentController.recentCount == 0
                        ? SizedBox.shrink()
                        : SizedBox(height: 8),
                    recentController.recentCount == 0
                        ? SizedBox.shrink()
                        : Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              " Recent openings",
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: Get.height * 0.029,
                                fontFamily:
                                    GoogleFonts.leagueSpartan(
                                      fontWeight: FontWeight.w600,
                                    ).fontFamily,
                              ),
                            ),
                          ],
                        ),

                    // FIXED: Proper skeleton control for ForYou
                    recentController.recentCount == 0
                        ? SizedBox.shrink()
                        : SizedBox(
                          height: 250,
                          child: Skeletonizer(
                            enabled: widget.forYouController.isLoading.value,
                            child:
                                widget.forYouController.isLoading.value
                                    ? _buildForYouSkeletonList()
                                    : _buildRecentList(),
                          ),
                        ),

                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          " For You",
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: Get.height * 0.029,
                            fontFamily:
                                GoogleFonts.leagueSpartan(
                                  fontWeight: FontWeight.w600,
                                ).fontFamily,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                           Get.to(()=> ForYouFullPage());
                          },
                          child: Icon(Icons.arrow_forward_rounded),
                        ),
                      ],
                    ),

                    // FIXED: Proper skeleton control for ForYou
                    SizedBox(
                      height: 235,
                      child: Skeletonizer(
                        enabled: widget.forYouController.isLoading.value,
                        child:
                            widget.forYouController.isLoading.value
                                ? _buildForYouSkeletonList()
                                : _buildForYouList(),
                      ),
                    ),

                    Skeletonizer(
                      enabled: true,
                      child: Skeleton.shade(
                        child: SizedBox(
                          width: double.infinity,
                          height: 140,
                          child: FittedBox(
                            fit: BoxFit.fill,
                            child: Text(
                              "LEARN WITH STUDYCO.",
                              style: GoogleFonts.mohave(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xffcccccc),
                                letterSpacing: 1,
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
          ),
        ),
      ),
    );
  }

  // ADDED: Build actual subjects grid
  Widget _buildSubjectsGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 0,
        mainAxisSpacing: 0,
        childAspectRatio: 1,
      ),
      itemCount: widget.subjectController.subjects.length,
      itemBuilder: (context, index) {
        final subject = widget.subjectController.subjects[index];
        return SizedBox(
          width: 175,
          height: 175,
          child: buildSubjectCard(subject),
        );
      },
    );
  }

  // ADDED: Build skeleton grid for subjects
  Widget _buildSubjectsSkeletonGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 0,
        mainAxisSpacing: 0,
        childAspectRatio: 1,
      ),
      itemCount: 4, // Show 6 skeleton items
      itemBuilder: (context, index) {
        return SizedBox(
          width: 175,
          height: 175,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            margin: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 100,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                Spacer(),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Container(
                    width: 150,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
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

  Widget _buildRecentList() {
    RecentMaterialsController recentController =
        Get.find<RecentMaterialsController>();

    return Obx(
      () => ListView.builder(
        shrinkWrap: true,
        scrollDirection: Axis.horizontal,
        itemCount: recentController.recentCount,
        itemBuilder: (context, index) {
          final material = recentController.recentMaterials[index];

          return GestureDetector(
            onTap: () {
              // Open PDF
              if (material.type.toLowerCase() == 'pdf') {
                Get.to(
                  () => PremiumPdfViewPage(
                    url: material.source,
                    title: material.title,
                    materialId: material.materialId,
                    subject: material.subject,
                  ),
                );
              }
            },
            child: SizedBox(
              width: 170,
              height: 262,
              child: Card(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  children: [
                    SizedBox(height: 4),
                    Container(
                      width: 155,
                      height: 160,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: CachedNetworkImage(
                          imageUrl: material.thumbnail,
                          fit: BoxFit.fill,
                          placeholder:
                              (context, url) => Container(
                                color: Colors.grey[300],
                                child: Icon(Icons.image, color: Colors.grey),
                              ),
                          errorWidget:
                              (context, url, error) => Container(
                                color: Colors.grey[300],
                                child: Icon(Icons.error, color: Colors.grey),
                              ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                        top: 2.0,
                        left: 9,
                        right: 9,
                      ),
                      child: Text(
                        material.title,
                        maxLines: 2,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    // Action buttons row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Subject badge
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          margin: EdgeInsets.only(left: 8, bottom: 8),
                          decoration: BoxDecoration(
                            color: Color(0xFFFFBB00),
                            borderRadius: BorderRadius.circular(12),
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

                        // Action buttons
                        Row(
                          children: [
                            // Time ago indicator
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              margin: EdgeInsets.only(right: 12, bottom: 8),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                material.timeAgo,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 8,
                                  fontWeight: FontWeight.w500,
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
        },
      ),
    );
  }

  Widget _buildForYouList() {
    return ListView.builder(
      shrinkWrap: true,
      scrollDirection: Axis.horizontal,
      itemCount:
          widget.forYouController.forYouItems.length >= 4
              ? 4
              : widget.forYouController.forYouItems.length,
      itemBuilder: (context, index) {
        return forYouCard(widget.forYouController.forYouItems[index]);
      },
    );
  }

  // ADDED: Build skeleton list for ForYou
  Widget _buildForYouSkeletonList() {
    return ListView.builder(
      shrinkWrap: true,
      scrollDirection: Axis.horizontal,
      itemCount: 3, // Show 3 skeleton items
      itemBuilder: (context, index) {
        return Container(
          width: 200,
          margin: EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image skeleton
              Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title skeleton
                    Container(
                      width: 150,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    SizedBox(height: 8),
                    // Subtitle skeleton
                    Container(
                      width: 100,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    SizedBox(height: 12),
                    // Button skeleton
                    Container(
                      width: 80,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
