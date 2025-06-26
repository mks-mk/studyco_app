import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:studyco_app/Utilities/functions/firebase/store_user.dart';
import 'package:studyco_app/controllers/ban_account_controller.dart';
import '../../../controllers/authcontroller.dart';
import '../../../pages/splash/splashScreen.dart';
import '../../components/proggress_dialog.dart';
import '../../components/single_login_alert.dart';
import 'device_check.dart';
import 'google_sighnout.dart';

Future<void> googleAuthStudyCo() async {
  try {
    // Step 1: Initialize Google Sign-In
    final GoogleSignIn googleSignIn = GoogleSignIn(
      scopes: ['email', 'profile'],
    );

    // Step 2: Trigger Google Sign-In flow
    final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
    if (googleUser == null) {
      if (kDebugMode) {
        print('Google sign-in aborted by user');
      }
      return;
    }

    // Step 3: Get authentication tokens
    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    // Step 4: Create Firebase credential
    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // Step 5: Sign in to Firebase
    final UserCredential userCredential = await FirebaseAuth.instance
        .signInWithCredential(credential);

    // Step 6: Get and handle user data safely
    final User? user = userCredential.user;
    if (user != null) {
      showProgress();
      final bool isNewUser =
          userCredential.additionalUserInfo?.isNewUser ?? false;
      AuthController authController = Get.put(AuthController());
      BanController banCtrl = Get.put(BanController());
      if (isNewUser) {
        if (kDebugMode) {
          print('New user signed up with Google');
        }

        // Handle first-time signup (with fallbacks for null values)
        await addUser(
          name: user.displayName ?? 'No Name', // Fallback if null
          email: user.email ?? 'no-email@studyco.com', // Fallback if null
          number: user.phoneNumber ?? '', // Fallback if null
          profile: user.photoURL ?? '', // Fallback if null
          uid: user.uid, // UID is guaranteed to exist
          isNew: true,
        );
        devicePunch(isNew: true);
        authController.login.value = 2;
        return;
      } else {
        if (kDebugMode) {
          print('Existing user logged in with Google');
        }
        // Handle existing user login
        devicePunch(isNew: false);
        if (await deviceCheck(userId: user.uid) == false) {
          Get.back();
          showCustomDialog(
            title: "Single device login!",
            message:
                "This account is already logged in on another device. If you log in here, the other device will be logged out. Only one device can use this app at a time.",
            agreeText: "I Agree",
            cancelText: "Cancel",
            onAgree: () async {
              await addUser(
                name: user.displayName ?? 'No Name', // Fallback if null
                email: user.email ?? 'no-email@example.com', // Fallback if null
                number: user.phoneNumber ?? '', // Fallback if null
                profile: user.photoURL ?? '', // Fallback if null
                uid: user.uid, // UID is guaranteed to exist
                isNew: false,
              );
              authController.login.value = 1;
            },
            onCancel: () async {
              await signOut();
              Get.offAll(() => const Splashscreen());
            },
          );
        } else if (await isBanned()) {
          Get.back();
          banCtrl.showBanD();
        } else {
          await addUser(
            name: user.displayName ?? 'No Name', // Fallback if null
            email: user.email ?? 'no-email@example.com', // Fallback if null
            number: user.phoneNumber ?? '', // Fallback if null
            profile: user.photoURL ?? '', // Fallback if null
            uid: user.uid, // UID is guaranteed to exist
            isNew: false,
          );
          authController.login.value = 1;
        }
      }

      // Log user details safely
      if (kDebugMode) {
        print('''
      Successful Google Sign-In:
      UID: ${user.uid}
      Name: ${user.displayName ?? 'N/A'}
      Email: ${user.email ?? 'N/A'}
      Photo URL: ${user.photoURL ?? 'N/A'}
      Phone: ${user.phoneNumber ?? 'N/A'}
      Provider: ${user.providerData.map((p) => p.providerId).join(', ')}
      ''');
      }
    }

    return;
  } catch (e) {
    if (e is FirebaseAuthException) {
      if (kDebugMode) {
        print('Firebase Auth Error: ${e.code} - ${e.message}');
      }
    } else if (e is PlatformException) {
      if (kDebugMode) {
        print('Platform Error: ${e.code} - ${e.message}');
      }
    } else {
      if (kDebugMode) {
        print('Unexpected Error: $e');
      }
    }
    return;
  }
}
