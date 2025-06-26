import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:studyco_app/Utilities/variables/app_colors.dart';
import 'package:studyco_app/pages/home/home_screen.dart';
import 'package:studyco_app/pages/login/profile_fill.dart';
import '../../controllers/authcontroller.dart';
import '../../controllers/single_device_controller.dart';
import '../../pages/login/login_screen.dart';
import '../../pages/login/phone_auth_screen.dart';
import '../functions/firebase/google_signin.dart';
import 'gradient_bt.dart';

class LandLoginWidget extends StatelessWidget {
  LandLoginWidget({super.key});

  final AuthController authController = Get.find<AuthController>();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: Get.width - 20,
      height: Get.height * 0.4,
      decoration: BoxDecoration(
        color: AppColor.backgroundColor,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 25.0, horizontal: 12),
        child: Column(
          children: [
            Text(
              "Join with us,",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: Get.height * 0.04 + 10,
                fontFamily: GoogleFonts.leagueSpartan(
                  fontWeight: FontWeight.bold,
                ).fontFamily,
              ),
            ),
            Text(
              "please signing with us that can keep your status !",
              style: TextStyle(
                fontSize: Get.width * 0.03,
                color: const Color(0xFF818181),
                fontFamily: GoogleFonts.poppins().fontFamily,
              ),
            ),
            const SizedBox(height: 10),
            // Reactive Google Sign-In Button
            Obx(() {
              // Handle navigation when login state changes
              if (authController.login.value == 1) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Get.back();
                  Get.put(SessionController());
                  Get.offAll(() => const HomeScreen());
                });
              }else if(authController.login.value == 2){
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Get.back();
                  Get.offAll(() => const ProfileFillScreen());
                });
              }
              return GradientBG(
                onTap: () async {
                  await googleAuthStudyCo();
                },
                height: Get.height * 0.06 + 5,
                width: Get.width - 50,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.white,
                        radius: 18,
                        child: Image.asset(
                          "assets/images/google_ic.png",
                          height: 26,
                          width: 26,
                        ),
                      ),
                      Text(
                        " Google Sign-In",
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          fontFamily: GoogleFonts.leagueSpartan(
                            fontWeight: FontWeight.w600,
                          ).fontFamily,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 12),
            // Phone Sign-In Button (non-reactive)
            GradientBG(
              onTap: () {
                Get.to(() => const PhoneNumberAuthScreen());
              },
              height: Get.height * 0.06 + 5,
              width: Get.width - 50,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.black,
                      radius: 16,
                      child: Icon(
                        Icons.local_phone_rounded,
                        size: 24,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      " Phone Sign-In",
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        fontFamily: GoogleFonts.leagueSpartan(
                          fontWeight: FontWeight.w600,
                        ).fontFamily,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontFamily: GoogleFonts.leagueSpartan(
                    fontWeight: FontWeight.w300,
                  ).fontFamily,
                ),
                children: <TextSpan>[
                  const TextSpan(
                    text: " by Sign in you agreeing the ",
                    style: TextStyle(color: Color(0xff939393)),
                  ),
                  TextSpan(
                    text: "privacy & policy",
                    style: const TextStyle(
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        // Get.to(() => PrivacyPolicyScreen());
                      },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}