import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:studyco_app/Utilities/functions/cantact.dart';
import 'package:studyco_app/bindings/bookmark_binding.dart';
import 'package:studyco_app/pages/materials/my_bookmarks_page.dart';
import 'package:studyco_app/pages/settings/settings_page.dart';

import '../../Utilities/components/dialogues/logOut_dialouge.dart';
import '../../Utilities/variables/app_colors.dart';
import '../../controllers/profile/profileController.dart';
import '../../controllers/scrollController.dart';
import '../downlod/downloads_page.dart';
import '../login/profile_fill.dart';

class ProfileScreen extends StatelessWidget {
  final ScrollerController scrollControl;

  const ProfileScreen({super.key, required this.scrollControl});

  @override
  Widget build(BuildContext context) {
    final UserProfileController userProfileController =
        Get.find<UserProfileController>();
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
                            color: Colors.grey.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Profile Avatar - skeleton-friendly
                          // Wrap your original widget in a Stack to place the camera icon on top
                          GestureDetector(
                            onTap: userProfileController.isLoading.value || userProfileController.isUploadingImage.value
                                ? null
                                : () => userProfileController.updateProfileImage(),
                            child: Stack(
                              children: [
                                // Your original container for the profile image
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    shape:
                                        BoxShape
                                            .circle, // Using BoxShape.circle is cleaner
                                  ),
                                  // Use ClipOval for perfect circular clipping of the child
                                  child: ClipOval(
                                  // AnimatedSwitcher fades between the loading indicator and the image
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 400),
                                    transitionBuilder:
                                        (child, animation) => FadeTransition(
                                          opacity: animation,
                                          child: child,
                                        ),
                                    child:
                                        (userProfileController.isLoading.value || userProfileController.isUploadingImage.value)
                                            // 1. Show a progress indicator while loading
                                            ? Container(
                                              // Use a key to help AnimatedSwitcher identify the change
                                              key: const ValueKey('loading'),
                                              padding: const EdgeInsets.all(
                                                18.0,
                                              ),
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.grey[400],
                                              ),
                                            )
                                            // 2. Show the image when loaded
                                            : Image.network(
                                              // Use a key to help AnimatedSwitcher identify the change
                                              key: const ValueKey('image'),
                                              userProfileController
                                                  .profileImageUrl,
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
                              ),
                              // 3. The Camera Icon, positioned on top of the Stack
                              userProfileController.isVerified.value ? Positioned(
                                bottom: 0,
                                right: -5,
                                child: Container(
                                  width: 26,
                                  height: 26,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                    border: Border.all(
                                      color:
                                      Colors
                                          .grey[200]!, // Border color to blend with the background
                                      width: 1,
                                    ),
                                  ),
                                  child: CachedNetworkImage(
                                    imageUrl:
                                    "https://firebasestorage.googleapis.com/v0/b/studyco-app-55a76.firebasestorage.app/o/util%2Fverified.png?alt=media&token=b1f56d5c-27b2-4044-b0a6-a43acb4d350b",
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ) : SizedBox.shrink(),
                              // 4. Edit Camera Icon Overlay
                              Positioned(
                                bottom: 0,
                                left: -5,
                                child: Container(
                                  width: 26,
                                  height: 26,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xFFFFBB00),
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  child: Icon(Icons.camera_alt, size: 14, color: Colors.white),
                                ),
                              ),
                            ],
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
                      icon: Icons.edit_road_rounded,
                      title:
                          userProfileController.isLoading.value
                              ? 'Loading...'
                              : 'Edit Profile',
                      subtitle:
                          userProfileController.isLoading.value
                              ? 'Loading description...'
                              : 'Edit your profile (class , course, etc.)',
                      onTap:
                          userProfileController.isLoading.value
                              ? () {}
                              : () {
                                Get.to(() => ProfileFillScreen());
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
              color: Colors.grey.withValues(alpha: 0.1),
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
                color: Colors.grey.withValues(alpha: 0.1),
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
