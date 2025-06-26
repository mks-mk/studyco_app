import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../controllers/authcontroller.dart';
import '../../../pages/splash/splashScreen.dart';

Future<void> signOut() async {
  try {
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn().signOut();
    Get.find<AuthController>().login.value = 0;
    Get.offAll(()=>Splashscreen());
    print('User signed out successfully');
  } catch (e) {
    print('Error signing out: $e');
  }
}