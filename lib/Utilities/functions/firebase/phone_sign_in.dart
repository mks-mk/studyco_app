import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:studyco_app/Utilities/functions/firebase/store_user.dart';
import 'package:studyco_app/controllers/ban_account_controller.dart';
import 'package:studyco_app/pages/login/otp_screen.dart';
import '../../../controllers/authcontroller.dart';
import '../../components/proggress_dialog.dart';
import '../../components/single_login_alert.dart';
import 'device_check.dart';
import 'google_sighnout.dart';

// Phone number verification function
Future<void> verifyPhoneNumber(String phoneNumber) async {
  try {
    showProgress();

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _handlePhoneSignIn(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        Get.back();
        if (kDebugMode) {
          print('Phone verification failed: ${e.code} - ${e.message}');
        }
        Get.snackbar('Error', 'Phone verification failed: ${e.message}');
      },
      codeSent: (String verificationId, int? resendToken) {
        Get.back();
        Get.to(()=> OTPScreen(phoneNumber: phoneNumber,verificationId: verificationId,));
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
      timeout: const Duration(seconds: 60),
    );
  } catch (e) {
    Get.back();
    if (kDebugMode) {
      print('Phone auth error: $e');
    }
    Get.snackbar('Error', 'Phone authentication failed');
  }
}

// OTP verification function to be called from your OTP screen
Future<void> verifyOTP({
  required String verificationId,
  required String otp,
  required String phoneNumber,
}) async {
  try {
    showProgress();

    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: otp,
    );

    await _handlePhoneSignIn(credential);
  } catch (e) {
    Get.back();
    if (kDebugMode) {
      print('OTP verification error: $e');
    }
    Get.snackbar('Error', 'Invalid OTP code');
    rethrow; // Re-throw the error if you want to handle it in the UI
  }
}

Future<void> _handlePhoneSignIn(PhoneAuthCredential credential) async {
  try {
    final UserCredential userCredential = await FirebaseAuth.instance
        .signInWithCredential(credential);

    final User? user = userCredential.user;
    if (user != null) {
      final bool isNewUser =
          userCredential.additionalUserInfo?.isNewUser ?? false;
      AuthController authController = Get.put(AuthController());
      BanController banCtrl = Get.put(BanController());

      if (isNewUser) {
        if (kDebugMode) {
          print('New user signed up with Phone');
        }

        await addUser(
          name: 'Phone User',
          email: '${user.phoneNumber}@phone.studyco.com',
          number: user.phoneNumber ?? '',
          profile: user.photoURL ?? "",
          uid: user.uid,
          isNew: true,
        );
        devicePunch(isNew: true);
        authController.login.value = 2;
      } else {
        if (kDebugMode) {
          print('Existing user logged in with Phone');
        }

        devicePunch(isNew: false);
        if (await deviceCheck(userId: user.uid) == false) {
          Get.back();
          showCustomDialog(
            title: "Single device login!",
            message: "This account is already logged in on another device. If you log in here, the other device will be logged out. Only one device can use this app at a time.",
            agreeText: "I Agree",
            cancelText: "Cancel",
            onAgree: () async {
              await addUser(
                name: 'Phone User',
                email: '${user.phoneNumber}@phone.studyco.com',
                number: user.phoneNumber ?? '',
                profile: user.photoURL ?? '',
                uid: user.uid,
                isNew: false,
              );
              authController.login.value = 1;
            },
            onCancel: () async {
              await signOut();
              Get.offAllNamed('/splash');
            },
          );
        } else if (await isBanned()) {
          Get.back();
          banCtrl.showBanD();
        } else {
          await addUser(
            name: 'Phone User',
            email: '${user.phoneNumber}@phone.studyco.com',
            number: user.phoneNumber ?? '',
            profile: user.photoURL ?? '',
            uid: user.uid,
            isNew: false,
          );
          authController.login.value = 1;
        }
      }
    }
  } catch (e) {
    Get.back();
    rethrow;
  }
}