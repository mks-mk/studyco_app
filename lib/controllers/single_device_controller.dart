import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../Utilities/components/single_login_alert.dart';
import '../Utilities/functions/cantact.dart';
import '../Utilities/functions/deviceid.dart';
import '../Utilities/functions/firebase/google_sighnout.dart';
import '../pages/splash/splashScreen.dart';

class SessionController extends GetxController {
  RxString storedDeviceId = ''.obs;
  String currentDeviceId = '';
  bool isDialogOpen = false;
  final Completer<void> _initialLoadCompleter = Completer<void>();
  StreamSubscription<DocumentSnapshot>? _userSubscription;

  @override
  void onInit() {
    super.onInit();
    _initializeDeviceCheck();
    ever<String>(storedDeviceId, _handleDeviceIdChange);
  }

  @override
  void onClose() {
    _userSubscription?.cancel();
    super.onClose();
  }

  Future<void> _initializeDeviceCheck() async {
    try {
      currentDeviceId = await getDeviceId() ?? '';
      await _bindDeviceIdStream();
    } catch (e) {
      print("Initialization error: $e");
    } finally {
      _initialLoadCompleter.complete();
    }
  }

  Future<void> _bindDeviceIdStream() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
      _userSubscription = userDoc.snapshots().listen(
        _updateStoredId,
        onError: (e) => print("Firestore error: $e"),
      );
    } catch (e) {
      print("Stream binding failed: $e");
    }
  }

  void _updateStoredId(DocumentSnapshot doc) {
    try {
      final String newId = doc.exists ? (doc.data() as Map<String, dynamic>)['deviceId']?.toString() ?? '' : "";
      if (newId != storedDeviceId.value) {
        storedDeviceId.value = newId;
      }
    } catch (e) {
      print("Error updating device ID: $e");
    }
  }

  Future<void> _handleDeviceIdChange(String storedId) async {
    await _initialLoadCompleter.future;
    if (storedId.isNotEmpty && storedId != currentDeviceId && !isDialogOpen) {
      await _showDeviceMismatchDialog();
    }
  }

  Future<void> _showDeviceMismatchDialog() async {
    if (Get.isDialogOpen ?? false) return;

    isDialogOpen = true;
    try {
        isDialogOpen = true;
        await signOut();
        Get.offAll(() => const Splashscreen());
        showCustomDialog(
            title: "Session Expired!",
            message: "Your account was accessed from another device because of that your device has been logged out.",
            agreeText: "I Understand",
            cancelText: "Contact us",
            onAgree: () async {
              _closeDialog();
            },
            onCancel: () async{
              await contactUs();
            }
        ).then((_) => isDialogOpen = false);

    } finally {
      isDialogOpen = false;
    }
  }

  void _closeDialog() {
    if (isDialogOpen) {
      Get.back();
      isDialogOpen = false;
    }
  }
}