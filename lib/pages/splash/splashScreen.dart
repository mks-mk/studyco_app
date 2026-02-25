import 'dart:math' as math;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:studyco_app/controllers/profile/profileController.dart';
import 'package:studyco_app/pages/home/home_screen.dart';
import 'package:studyco_app/pages/login/profile_fill.dart';
import '../../Utilities/components/land_login_widget.dart';
import '../../Utilities/functions/firebase/device_check.dart';
import '../../controllers/ban_account_controller.dart';
import '../../controllers/bookmark/bookmarkController.dart';
import '../../controllers/cart/cart_controller.dart';
import '../../controllers/downloads/save_controller.dart';
import '../../controllers/myMaterials/my_materials_controller.dart';
import '../../controllers/recentOpenings/recent_openings_controller.dart';
import '../../controllers/single_device_controller.dart';
import '../../controllers/subjectController/getMaterialsWithSubjects.dart';

class Splashscreen extends StatefulWidget {
  const Splashscreen({super.key});

  @override
  State<Splashscreen> createState() => _SplashscreenState();
}

class _SplashscreenState extends State<Splashscreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _waveController;
  late Animation<Offset> _textPositionAnimation;
  late Animation<double> _loginWidgetAnimation;
  late Animation<double> _waveAnimation;

  bool _textAnimationCompleted = false;
  User? user = FirebaseAuth.instance.currentUser;
  final BanController banCtrl = Get.put(BanController());
  final GetStorage storage = GetStorage();

  @override
  void initState() {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
      ),
    );
    super.initState();

    // Initialize animation controllers with optimized durations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000), // Reduced from 3000
    );

    // Wave animation with better curve
    _waveAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _waveController, curve: Curves.easeInOutCubic),
    );

    // Text position animation (center to top)
    _textPositionAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -0.1),
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Login widget animation (hidden to visible)
    _loginWidgetAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    // Start animations
    _startTextAnimation();
  }

  void _startTextAnimation() {
    _waveController.forward();

    // Optimized listener - use addListener instead of addStatusListener
    _waveController.addListener(() {
      if (_waveController.isCompleted && !_textAnimationCompleted) {
        _handleAnimationComplete();
      }
    });
  }

  void _handleAnimationComplete() async {
    setState(() {
      _textAnimationCompleted = true;
    });

    if (user == null) {
      _animationController.forward();
    } else {
      if (storage.read('sem') == null) {
        Get.to(() => const ProfileFillScreen());
      } else {
        // Move heavy operations off main thread
        await _handleUserNavigation();
      }
    }
  }

  Future<void> _handleUserNavigation() async {
    devicePunch(isNew: false);
    if (await isBanned()) {
      banCtrl.showBanD();
    } else {
      Get.put(SessionController());
      Get.put(BookmarkController());
      Get.put(UserProfileController());
      Get.put(MyMaterialsController());
      Get.put(MaterialsWithSubjectsController());
      Get.put(SecureDownloadManager());
      Get.put(RecentMaterialsController());
      Get.offAll(() => const HomeScreen());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Animated text with wave effect - wrapped in RepaintBoundary
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Transform.translate(
                  offset: _textPositionAnimation.value * Get.height,
                  child: Center(
                    child: AnimatedBuilder(
                      animation: _waveAnimation,
                      builder: (context, child) {
                        return CustomPaint(
                          size: const Size(300, 150),
                          painter: OptimizedWaveTextPainter(
                            progress: _waveAnimation.value,
                            text: 'studyco.',
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),

          // Animated login widget
          Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, (1 - _loginWidgetAnimation.value) * 100),
                  child: Opacity(
                    opacity: _loginWidgetAnimation.value,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: LandLoginWidget(),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _waveController.dispose();
    super.dispose();
  }
}

// OPTIMIZED Custom painter for wave text effect
class OptimizedWaveTextPainter extends CustomPainter {
  final double progress;
  final String text;

  // Cache TextPainters to avoid recreation
  static TextPainter? _cachedGrayTextPainter;
  static TextPainter? _cachedColoredTextPainter;
  static String? _cachedText;
  static double? _cachedFontSize;
  static Path? _cachedWavePath;
  static double? _cachedProgress;

  OptimizedWaveTextPainter({required this.progress, required this.text});

  @override
  void paint(Canvas canvas, Size size) {
    final fontSize = Get.height * 0.09;

    // Cache TextPainters to avoid recreation on every frame
    if (_cachedText != text || _cachedFontSize != fontSize) {
      final textStyle = TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
          fontFamily: 'studycoFont'
      );

      _cachedGrayTextPainter = TextPainter(
        text: TextSpan(
            text: text,
            style: textStyle.copyWith(color: Colors.grey.shade300)
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      _cachedColoredTextPainter = TextPainter(
        text: TextSpan(
            text: text,
            style: textStyle.copyWith(color: Colors.black)
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      _cachedText = text;
      _cachedFontSize = fontSize;
    }

    // Calculate text position
    final textOffset = Offset(
      (size.width - _cachedGrayTextPainter!.width) / 2,
      (size.height - _cachedGrayTextPainter!.height) / 2,
    );

    // Draw background text
    _cachedGrayTextPainter!.paint(canvas, textOffset);

    // Optimize wave path creation - cache if progress hasn't changed much
    if (_cachedWavePath == null ||
        _cachedProgress == null ||
        (progress - _cachedProgress!).abs() > 0.01) {

      _cachedWavePath = _createOptimizedWavePath(size);
      _cachedProgress = progress;
    }

    // Clip and draw colored text
    canvas.save();
    canvas.clipPath(_cachedWavePath!);
    _cachedColoredTextPainter!.paint(canvas, textOffset);
    canvas.restore();
  }

  Path _createOptimizedWavePath(Size size) {
    final waveHeight = size.height * progress;
    final wavePath = Path();

    wavePath.moveTo(0, size.height - waveHeight);

    // CRITICAL FIX: Reduce calculations - use fewer points (every 10 pixels instead of 2)
    const step = 10.0; // Reduced from 2 to 10 - 5x fewer calculations
    for (double x = 0; x <= size.width; x += step) {
      final normalizedX = x / size.width;
      final waveY = size.height - waveHeight +
          (10 * math.sin(normalizedX * 4 * math.pi + (progress * 2 * math.pi)));
      wavePath.lineTo(x, waveY);
    }

    wavePath.lineTo(size.width, size.height);
    wavePath.lineTo(0, size.height);
    wavePath.close();

    return wavePath;
  }

  @override
  bool shouldRepaint(covariant OptimizedWaveTextPainter oldDelegate) {
    // CRITICAL FIX: Only repaint when progress changes significantly
    return (oldDelegate.progress - progress).abs() > 0.01;
  }
}
