import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import 'login_screen.dart';

/// Animated Splash Screen.
/// Shows the splash_logo.png with a 3-stage animation sequence:
///   1. Logo fades + scales in
///   2. App name slides up and fades in
///   3. Tagline fades in
/// Then auto-navigates to LoginScreen after ~3 seconds.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // ── Logo: fade + scale ────────────────────────────────────────────────────
  late final AnimationController _logoController;
  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;

  // ── App name: slide up + fade ─────────────────────────────────────────────
  late final AnimationController _titleController;
  late final Animation<double> _titleFade;
  late final Animation<Offset> _titleSlide;

  // ── Tagline: fade in ──────────────────────────────────────────────────────
  late final AnimationController _taglineController;
  late final Animation<double> _taglineFade;

  // ── Loading bar ───────────────────────────────────────────────────────────
  late final AnimationController _barController;
  late final Animation<double> _barProgress;

  @override
  void initState() {
    super.initState();

    // 1. Logo animates in over 900ms
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeIn),
    );
    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    // 2. Title slides up after 700ms, over 600ms
    _titleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _titleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _titleController, curve: Curves.easeIn),
    );
    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _titleController, curve: Curves.easeOut),
    );

    // 3. Tagline fades in after 1200ms, over 500ms
    _taglineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _taglineFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _taglineController, curve: Curves.easeIn),
    );

    // 4. Progress bar fills over 2500ms (starts immediately)
    _barController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
    _barProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _barController, curve: Curves.easeInOut),
    );

    // ── Kick off the sequence ─────────────────────────────────────────────
    _runAnimationSequence();
  }

  Future<void> _runAnimationSequence() async {
    // Start bar immediately
    _barController.forward();

    // Logo appears right away
    await _logoController.forward();

    // Title slides up after a short pause
    await Future.delayed(const Duration(milliseconds: 100));
    await _titleController.forward();

    // Tagline fades in
    await Future.delayed(const Duration(milliseconds: 150));
    _taglineController.forward();

    // Wait for the full branded moment, then navigate
    await Future.delayed(const Duration(milliseconds: 1400));

    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const LoginScreen(),
          transitionDuration: const Duration(milliseconds: 600),
          transitionsBuilder: (_, animation, __, child) {
            // Fade-through transition into Login
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _titleController.dispose();
    _taglineController.dispose();
    _barController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.bgGradientStart, AppColors.bgGradientEnd],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Main centred content ──────────────────────────────────
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ── Animated logo ───────────────────────────────
                      AnimatedBuilder(
                        animation: _logoController,
                        builder: (_, __) => FadeTransition(
                          opacity: _logoFade,
                          child: ScaleTransition(
                            scale: _logoScale,
                            child: Container(
                              width: 130,
                              height: 130,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.08),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.4),
                                    blurRadius: 40,
                                    spreadRadius: 10,
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(18),
                              child: Image.asset(
                                'assets/splash/splash_logo.png',
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.account_balance_wallet_outlined,
                                  size: 72,
                                  color: Colors.white70,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // ── Animated app name ───────────────────────────
                      SlideTransition(
                        position: _titleSlide,
                        child: FadeTransition(
                          opacity: _titleFade,
                          child: Text(
                            'SmartFinance AI',
                            style: AppTextStyles.heading.copyWith(
                              fontSize: 30,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // ── Animated tagline ────────────────────────────
                      FadeTransition(
                        opacity: _taglineFade,
                        child: Text(
                          'Your AI-powered money companion',
                          style: AppTextStyles.body.copyWith(
                            color: Colors.white.withValues(alpha: 0.55),
                            fontSize: 14,
                            letterSpacing: 0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Animated loading bar at the bottom ───────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(40, 0, 40, 48),
                child: Column(
                  children: [
                    AnimatedBuilder(
                      animation: _barProgress,
                      builder: (_, __) => ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: _barProgress.value,
                          minHeight: 3,
                          backgroundColor: Colors.white.withValues(alpha: 0.1),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FadeTransition(
                      opacity: _taglineFade,
                      child: Text(
                        'Loading your finances...',
                        style: AppTextStyles.body.copyWith(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.35),
                        ),
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
