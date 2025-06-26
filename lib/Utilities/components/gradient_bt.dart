import 'package:flutter/material.dart';
import 'package:studyco_app/Utilities/variables/app_colors.dart';

class GradientBG extends StatelessWidget {
  final double height;
  final double width;
  final Widget child;
  final VoidCallback? onTap;
  const GradientBG({super.key, required this.height, required this.width, required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            colors: [AppColor.primary_1, AppColor.primary_2],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: child,
      ),
    );
  }
}
