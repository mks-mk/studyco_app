import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:studyco_app/controllers/recentOpenings/recent_openings_controller.dart';

import '../../../controllers/authcontroller.dart';
import '../../../pages/splash/splashScreen.dart';

Future<void> signOut() async {
  try {
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn().signOut();
    Get.find<RecentMaterialsController>().clearRecentMaterials();
    Get.find<AuthController>().login.value = 0;
    Get.offAll(()=>Splashscreen());
  } catch (e) {
    if (kDebugMode) {
      print('Error signing out: $e');
    }
  }
}