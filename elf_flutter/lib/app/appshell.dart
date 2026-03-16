// app_shell.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elf_flutter/screens/chatScreen.dart';
import 'package:elf_flutter/screens/onboarding.dart';
import 'package:elf_flutter/screens/settings.dart';
import 'package:elf_flutter/provider/shellView.dart';

// Ensure the auth provider is initialised as soon as the shell mounts.
// This kicks off the silent session-restore check on startup.
import 'package:elf_flutter/provider/auth_state.dart';

class AppShell extends ConsumerStatefulWidget {


  const AppShell({super.key, });

  @override
  ConsumerState<AppShell> createState() => AppShellState();
}

class AppShellState extends ConsumerState<AppShell>
    with SingleTickerProviderStateMixin {

  @override
  void initState() {
    super.initState();
    // Read (not watch) just to ensure the provider is alive and the
    // session-restore future has started before the first frame.
    ref.read(authProvider);
  }

  Widget _buildPage(ShellView view) {
    switch (view) {
      case ShellView.chat:
        return const ChatScreen(key: ValueKey('chat'));
      case ShellView.onboarding:
        return OnboardingScreen(
          key: const ValueKey('onboarding'), 
        );
      case ShellView.settings:
        return const Settings(key: ValueKey('settings'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final view = ref.watch(shellViewProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: false,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        layoutBuilder: (current, previous) => Stack(
          children: [...previous, if (current != null) current],
        ),
        child: _buildPage(view),
      ),
    );
  }
}