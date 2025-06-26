import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../pages/splash/splashScreen.dart';
import '../functions/firebase/google_sighnout.dart';
import 'gradient_bt.dart';

class CustomAlertDialog extends StatelessWidget {
  final String title;
  final String message;
  final String agreeText;
  final String cancelText;
  final VoidCallback? onAgree;
  final VoidCallback? onCancel;
  final bool barrierDismissible;

  const CustomAlertDialog({
    super.key,
    required this.title,
    required this.message,
    this.agreeText = "I Agree",
    this.cancelText = "Cancel",
    this.onAgree,
    this.onCancel,
    this.barrierDismissible = false,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      elevation: 24,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: const EdgeInsets.all(18),
      title: Text(
        title,
        textAlign: TextAlign.center,
        style: GoogleFonts.leagueSpartan(
          color: Colors.black,
          fontSize: Get.height * 0.028,
          fontWeight: FontWeight.w700,
        ),
      ),
      actions: [
        Visibility(
          visible: cancelText != "null" ? true : false,
          child: GradientBG(
            height: 40,
            width: Get.width * 0.3,
            onTap: () async {
              Get.back();
              if (onCancel != null) {
                onCancel!();
              } else {
                await signOut();
                Get.offAll(() => const Splashscreen());
              }
            },
            child: Center(
              child: Text(
                cancelText,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
        Visibility(
          visible: onAgree != "null" ? true : false,
          child: GradientBG(
            height: 40,
            width: Get.width * 0.3,
            onTap: () {
              Get.back();
              if (onAgree != null) onAgree!();
            },
            child: Center(
              child: Text(
                agreeText,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ],
      content: Text(
        message,
        style: GoogleFonts.poppins(
          color: Colors.black87,
          fontSize: Get.height * 0.02,
          fontWeight: FontWeight.w500,
        ),
      ),
      actionsAlignment: MainAxisAlignment.center,

    );
  }
}

Future<void> showCustomDialog({
  required String title,
  required String message,
  String agreeText = "I Agree",
  String cancelText = "Cancel",
  VoidCallback? onAgree,
  VoidCallback? onCancel,
  bool barrierDismissible = false,
}) async {
  await Get.dialog(
    CustomAlertDialog(
      title: title,
      message: message,
      agreeText: agreeText,
      cancelText: cancelText,
      onAgree: onAgree,
      onCancel: onCancel,
      barrierDismissible: barrierDismissible,
    ),
    barrierDismissible: barrierDismissible,
  );
}
