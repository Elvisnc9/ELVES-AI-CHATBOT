// ignore_for_file: avoid_print, non_constant_identifier_names

import 'dart:async';

import 'package:another_flushbar/flushbar.dart';
import 'package:elf_client/elf_client.dart';
// import 'package:elf_flutter/widgets/robot.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';
// import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';
import 'package:the_responsive_builder/the_responsive_builder.dart';
// import 'package:video_player/video_player.dart';

import 'package:elf_flutter/shared/theme.dart';
// import 'package:elf_flutter/state/shellView.dart';



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
    _pageController.dispose(); // Dispose video controller
    super.dispose();
  }

  void _startAutoScroll() {
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_pageController.hasClients) {
        int nextPage = (currentPage + 1) % 4; // 4 is the number of pages
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
    //  final textTheme = Theme.of(context).textTheme;
    final theme = Theme.of(context);

    final pages = [
      PageSlider(
        Title: ' Evolving Intelligence',
        Title2: 'Built Simply',
        Title3: 'Powered AI',
        Subtext:
            'Fast, adaptive intelligence designed to\n work naturally for you.',
      ),
      PageSlider(
        Title: 'Brain AI',
        Title2: 'Get Answers',
        Title3: 'Smart Support',
        Subtext: 'Get intelligent help anytime you need it.',
      ),
      PageSlider(
        Title: 'Work Smarter',
        Title2: 'Less Effort',
        Title3: 'Better Effort',
        Subtext:
            'Natural conversations\n powered by intelligent understanding.',
      ),
      PageSlider(
        Title: 'Create Faster',
        Title2: 'Think Bigger',
        Title3: 'AI Powered',
        Subtext: 'Let AI handle tasks\n while you focus on what matters.',
      ),
    ];

    return Column(
      children: [
      
    
       SizedBox(
      height: 55.h,
      
    ),
    
    
    
        /// TEXT
        SizedBox(
          height: 28.h,
          child: PageView.builder(
            controller: _pageController,
            itemCount: pages.length,
            itemBuilder: (context, idx) => PageSlider(
              Title: pages[idx].Title,
              Title2: pages[idx].Title2,
              Title3: pages[idx].Title3,
              Subtext: pages[idx].Subtext,
            ),
          ),
        ),
    
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          
          children: List.generate(
            pages.length,
            (index) => Container(
              margin: EdgeInsets.symmetric(horizontal: 0.5.w),
              width: currentPage == index ? 3.w : 2.w,
              height: 0.8.h,
              decoration: BoxDecoration(
                color: currentPage == index
                    ? theme.cardColor
                    : theme.canvasColor.withOpacity(0.5),
                borderRadius: BorderRadius.circular(10),
              ),
            ).animate().fadeIn(),
          ),
        ),
    
        SizedBox(height: 2.h,),
      AnimatedGoogleButton(
      logo: _isloading
          ? Indicator()
          : Image.asset(
      'assets/google_Logo.png',
      width: 30,
    ),
      onTap: () async {
        if (_isloading) return;
    
        setState(() {
          _isloading = true;
        });
    
        try {
       
    
          // final controller = ref.read(googleAuthControllerProvider);
          // await controller.signIn();
    
        
    
          // Optional: If your controller exposes the Google user / ID token,
          // print it here. Example if you can access it:
          // final googleUser = controller.currentUser; // or similar
          // print('Google ID Token: ${googleUser?.idToken}');
          // print('Google Access Token: ${googleUser?.accessToken}');
    
          // await ref.read(authNotifierProvider.notifier).onSignInCompleted();
    
          // ✅ SUCCESS FLUSHBAR
    //       Flushbar(
    // message: 'Sign-In Successfully',
    // icon: const Icon(Icons.check, color: Colors.green),
    // duration: const Duration(seconds: 3),
    // flushbarPosition: FlushbarPosition.BOTTOM,
    // flushbarStyle: FlushbarStyle.FLOATING,
    // margin: const EdgeInsets.all(16),
    // borderRadius: BorderRadius.circular(12),
    //       ).show(context);
    
          await Future.delayed(const Duration(seconds: 3));
    
          if (!mounted) return;
    
    widget.onStart?.call();
        } catch (e, stack) {
          print('Google sign-in failed with error:');
          print(e);
          print('Stack trace:');
          print(stack);
        } finally {
          if (mounted) {
    setState(() {
      _isloading = false;
    });
          }
          print('Sign-in flow ended (loading = false)');
        }
      },
    ),
    
    
    
    
        const SizedBox(height: 14),
    
        Text(
          "By logging in you accept our privacy policy",
          style: TextStyle(
            fontSize: 11,
            color: theme.secondaryHeaderColor.withOpacity(0.5),
          ),
        ).animate().fadeIn(delay: 1400.ms),
    
        const SizedBox(height: 20),
      ],
    );
  }
}

class PageSlider extends StatelessWidget {
  const PageSlider({
    super.key,
    required this.Title,
    required this.Title2,
    required this.Title3,
    required this.Subtext,
  });

  final String Title;
  final String Title2;
  final String Title3;
  final String Subtext;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final theme = Theme.of(context);
    return Column(
      children: [
        AnimatedTextReveal(
          text: Title,
          size: 35.sp,
          color: theme.secondaryHeaderColor,
          weight: FontWeight.w800,
        ),
        GlowShader(
          child: AnimatedTextReveal(
            text: Title2,
            delay: 300.ms,
            size: 50.sp,
            color: AppColors.accent,
            weight: FontWeight.bold,
          ),
        ),
        AnimatedTextReveal(
          text: Title3,
          delay: 500.ms,
          size: 40.sp,
          color: theme.secondaryHeaderColor,
          weight: FontWeight.w800,
        ),
        const SizedBox(height: 5),
        Text(Subtext,
                textAlign: TextAlign.center,
                style: textTheme.labelMedium?.copyWith(
                    height: 1.7,
                    fontWeight: FontWeight.w100,
                    fontSize: 12.sp,
                    color: theme.secondaryHeaderColor.withOpacity(0.5)))
            .animate()
            .fadeIn(delay: 1.seconds)
            .slideY(begin: 0.4),
      ],
    );
  }
}

class AnimatedGoogleButton extends StatelessWidget {
  final VoidCallback onTap;
  final Widget logo;
  const AnimatedGoogleButton(
      {super.key, required this.onTap, required this.logo});

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

class AnimatedTextReveal extends StatelessWidget {
  final String text;
  final Duration delay;
  final double size;
  final Color color;
  final FontWeight weight;

  const AnimatedTextReveal(
      {super.key,
      required this.text,
      this.delay = Duration.zero,
      required this.size,
      required this.color,
      required this.weight});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Wrap(
      alignment: WrapAlignment.center,
      children: List.generate(
        text.length,
        (index) => Text(
          text[index],
          style: textTheme.displayLarge?.copyWith(
              fontSize: size, color: color, height: 1.3, fontWeight: weight),
        )
            .animate()
            .fadeIn(
              delay: delay + (100.ms * index),
              duration: 300.ms,
            )
            .slideX(begin: 0.9),
      ),
    );
  }
}



class GlowShader extends StatelessWidget {
  final Widget child;
  final List<Color> colors;
  final Duration duration;

  const GlowShader({
    super.key,
    required this.child,
    this.colors = const [
      Color(0xFF8E2DE2),
      Color(0xFF4A00E0),
    ],
    this.duration = const Duration(seconds: 4),
  });

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) {
        return LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(bounds);
      },
      blendMode: BlendMode.srcATop,
      child:
          child.animate(onPlay: (c) => c.repeat()).shimmer(duration: duration),
    );
  }
}

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

