import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:studyco_app/Utilities/components/proggress_dialog.dart';
import 'package:studyco_app/controllers/single_device_controller.dart';

import '../Utilities/functions/deviceid.dart';
import '../pages/home/home_screen.dart';
import 'ban_account_controller.dart';

class AuthController extends GetxController {
  // 0 not login
  // 1 logged in
  // 2 logged in new user
  RxInt login = 0.obs;
  RxBool isLoading = false.obs;
  User? user = FirebaseAuth.instance.currentUser;

  Future<void> saveProfile({
    required String name,
    required String course,
    required String stream,
    required int sem,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      Get.back();
      Get.snackbar('Error', 'User not authenticated');
      return;
    }

    showProgress();
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .update({
            'name': name,
            'joined': FieldValue.serverTimestamp(),
            'deviceId': await getDeviceId(),
            'education': {'class': sem, 'course': course, 'stream': stream},
          });
      Get.back();
      Get.offAll(() => const HomeScreen());
      Get.put(BanController());
      Get.put(SessionController());
      Get.snackbar(
        'Success',
        'Authentication completed',
        colorText: Colors.white,
        backgroundColor: Colors.green,
      );
    } catch (e) {
      Get.back();
      print('Error saving profile: $e');
      Get.snackbar('Error', 'Failed to save profile');
    }
  }
}
