import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:studyco_app/Utilities/variables/app_colors.dart';
import 'package:studyco_app/pages/splash/splashScreen.dart';
import 'controllers/authcontroller.dart';
import 'controllers/scrollController.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Studyco.',
      theme: ThemeData(scaffoldBackgroundColor: AppColor.backgroundColor),
      debugShowCheckedModeBanner: false,
      home: Splashscreen(),
    );
  }
}
