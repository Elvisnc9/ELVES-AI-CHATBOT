// app_shell.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elf_flutter/screens/chatScreen.dart';
import 'package:elf_flutter/screens/home.dart';
import 'package:elf_flutter/screens/onboarding.dart';
import 'package:elf_flutter/screens/settings.dart';
import 'package:elf_flutter/state/shellView.dart';

class AppShell extends ConsumerStatefulWidget {
  final Widget robot;

  const AppShell({super.key, required this.robot});

  @override
  ConsumerState<AppShell> createState() => AppShellState();
}

class AppShellState extends ConsumerState<AppShell>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // Scale animation
    _scale = TweenSequence([
      TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 1.2).chain(CurveTween(curve: Curves.easeIn)), 
          weight: 40),
      TweenSequenceItem(
          tween: Tween(begin: 1.4, end: 0.6).chain(CurveTween(curve: Curves.easeOut)), 
          weight: 60),
    ]).animate(_controller);

    // Rotation 360°
   

  }

  Future<void> startTransition(ShellView target) async {
    if (_isAnimating) return;
    _isAnimating = true;

    _controller.forward(from: 0);

    // Switch page mid-animation
    Future.delayed(const Duration(milliseconds: 900), () {
      ref.read(shellViewProvider.notifier).state = target;
    });

    await _controller.forward();
    _isAnimating = false;
  }

  double _defaultScale(ShellView view) {
    switch (view) {
      case ShellView.onboarding:
        return 1.0;
      case ShellView.home:
        return 0.8;
      case ShellView.chat:
        return 0.45;
      default:
        return 0;
    }
  }

  double _defaultLeft(ShellView view, double screenWidth) {
  switch (view) {
    case ShellView.onboarding:
      // Center horizontally
      return (screenWidth - 500) / 2;

    case ShellView.home:
      // Stick to left edge
      return 0;

    case ShellView.chat:
      return 20; // example position for chat

    default:
      return 0;
  }
}

  double _defaultTop(ShellView view, double screenHeight) {
    switch (view) {
      case ShellView.onboarding:
        return screenHeight * 0.009;
      case ShellView.home:
        return screenHeight * 0.05;
      case ShellView.chat:
        return screenHeight * 0.15;
      default:
        return 0.0;
    }
  }

  Widget _buildPage(ShellView view) {
    switch (view) {
      case ShellView.chat:
        return const ChatView(key: ValueKey('chat'));
      case ShellView.onboarding:
        return OnboardingScreen(
          key: const ValueKey('onboarding'),
          onStart: () => startTransition(ShellView.chat),
        );
      case ShellView.home:
        return const HomeView(key: ValueKey('home'));
      case ShellView.settings:
        return const Settings(key: ValueKey('settings'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final view = ref.watch(shellViewProvider);
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Pages
      
          // Robot
          if (view != ShellView.settings)
            AnimatedBuilder(
              animation: _controller,
              builder: (_, child) {
                final scale = _isAnimating ? _scale.value : _defaultScale(view);
                final topPosition =
                    _defaultTop(view, screenHeight) ;
      
                return Positioned(
                  top: topPosition,
                  left: _defaultLeft(view, screenWidth),
       // center horizontally
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..scale(scale),
                    child: SizedBox(
                      width: 500,
                      height: 500,
                      child: child,
                    ),
                  ),
                );
              },
              child: widget.robot,
            ),
      
      
              AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _buildPage(view),
          ),
        ],
      ),
    );
  }
}
