import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:studyco_app/Utilities/functions/cantact.dart';
import 'package:studyco_app/bindings/bookmark_binding.dart';
import 'package:studyco_app/pages/carts/cart_page.dart';
import 'package:studyco_app/pages/materials/my_bookmarks_page.dart';
import 'package:studyco_app/pages/settings/settings_page.dart';

import '../../Utilities/components/dialogues/logOut_dialouge.dart';
import '../../Utilities/variables/app_colors.dart';
import '../../controllers/profile/profileController.dart';
import '../../controllers/scrollController.dart';
import '../downlod/downloads_page.dart';

class ProfileScreen extends StatelessWidget {
  final ScrollerController scrollControl;

  const ProfileScreen({super.key, required this.scrollControl});

  @override
  Widget build(BuildContext context) {
    final UserProfileController userProfileController = Get.put(
      UserProfileController(),
    );
    final GlobalKey<LiquidPullToRefreshState> refreshIndicatorKey =
        GlobalKey<LiquidPullToRefreshState>();

    return LiquidPullToRefresh(
      key: refreshIndicatorKey,
      onRefresh: () async {
        await userProfileController.refreshProfile();
      },
      backgroundColor: AppColor.backgroundColor,
      color: Colors.orange,
      springAnimationDurationInMilliseconds: 800,
      showChildOpacityTransition: false,
      height: 80,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Obx(
            () => Skeletonizer(
              enabled: userProfileController.isLoading.value,
              effect: ShimmerEffect(
                baseColor: Colors.grey[100]!, // Gray shade 100
                highlightColor: Colors.grey[300]!, // Gray shade 300
                duration: Duration(seconds: 1),
              ),
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                controller: scrollControl.scrollController,
                padding: EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    // Settings Icon
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        GestureDetector(
                          onTap: () {
                            Get.to(() => SettingsPage());
                          },
                          child: Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Color(0xFFFFBB00),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.settings,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 80),

                    // Profile Section with skeleton-friendly structure
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(20),
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
                      child: Row(
                        children: [
                          // Profile Avatar - skeleton-friendly
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child:
                                userProfileController.isLoading.value
                                    ? Container() // Empty container for skeleton
                                    : ClipRRect(
                                      borderRadius: BorderRadius.circular(15),
                                      child: Image.network(
                                        userProfileController.profileImageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (
                                          context,
                                          error,
                                          stackTrace,
                                        ) {
                                          return Icon(
                                            Icons.person,
                                            size: 30,
                                            color: Colors.grey[600],
                                          );
                                        },
                                      ),
                                    ),
                          ),

                          SizedBox(width: 16),

                          // Profile Info - skeleton-friendly
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Name - will be skeletonized
                                Text(
                                  userProfileController.isLoading.value
                                      ? 'Loading User Name...'
                                      : userProfileController.name.value,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                SizedBox(height: 4),
                                // Education info - will be skeletonized
                                Text(
                                  userProfileController.isLoading.value
                                      ? 'Loading education details...'
                                      : "${userProfileController.education["course"]}, Group ${userProfileController.education["stream"]}, S${userProfileController.education["class"]} Student",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 24),

                    // Action Buttons Row - skeleton-friendly
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            icon: Icons.bookmark,
                            label: 'Bookmarks',
                            color: Color(0xFFFFBB00),
                            onTap:
                                userProfileController.isLoading.value
                                    ? () {}
                                    : () {
                                      Get.to(
                                        MyBookmarks(),
                                        binding: MyBookmarksBinding(),
                                      );
                                    },
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _buildActionButton(
                            icon: Icons.shopping_cart,
                            label: 'Cart',
                            color: Colors.blueAccent,
                            textColor: Colors.white,
                            onTap:
                                userProfileController.isLoading.value
                                    ? () {}
                                    : () {
                                      Get.to(() => CartPage());
                                    },
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _buildActionButton(
                            icon: Icons.offline_pin_rounded,
                            label: 'Offline',
                            color: Colors.grey[300]!,
                            textColor: Colors.black,
                            onTap:
                                userProfileController.isLoading.value
                                    ? () {}
                                    : () {
                                      Get.to(() => OfflineMaterialsPage());
                                    },
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 24),

                    // Menu Items - skeleton-friendly
                    _buildMenuItem(
                      icon: Icons.person_add,
                      title:
                          userProfileController.isLoading.value
                              ? 'Loading...'
                              : 'Add Profile',
                      subtitle:
                          userProfileController.isLoading.value
                              ? 'Loading description...'
                              : 'Allow you to add multiple profiles',
                      onTap:
                          userProfileController.isLoading.value
                              ? () {}
                              : () {
                                print('Add Profile tapped');
                              },
                    ),

                    _buildMenuItem(
                      icon: Icons.swap_horiz,
                      title:
                          userProfileController.isLoading.value
                              ? 'Loading...'
                              : 'Switch Profile',
                      subtitle:
                          userProfileController.isLoading.value
                              ? 'Loading description...'
                              : 'Switch to your another profile',
                      onTap:
                          userProfileController.isLoading.value
                              ? () {}
                              : () {
                                print('Switch Profile tapped');
                              },
                    ),

                    _buildMenuItem(
                      icon: Icons.feedback,
                      title:
                          userProfileController.isLoading.value
                              ? 'Loading...'
                              : 'Send feedback',
                      subtitle:
                          userProfileController.isLoading.value
                              ? 'Loading description...'
                              : 'Let us know your thoughts about us',
                      onTap:
                          userProfileController.isLoading.value
                              ? () {}
                              : () async {
                                await sendFeedback();
                              },
                    ),

                    _buildMenuItem(
                      icon: Icons.support_agent,
                      title:
                          userProfileController.isLoading.value
                              ? 'Loading...'
                              : 'Contact us',
                      subtitle:
                          userProfileController.isLoading.value
                              ? 'Loading description...'
                              : 'Communicate with studyco.',
                      onTap:
                          userProfileController.isLoading.value
                              ? () {}
                              : () async {
                                await contactUs();
                              },
                    ),

                    _buildMenuItem(
                      icon: Icons.logout_rounded,
                      title:
                          userProfileController.isLoading.value
                              ? 'Loading...'
                              : 'Logout Account',
                      subtitle:
                          userProfileController.isLoading.value
                              ? 'Loading description...'
                              : 'bye bye ${userProfileController.name.value}',
                      onTap:
                          userProfileController.isLoading.value
                              ? () {}
                              : () {
                                showLogoutDialog(context);
                              },
                    ),

                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    Color textColor = Colors.white,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 5,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: textColor, size: 24),
            SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 5,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.black, size: 20),
              ),

              SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),

              Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
