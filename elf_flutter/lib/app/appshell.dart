// app_shell.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elf_flutter/screens/chatScreen.dart';
import 'package:elf_flutter/screens/onboarding.dart';
import 'package:elf_flutter/screens/settings.dart';
import 'package:elf_flutter/provider/shellView.dart';
import 'package:elf_flutter/provider/auth_state.dart';
import 'package:elf_flutter/widgets/elvesDrawer.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => AppShellState();
}

class AppShellState extends ConsumerState<AppShell> {
  // initialPage: 1 → chat is the landing screen; page 0 is the drawer
  final PageController _pageController = PageController(initialPage: 1);

  @override
  void initState() {
    super.initState();
    ref.read(authProvider); // kick off silent session-restore
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void openDrawer() {
    _pageController.animateToPage(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  void closeDrawer() {
    _pageController.animateToPage(
      1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final view = ref.watch(shellViewProvider);

    // Settings and Onboarding fully replace the PageView —
    // no overlay, no see-through.
    if (view == ShellView.settings) {
      return const Scaffold(
        body: Settings(key: ValueKey('settings')),
      );
    }

    if (view == ShellView.onboarding) {
      return const Scaffold(
        body: OnboardingScreen(key: ValueKey('onboarding')),
      );
    }

    // ShellView.chat → PageView with drawer at 0, chat at 1
    return Scaffold(
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: false,
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          // Page 0 — Drawer
          ElvesDrawerPage(
            pageController: _pageController,
            onClose: closeDrawer,
          ),
          // Page 1 — Chat
          ChatScreen(
            key: const ValueKey('chat'),
            openDrawer: openDrawer,
            pageController: _pageController,
          ),
        ],
      ),
    );
  }
}