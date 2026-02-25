import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';


class UserProfileController extends GetxController {
  // Observable variables
  var profileData = <String, dynamic>{}.obs;
  var isLoading = false.obs;
  var errorMessage = ''.obs;

  // Individual profile fields for easy access
  var deviceId = ''.obs;
  var email = ''.obs;
  var name = ''.obs;
  var number = ''.obs;
  var profile = ''.obs;
  RxBool isVerified = false.obs;
  var joinedDate = ''.obs;
  var education = {}.obs;

  @override
  void onInit() {
    super.onInit();
    fetchUserProfile();
  }

  /// Fetch user profile data excluding education, bookmarks, and isRestricted
  Future<void> fetchUserProfile() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        errorMessage.value = 'User not authenticated';
        return;
      }

      print('Fetching profile for user: ${currentUser.uid}');

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (doc.exists && doc.data() != null) {
        final data = Map<String, dynamic>.from(doc.data()!);

        data.remove('bookmarks');
        data.remove('isRestricted');

        // Update observable data
        profileData.value = data;

        // Update individual fields for easy access
        deviceId.value = data['deviceId'] ?? '';
        email.value = data['email'] ?? '';
        name.value = data['name'] ?? '';
        number.value = data['number'] ?? '';
        profile.value = data['profile'] ?? '';
        education.value = data['education'] ?? {};
        isVerified.value = data['isVerified'] ?? false;

        // Format joined date if available
        if (data['joined'] != null) {
          try {
            if (data['joined'] is Timestamp) {
              final timestamp = data['joined'] as Timestamp;
              joinedDate.value = timestamp.toDate().toString();
            } else {
              joinedDate.value = data['joined'].toString();
            }
          } catch (e) {
            joinedDate.value = data['joined'].toString();
          }
        }

        print('Profile data fetched successfully');
        print('User: ${name.value}');
        print('Email: ${email.value}');

        // ADD: Check profile completeness after fetching
        _checkProfileCompleteness();

      } else {
        errorMessage.value = 'User profile not found';
        print('User document does not exist');
      }
    } catch (e) {
      errorMessage.value = 'Failed to fetch profile: ${e.toString()}';
      print('Error fetching user profile: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ADD: Check if profile needs completion
  void _checkProfileCompleteness() {
    // Check if number is empty or null
    if (number.value.isEmpty) {
      Future.delayed(Duration(milliseconds: 500), () {
        _showNumberInputBottomSheet();
      });
      return;
    }

    // Check if email is in default format (usernumber@phone.studyco.com)
    if (_isDefaultEmail(email.value)) {
      Future.delayed(Duration(milliseconds: 500), () {
        _showEmailInputBottomSheet();
      });
      return;
    }
  }

  // ADD: Check if email is in default format
  bool _isDefaultEmail(String email) {
    if (email.isEmpty) return false;
    // Pattern: digits@phone.studyco.com
    final pattern = RegExp(r'^\d+@phone\.studyco\.com$');
    return pattern.hasMatch(email);
  }

  // ADD: Show bottom sheet for number input
  void _showNumberInputBottomSheet() {
    final TextEditingController numberController = TextEditingController();

    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            SizedBox(height: 20),

            // Title
            Text(
              'Complete Your Profile',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Please enter your phone number to continue',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 20),

            // Number input field
            TextField(
              controller: numberController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                hintText: 'Enter your phone number',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Color(0xFFFFBB00), width: 2),
                ),
              ),
            ),
            SizedBox(height: 20),

            // Save button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  final phoneNumber = numberController.text.trim();
                  if (phoneNumber.isNotEmpty) {
                    await updateProfileField('number', phoneNumber);
                    Get.back();

                    // Check email after number is saved
                    if (_isDefaultEmail(email.value)) {
                      Future.delayed(Duration(milliseconds: 300), () {
                        _showEmailInputBottomSheet();
                      });
                    }
                  } else {
                    Get.snackbar(
                      'Error',
                      'Please enter a valid phone number',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: Colors.red,
                      colorText: Colors.white,
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFFFBB00),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Save Phone Number',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SizedBox(height: 10),
          ],
        ),
      ),
      isDismissible: false,
      enableDrag: false,
    );
  }

  // ADD: Show bottom sheet for email input
  void _showEmailInputBottomSheet() {
    final TextEditingController emailController = TextEditingController();

    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            SizedBox(height: 20),

            // Title
            Text(
              'Update Your Email',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Please enter your actual email address',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 20),

            // Email input field
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email Address',
                hintText: 'Enter your email address',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Color(0xFFFFBB00), width: 2),
                ),
              ),
            ),
            SizedBox(height: 20),

            // Save button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  final emailAddress = emailController.text.trim();
                  if (emailAddress.isNotEmpty && _isValidEmail(emailAddress)) {
                    await updateProfileField('email', emailAddress);
                    Get.back();

                    Get.snackbar(
                      'Success',
                      'Profile updated successfully!',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: Colors.green,
                      colorText: Colors.white,
                    );
                  } else {
                    Get.snackbar(
                      'Error',
                      'Please enter a valid email address',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: Colors.red,
                      colorText: Colors.white,
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFFFBB00),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Save Email Address',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SizedBox(height: 10),
          ],
        ),
      ),
      isDismissible: false,
      enableDrag: false,
    );
  }

  // ADD: Validate email format
  bool _isValidEmail(String email) {
    final pattern = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return pattern.hasMatch(email);
  }

  /// Refresh user profile data
  Future<void> refreshProfile() async {
    await fetchUserProfile();
  }

  /// Update specific profile field
  Future<void> updateProfileField(String field, dynamic value) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        errorMessage.value = 'User not authenticated';
        return;
      }

      // Don't allow updating restricted fields
      if (['bookmarks', 'isRestricted'].contains(field)) {
        errorMessage.value = 'Cannot update restricted field: $field';
        return;
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .update({field: value});

      // Update local data
      profileData[field] = value;

      // Update individual observable if it exists
      switch (field) {
        case 'name':
          name.value = value.toString();
          break;
        case 'email':
          email.value = value.toString();
          break;
        case 'number':
          number.value = value.toString();
          break;
        case 'profile':
          profile.value = value.toString();
          break;
        case 'deviceId':
          deviceId.value = value.toString();
          break;
      }

      print('Profile field $field updated successfully');

    } catch (e) {
      errorMessage.value = 'Failed to update profile: ${e.toString()}';
      print('Error updating profile field: $e');
    }
  }

  /// Get profile data as Map
  Map<String, dynamic> getProfileData() {
    return Map<String, dynamic>.from(profileData);
  }

  /// Check if profile data is loaded
  bool get hasProfileData => profileData.isNotEmpty;

  /// Get formatted phone number
  String get formattedNumber {
    if (number.value.isEmpty) return '';
    // Add formatting logic if needed
    return number.value;
  }

  /// Check if user has profile image
  bool get hasProfileImage => profile.value.isNotEmpty;

  /// Get profile image URL
  String get profileImageUrl => profile.value;

  /// Clear all profile data (for logout)
  void clearProfileData() {
    profileData.clear();
    deviceId.value = '';
    email.value = '';
    name.value = '';
    number.value = '';
    profile.value = '';
    joinedDate.value = '';
    errorMessage.value = '';
    isVerified.value = false;
  }

  /// Listen to real-time profile updates
  void startProfileListener() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .snapshots()
        .listen((doc) {
      if (doc.exists && doc.data() != null) {
        final data = Map<String, dynamic>.from(doc.data()!);

        // Remove unwanted fields
        data.remove('education');
        data.remove('bookmarks');
        data.remove('isRestricted');

        // Update observable data
        profileData.value = data;

        // Update individual fields
        deviceId.value = data['deviceId'] ?? '';
        email.value = data['email'] ?? '';
        name.value = data['name'] ?? '';
        number.value = data['number'] ?? '';
        profile.value = data['profile'] ?? '';
        isVerified.value = data['isVerified'] ?? false;

        if (data['joined'] != null) {
          try {
            if (data['joined'] is Timestamp) {
              final timestamp = data['joined'] as Timestamp;
              joinedDate.value = timestamp.toDate().toString();
            } else {
              joinedDate.value = data['joined'].toString();
            }
          } catch (e) {
            joinedDate.value = data['joined'].toString();
          }
        }
      }
    }, onError: (error) {
      errorMessage.value = 'Profile listener error: ${error.toString()}';
      print('Profile listener error: $error');
    });
  }
}
