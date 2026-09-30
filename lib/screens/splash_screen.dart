import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../services/user_service.dart';
import '../theme/app_colors.dart';
import '../widgets/custom_text.dart';

// Enhancement 1: our own splash screen. It shows the logo while it checks for a
// saved session (persistent authentication) and then opens Home or Sign in.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..forward();

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  @override
  void dispose() {
    _intro.dispose();
    super.dispose();
  }

  Future<void> _checkAuthentication() async {
    // Long enough for the logo animation to play and be seen.
    await Future.delayed(const Duration(milliseconds: 3000));

    bool loggedIn;
    try {
      // True when Firebase restored a session or DummyJSON tokens are saved.
      loggedIn = await userService.value.isLoggedIn();
    } catch (_) {
      loggedIn = false;
    }

    if (!mounted) return;
    Navigator.pushReplacementNamed(context, loggedIn ? '/home' : '/signin');
  }

  @override
  Widget build(BuildContext context) {
    final logoScale = CurvedAnimation(parent: _intro, curve: Curves.elasticOut);
    final textFade = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0.45, 1, curve: Curves.easeOut),
    );

    return Scaffold(
      body: DecoratedBox(
        // The palette's wash: blue at the top, through aqua, into sage.
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.blue, AppColors.aqua, AppColors.sage],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ScaleTransition(
                scale: logoScale,
                child: Container(
                  padding: EdgeInsets.all(26.r),
                  decoration: BoxDecoration(
                    gradient: AppColors.sentGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.ink.withValues(alpha: 0.25),
                        blurRadius: 28,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Icon(Icons.storefront, size: 64.sp, color: Colors.white),
                ),
              ),
              SizedBox(height: 24.h),
              FadeTransition(
                opacity: textFade,
                child: Column(
                  children: [
                    CustomText(
                      text: 'NubDExchange',
                      fontSize: 26.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                    SizedBox(height: 28.h),
                    const SizedBox(
                      width: 26,
                      height: 26,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: AppColors.indigo,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
