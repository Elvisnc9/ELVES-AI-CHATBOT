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
  late Animation<double> _rotationY;
  late Animation<double> _offsetY;

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
          tween: Tween(begin: 1.0, end: 1.8).chain(CurveTween(curve: Curves.easeInOut)), 
          weight: 40),
      TweenSequenceItem(
          tween: Tween(begin: 1.8, end: 0.6).chain(CurveTween(curve: Curves.easeInOut)), 
          weight: 60),
    ]).animate(_controller);

    // Rotation 360°
    _rotationY = Tween<double>(begin: 0, end: 2 * 3.14159)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    // Vertical offset
    _offsetY = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -40.0), weight: 50),
  TweenSequenceItem(tween: Tween(begin: -40.0, end: 0.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
  }

  Future<void> startTransition(ShellView target) async {
    if (_isAnimating) return;
    _isAnimating = true;

    _controller.forward(from: 0);

    // Switch page mid-animation
    Future.delayed(const Duration(milliseconds: 400), () {
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
        return 0.6;
      case ShellView.chat:
        return 0.45;
      default:
        return 0;
    }
  }

  double _defaultTop(ShellView view, double screenHeight) {
    switch (view) {
      case ShellView.onboarding:
        return screenHeight * 0.009;
      case ShellView.home:
        return screenHeight * 0.2;
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
          onStart: () => startTransition(ShellView.home),
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
      body: SafeArea(
        child: Stack(
          children: [
            // Pages
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _buildPage(view),
            ),

            // Robot
            if (view != ShellView.settings)
              AnimatedBuilder(
                animation: _controller,
                builder: (_, child) {
                  final scale = _isAnimating ? _scale.value : _defaultScale(view);
                  final topPosition =
                      _defaultTop(view, screenHeight) + (_isAnimating ? _offsetY.value : 0);

                  return Positioned(
                    top: topPosition,
                    left: (screenWidth - 500) / 2, // center horizontally
                    child: Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..scale(scale)
                        ..rotateY(_isAnimating ? _rotationY.value : 0),
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
          ],
        ),
      ),
    );
  }
}
