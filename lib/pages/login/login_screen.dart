import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:studyco_app/Utilities/functions/firebase/google_sighnout.dart';
import 'package:studyco_app/controllers/ban_account_controller.dart';
import '../../Utilities/variables/app_colors.dart';
import '../splash/splashScreen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final BanController banCtrl = Get.find<BanController>();
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: AppColor.backgroundColor,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: AppColor.backgroundColor,
      ),
    );
    return Scaffold(
      body: Obx(
        () => Padding(
          padding: const EdgeInsets.only(top: 18.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () {
                  signOut();
                  Get.offAll(() => const Splashscreen());
                },
                child: Text(banCtrl.isBanned.value ? 'Banned' : 'Not Banned'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
