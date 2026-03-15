// app_shell.dart
import 'package:elf_flutter/screens/voicehat.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elf_flutter/screens/chatScreen.dart';
import 'package:elf_flutter/screens/onboarding.dart';
import 'package:elf_flutter/screens/settings.dart';
import 'package:elf_flutter/provider/shellView.dart';

class AppShell extends ConsumerStatefulWidget {
  final Widget robot;

  const AppShell({super.key, required this.robot});

  @override
  ConsumerState<AppShell> createState() => AppShellState();
}

class AppShellState extends ConsumerState<AppShell>
    with SingleTickerProviderStateMixin {




  Widget _buildPage(ShellView view) {
    switch (view) {
      case ShellView.chat:
        return const ChatScreen(key: ValueKey('chat'));
      case ShellView.onboarding:
        return OnboardingScreen(
          key: const ValueKey('onboarding'), onStart: () {  },
         
        );
        case ShellView.voicechat:
        return VoiceChatOverlay(key: ValueKey('voiceChat'));
    
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
      
     
      
      
           // Fix AnimatedSwitcher touch passthrough
AnimatedSwitcher(
  duration: const Duration(milliseconds: 250),
  layoutBuilder: (current, previous) => Stack(
    children: [...previous, if (current != null) current],
  ),
  child: _buildPage(view),
),
        ],
      ),
    );
  }
}
