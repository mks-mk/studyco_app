import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:studyco_app/Utilities/variables/app_colors.dart';
import '../Utilities/functions/cantact.dart';
import '../Utilities/functions/firebase/google_sighnout.dart';
import '../pages/splash/splashScreen.dart';

class BanController extends GetxController {
  RxBool isBanned = false.obs;
  bool isOpenD = false;
  final Completer<void> _initialLoadCompleter =
      Completer<void>(); // NEW: Tracks initial data load

  @override
  void onInit() {
    super.onInit();
    _initDeviceAndBind();
    // Listen to isBanned changes AFTER initial data loads
    ever<bool>(isBanned, (banned) {
      if (_initialLoadCompleter.isCompleted) {
        if (banned) {
          showBanD();
        } else {
          closeBannedDialog();
        }
      }
    });
  }

  Future<void> _initDeviceAndBind() async {
    await bindIsBanned(); // Wait for initial Firestore data
    _initialLoadCompleter.complete(); // Signal initial load complete
  }

  Future<void> bindIsBanned() async {
    User? user = FirebaseAuth.instance.currentUser;
    // 1. Get initial ban status
    final DocumentSnapshot initialDoc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user?.uid)
            .get();

    bool initialBanned =
        initialDoc.exists &&
        (initialDoc.data() as Map<String, dynamic>?)?['isRestricted'];
    isBanned.value = initialBanned;

    // 2. Listen for real-time updates
    FirebaseFirestore.instance
        .collection('users')
        .doc(user?.uid)
        .snapshots()
        .listen((doc) {
          bool newBanned = doc.exists && (doc.data())?['isRestricted'];
          if (newBanned != isBanned.value) {
            isBanned.value = newBanned;
          }
        });
  }

  void showBanD() {
    if (isOpenD) return;
    isOpenD = true;
    Get.dialog(
      PopScope(
        canPop: false,
        child: AlertDialog(
          backgroundColor: Colors.white,
          title: Text(
            "Account Access Restricted!",
            style: TextStyle(
              color: Colors.black,
              fontFamily: 'studycoFont',
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            '''We've noticed some activity on your account that doesn't align with our community guidelines. As a result, your account has been temporarily suspended.

If you believe this is a mistake or have any questions, please contact our support team. We're here to help!

Thank you for your understanding.''',
            style: TextStyle(color: Colors.black, fontFamily: 'studycoFont',fontSize: 18, height: 1.5, letterSpacing: 0.5),
          ),
          actions: [
            if (Platform.isAndroid)
              TextButton(
                onPressed: () async {
                  SystemNavigator.pop();
                },
                child: Text("Exit"),
              ),
            ElevatedButton(
              onPressed: () async {
                await signOut();
                Get.offAll(() => const Splashscreen());
                await contactUs();
              },
              style: ButtonStyle(
                backgroundColor: WidgetStatePropertyAll(AppColor.primary_1),
              ),
              child: Text("Contact us", style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      ),
      barrierDismissible: false,
      barrierColor: Colors.black54,
    ).then((_) => isOpenD = false);
  }

  void closeBannedDialog() {
    if (isOpenD) {
      Get.back();
      isOpenD = false;
    }
  }
}
