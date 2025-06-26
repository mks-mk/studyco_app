import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CustomProgressDialog extends StatelessWidget {
  const CustomProgressDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: Get.width * 0.2 + 8,
        height: Get.height * 0.1,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            color: CupertinoColors.systemYellow,
          ),
        ),
      ),
    );
  }
}

void showProgress() {
  Get.dialog(const CustomProgressDialog(), barrierDismissible: false);
}
