import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/auth_providers.dart';
import '../../../core/router/app_router.dart';
import '../models/auth_state.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _logoController;
  late final AnimationController _textController;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<double> _textFade;
  late final Animation<Offset> _textSlide;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _navigate();
  }

  void _initAnimations() {
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
    _textController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );

    _logoScale = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );
    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOut),
    );
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOut),
    );

    _logoController.forward().then((_) => _textController.forward());
  }

  Future<void> _navigate() async {
    // Wait for both the minimum splash duration AND auth initialization to finish
    await Future.wait([
      Future.delayed(const Duration(milliseconds: 2800)),
      ref.read(authNotifierProvider.notifier).initFuture,
    ]);
    if (!mounted) return;
    final authState = ref.read(authNotifierProvider);
    if (authState is AuthAuthenticated) {
      try {
        await ref
            .read(userProfileNotifierProvider.notifier)
            .loadProfile(authState.token);
      } catch (_) {
        // Profile load failure is non-fatal — estate selection handles errors
      }
      if (mounted) context.go(AppRoutes.estateSelection);
    } else {
      context.go(AppRoutes.login);
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.splashGradient),
        child: SafeArea(
          child: Stack(
            children: [
              // Decorative background leaves
              Positioned(
                top: -40,
                right: -50,
                child: Opacity(
                  opacity: 0.07,
                  child: Icon(Icons.eco_rounded, size: 220, color: Colors.white),
                ),
              ),
              Positioned(
                bottom: 80,
                left: -50,
                child: Opacity(
                  opacity: 0.05,
                  child: Icon(Icons.eco_rounded, size: 180, color: Colors.white),
                ),
              ),
              Positioned(
                top: 200,
                left: -30,
                child: Opacity(
                  opacity: 0.04,
                  child: Icon(Icons.eco_rounded, size: 100, color: Colors.white),
                ),
              ),
              // Main content
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FadeTransition(
                      opacity: _logoFade,
                      child: ScaleTransition(
                        scale: _logoScale,
                        child: _Logo(),
                      ),
                    ),
                    const SizedBox(height: 36),
                    SlideTransition(
                      position: _textSlide,
                      child: FadeTransition(
                        opacity: _textFade,
                        child: Column(
                          children: [
                            Text(
                              'TeaState',
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 44,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'ESTATE  MANAGEMENT',
                              style: GoogleFonts.dmSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w300,
                                color: Colors.white.withValues(alpha: 0.75),
                                letterSpacing: 5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Loader at bottom
              Positioned(
                bottom: 56,
                left: 0,
                right: 0,
                child: FadeTransition(
                  opacity: _textFade,
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white.withValues(alpha: 0.55),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 112,
      height: 112,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(36),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.38),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 32,
            spreadRadius: 4,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: const Icon(Icons.eco_rounded, color: Colors.white, size: 62),
    );
  }
}
