// ignore_for_file: avoid_print, non_constant_identifier_names

import 'dart:async';
import 'package:elf_flutter/provider/shellView.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:the_responsive_builder/the_responsive_builder.dart';

import 'package:elf_flutter/shared/theme.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  final VoidCallback? onStart;
  const OnboardingScreen({super.key, required this.onStart});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late PageController _pageController;
  int currentPage = 0;
  late Timer _autoScrollTimer;
  bool _isloading = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _pageController.addListener(() {
      setState(() {
        currentPage = _pageController.page?.round() ?? 0;
      });
    });
    _startAutoScroll();
  }

  @override
  void dispose() {
    _autoScrollTimer.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_pageController.hasClients) {
        int nextPage = (currentPage + 1) % 4;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;

    final pages = [
      _PageData(
        title: 'Evolving Intelligence',
        title2: 'Built Simply',
        title3: 'Powered AI',
        subtext: 'Fast, adaptive intelligence designed to\n work naturally for you.',
      ),
      _PageData(
        title: 'Brain AI',
        title2: 'Get Answers',
        title3: 'Smart Support',
        subtext: 'Get intelligent help anytime you need it.',
      ),
      _PageData(
        title: 'Work Smarter',
        title2: 'Less Effort',
        title3: 'Better Effort',
        subtext: 'Natural conversations\n powered by intelligent understanding.',
      ),
      _PageData(
        title: 'Create Faster',
        title2: 'Think Bigger',
        title3: 'AI Powered',
        subtext: 'Let AI handle tasks\n while you focus on what matters.',
      ),
    ];

    return SafeArea(
      child: Column(
        children: [
          // ── Ghost / skip button ─────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Align(
              alignment: Alignment.topRight,
              child: GestureDetector(
                onTap: () {
                  ref.read(shellViewProvider.notifier).state = ShellView.chat;
                },
                child: Image.asset(
                  'assets/ghost.png',
                  height: 30,
                  width: 20,
                  color: theme.splashColor,
                )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .moveY(begin: -5, end: 5, duration: 2.seconds),
              ),
            ),
          ),

          // ── Space that mirrors where the robot ends in AppShell ─
          // AppShell positions the robot at top: screenHeight * 0.009,
          // scaled at 0.45 → effective height ≈ 500 * 0.45 = 225px.
          // We leave that space so content starts below the robot.
          SizedBox(height: screenHeight * 0.30),

          // ── Page slides (text content) ──────────────────────
          // Uses Flexible so it never overflows on short phones.
          Flexible(
            child: PageView.builder(
              controller: _pageController,
              itemCount: pages.length,
              itemBuilder: (context, idx) => PageSlider(
                data: pages[idx],
                key: ValueKey(idx),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ── Dot indicators ──────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              pages.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                margin: EdgeInsets.symmetric(horizontal: 0.5.w),
                width: currentPage == index ? 3.w : 2.w,
                height: 0.8.h,
                decoration: BoxDecoration(
                  color: currentPage == index
                      ? theme.cardColor
                      : theme.canvasColor.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ── Google Login Button ─────────────────────────────
          AnimatedGoogleButton(
            logo: _isloading
                ? const SizedBox(
                    width: 30,
                    height: 30,
                    child: Indicator(),
                  )
                : Image.asset('assets/google_Logo.png', width: 30),
            onTap: () async {
              if (_isloading) return;
              setState(() => _isloading = true);
              try {
                await Future.delayed(const Duration(seconds: 3));
                if (!mounted) return;
              } catch (e, stack) {
                print('Google sign-in failed: $e');
                print(stack);
              } finally {
                if (mounted) setState(() => _isloading = false);
              }
            },
          ),

          const SizedBox(height: 14),

          // ── Legal text ──────────────────────────────────────
          Text(
            "By logging in you accept our privacy policy",
            style: TextStyle(
              fontSize: 11,
              color: theme.secondaryHeaderColor.withOpacity(0.5),
            ),
          ).animate().fadeIn(delay: 1400.ms),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  DATA MODEL  (replaces unnamed positional args)
// ─────────────────────────────────────────────

class _PageData {
  final String title;
  final String title2;
  final String title3;
  final String subtext;

  const _PageData({
    required this.title,
    required this.title2,
    required this.title3,
    required this.subtext,
  });
}

// ─────────────────────────────────────────────
//  PAGE SLIDER
//  • Uses ClipRect + slideY per line instead of
//    per-character Text widgets — ~10× fewer widgets,
//    no frame drops on mid-range Android.
// ─────────────────────────────────────────────

class PageSlider extends StatelessWidget {
  const PageSlider({super.key, required this.data});

  final _PageData data;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final theme = Theme.of(context);

    return Padding(
      // Horizontal breathing room on all phones
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Line 1
          _RevealLine(
            text: data.title,
            style: textTheme.displayLarge?.copyWith(
              fontSize: 30.sp,
              color: theme.secondaryHeaderColor,
              fontWeight: FontWeight.w800,
            ),
            delay: Duration.zero,
          ),

          // Line 2  (accent + shimmer)
          GlowShader(
            child: _RevealLine(
              text: data.title2,
              style: textTheme.displayLarge?.copyWith(
                fontSize: 44.sp,
                color: AppColors.accent,
                fontWeight: FontWeight.bold,
              ),
              delay: 120.ms,
            ),
          ),

          // Line 3
          _RevealLine(
            text: data.title3,
            style: textTheme.displayLarge?.copyWith(
              fontSize: 34.sp,
              color: theme.secondaryHeaderColor,
              fontWeight: FontWeight.w800,
            ),
            delay: 240.ms,
          ),

          const SizedBox(height: 8),

          // Sub-text
          Text(
            data.subtext,
            textAlign: TextAlign.center,
            style: textTheme.labelMedium?.copyWith(
              height: 1.7,
              fontWeight: FontWeight.w300,
              fontSize: 11.sp,
              color: theme.secondaryHeaderColor.withOpacity(0.5),
            ),
          )
              .animate()
              .fadeIn(delay: 400.ms)
              .slideY(begin: 0.3, duration: 350.ms),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  REVEAL LINE  (replaces AnimatedTextReveal)
//  One widget per line, not one per character.
// ─────────────────────────────────────────────

class _RevealLine extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final Duration delay;

  const _RevealLine({
    required this.text,
    required this.style,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Text(text, style: style, textAlign: TextAlign.center)
          .animate()
          .slideY(
            begin: 0.8,
            end: 0,
            delay: delay,
            duration: 380.ms,
            curve: Curves.easeOutCubic,
          )
          .fadeIn(delay: delay, duration: 300.ms),
    );
  }
}

// ─────────────────────────────────────────────
//  GOOGLE BUTTON  (unchanged, kept identical)
// ─────────────────────────────────────────────

class AnimatedGoogleButton extends StatelessWidget {
  final VoidCallback onTap;
  final Widget logo;
  const AnimatedGoogleButton({
    super.key,
    required this.onTap,
    required this.logo,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 60,
        margin: const EdgeInsets.symmetric(horizontal: 28),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: const LinearGradient(
            colors: [Colors.black38, Colors.white12],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            logo,
            SizedBox(width: 3.w),
            Text(
              "Login with Google",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).secondaryHeaderColor,
              ),
            ),
          ],
        ),
      )
          .animate()
          .slideY(begin: 0.6, delay: 1200.ms)
          .fadeIn()
          .scaleXY(begin: 0.9, end: 1, curve: Curves.easeOutBack)
          .then()
          .shimmer(duration: 1500.ms),
    );
  }
}

// ─────────────────────────────────────────────
//  GLOW SHADER  (unchanged)
// ─────────────────────────────────────────────

class GlowShader extends StatelessWidget {
  final Widget child;
  final List<Color> colors;
  final Duration duration;

  const GlowShader({
    super.key,
    required this.child,
    this.colors = const [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
    this.duration = const Duration(seconds: 4),
  });

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => LinearGradient(
        colors: colors,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(bounds),
      blendMode: BlendMode.srcATop,
      child: child
          .animate(onPlay: (c) => c.repeat())
          .shimmer(duration: duration),
    );
  }
}

// ─────────────────────────────────────────────
//  INDICATOR  (unchanged)
// ─────────────────────────────────────────────

class Indicator extends StatelessWidget {
  const Indicator({super.key});

  @override
  Widget build(BuildContext context) {
    return CircularProgressIndicator(
      color: AppColors.light,
      strokeWidth: 4,
    );
  }
}