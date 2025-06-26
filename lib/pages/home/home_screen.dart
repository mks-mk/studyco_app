import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../Utilities/components/widget_components/bottom_nav_bar.dart';
import '../../Utilities/components/widget_components/for_you_widget.dart';
import '../../Utilities/components/widget_components/subject_card.dart';
import '../../Utilities/variables/app_colors.dart';
import '../../controllers/navController.dart';
import '../../controllers/scrollController.dart';
import '../../controllers/subjectController/fetch_subjects.dart';
import '../../controllers/subjectController/for_you_controller.dart';
import '../alerts_page/Alerts_Screen.dart';
import '../my_notes_page/myNotes_screen.dart';
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
      ProfileScreen(
        scrollControl: scrollControl,
      ),
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
              child: Obx(() => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "studyco.",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: Get.height * 0.07,
                      fontFamily: GoogleFonts.leagueSpartan(
                        fontWeight: FontWeight.bold,
                      ).fontFamily,
                    ),
                  ),

                  // FIXED: Proper skeleton control for subjects
                  Skeletonizer(
                    enabled: widget.subjectController.isLoading.value,
                    child: widget.subjectController.isLoading.value
                        ? _buildSubjectsSkeletonGrid()
                        : _buildSubjectsGrid(),
                  ),

                  SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        " For You",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: Get.height * 0.029,
                          fontFamily: GoogleFonts.leagueSpartan(
                            fontWeight: FontWeight.w600,
                          ).fontFamily,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          //TODO: Implement See All
                        },
                        child: Icon(Icons.arrow_forward_rounded),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),

                  // FIXED: Proper skeleton control for ForYou
                  SizedBox(
                    height: 235,
                    child: Skeletonizer(
                      enabled: widget.forYouController.isLoading.value,
                      child: widget.forYouController.isLoading.value
                          ? _buildForYouSkeletonList()
                          : _buildForYouList(),
                    ),
                  ),

                  SizedBox(height: 6),

                  // FIXED: Remove perpetual skeleton from bottom text
                  SizedBox(
                    width: double.infinity,
                    height: 150,
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
                ],
              )),
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
            padding: EdgeInsets.symmetric(horizontal: 12,vertical: 16),
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


  Widget _buildForYouList() {
    return ListView.builder(
      shrinkWrap: true,
      scrollDirection: Axis.horizontal,
      itemCount: widget.forYouController.forYouItems.length,
      itemBuilder: (context, index) {
        return forYouCard(
          widget.forYouController.forYouItems[index],
        );
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
