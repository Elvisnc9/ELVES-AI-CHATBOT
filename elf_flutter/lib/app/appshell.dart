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

  Widget _buildOverlayView(ShellView view) {
    switch (view) {
      case ShellView.onboarding:
        return OnboardingScreen(key: const ValueKey('onboarding'));
      case ShellView.settings:
        return Settings(key: const ValueKey('settings'));
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final view = ref.watch(shellViewProvider);
    final showOverlay = view == ShellView.onboarding || view == ShellView.settings;

    return Scaffold(
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // ── PageView: [DrawerPage, ChatScreen] ─────────────────────────
          PageView(
            controller: _pageController,
            // All gesture control is manual — we drive the PageController
            // ourselves from GestureDetectors inside each page.
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

          // ── Onboarding / Settings overlay ──────────────────────────────
          if (showOverlay)
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              layoutBuilder: (current, previous) => Stack(
                children: [...previous, if (current != null) current],
              ),
              child: _buildOverlayView(view),
            ),
        ],
      ),
    );
  }
}