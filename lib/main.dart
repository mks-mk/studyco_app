import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'controllers/authcontroller.dart';
import 'controllers/scrollController.dart';
import 'firebase_options.dart';
import 'package:studyco_app/Utilities/variables/app_colors.dart';
import 'package:studyco_app/pages/splash/splashScreen.dart';
import 'package:studyco_app/controllers/inboxController/inbox_model.dart';
import 'package:studyco_app/pages/alerts_page/alert_details_page.dart';

/// 1. Firebase background message handler (must be top-level)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  _showAwesomeNotification(message);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 2. Awesome Notifications local channel
  await AwesomeNotifications().initialize(
    null,
    [
      NotificationChannel(
        channelKey: 'alerts',
        channelName: 'Alerts',
        channelDescription: 'Important alerts channel',
        icon: "resource://drawable/ic_noti_studyco",
        defaultColor: AppColor.backgroundColor,
        ledColor: AppColor.backgroundColor,
        importance: NotificationImportance.High,
        channelShowBadge: true,
      ),
    ],
    debug: false,
  );

  // 3. Permissions for notifications
  bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
  if (!isAllowed) {
    await AwesomeNotifications().requestPermissionToSendNotifications();
  }

  // 4. Firebase Messaging setup
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Listen for foreground messages
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    _showAwesomeNotification(message);
  });

  // Handle when notification is tapped from terminated state
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    _handleNotificationTap(message);
  });

  AwesomeNotifications().setListeners(
    onActionReceivedMethod: NotificationController.onActionReceivedMethod,
  );

  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: AppColor.backgroundColor,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: AppColor.backgroundColor,
    ),
  );

  Get.put(AuthController());
  Get.put(ScrollerController());

  String? fcmToken = await FirebaseMessaging.instance.getToken();
  print("My FCM Token: $fcmToken");
  await saveFcmTokenToFirestore(fcmToken);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Studyco.',
      theme: ThemeData(scaffoldBackgroundColor: AppColor.backgroundColor),
      debugShowCheckedModeBanner: false,
      home: const Splashscreen(),
    );
  }
}

// Save/update token in Firestore (as before)
Future<void> saveFcmTokenToFirestore(String? fcmToken) async {
  if (fcmToken == null) return;
  final user = Get.find<AuthController>().user;
  if (user == null) return;
  final uid = user.uid;
  final docRef = FirebaseFirestore.instance.collection('FCM User').doc(uid);
  final doc = await docRef.get();
  if (!doc.exists || doc.data()?['fcmToken'] != fcmToken) {
    await docRef.set({
      'fcmToken': fcmToken,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    print('FCM token saved/updated for user: $uid');
  }
}

// Show "awesome notification" for a Firebase message
void _showAwesomeNotification(RemoteMessage message) {
  final data = message.data;
  final notification = message.notification;

  AwesomeNotifications().createNotification(
    content: NotificationContent(
      id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
      channelKey: 'alerts',
      title: notification?.title ?? data['title'] ?? 'Alert',
      body: notification?.body ?? data['body'] ?? '',
      icon: 'resource://drawable/ic_noti_studyco',
      payload: <String, String>{
        if (data.containsKey('alertId')) 'alertId': data['alertId'],
      },
      notificationLayout: NotificationLayout.Default,
    ),
  );
}

// Handle tapping the notification when the app is opened via system tray
void _handleNotificationTap(RemoteMessage message) {
  final data = message.data;
  final alertId = data['alertId'];
  if (alertId != null) {
    NotificationController.handleAlertTap(alertId);
  }
}

class NotificationController {
  static Future<void> onActionReceivedMethod(ReceivedAction receivedAction) async {
    final String? alertId = receivedAction.payload?['alertId'];
    if (alertId != null) {
      await handleAlertTap(alertId);
    }
  }

  static Future<void> handleAlertTap(String alertId) async {
    Get.dialog(const Center(child: CircularProgressIndicator(color: Color(0xd9ffbb00))), barrierDismissible: true);
    try {
      final doc = await FirebaseFirestore.instance.collection('Alerts').doc(alertId).get();
      if (doc.exists) {
        final alert = AlertModel.fromSnapshot(doc);
        Get.back();
        Get.to(() => AlertDetailsScreen(alert: alert));
      } else {
        Get.back();
        Get.snackbar('Not found', 'Sorry, alert not found!');
      }
    } catch (e) {
      Get.back();
      Get.snackbar('Error', 'Could not open alert: $e');
    }
  }
}
