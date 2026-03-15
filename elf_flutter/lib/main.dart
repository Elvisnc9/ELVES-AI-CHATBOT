import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:serverpod_flutter/serverpod_flutter.dart';
import 'package:the_responsive_builder/the_responsive_builder.dart';

import 'package:elf_client/elf_client.dart';
import 'package:elf_flutter/app/appshell.dart';
import 'package:elf_flutter/shared/theme.dart';
import 'package:elf_flutter/widgets/robot.dart';


late Client client;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
  const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
  ),
);
const String serverUrl = 'http://172.29.87.254:8080/';
 client  = Client(serverUrl) 
    ..connectivityMonitor = FlutterConnectivityMonitor();
 runApp(
    ProviderScope(
      child: TheResponsiveBuilder(builder: (context, orientation, screenType) {
        return const MyApp();
      }),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeControllerProvider);

    return AnimatedTheme(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeIn,
      data: themeMode == ThemeMode.dark
          ? AppTheme.darkTheme
          : AppTheme.light,
      child: MaterialApp(
        title: 'ELF',
        theme: AppTheme.light,
        themeMode: themeMode,
        darkTheme: AppTheme.darkTheme,
        home: AppShell(robot: Robot(),),
      ),
    ) .animate(key: ValueKey(themeMode))
        .fadeIn(duration: const Duration(milliseconds: 500))
        .scale(begin: const Offset(0.98, 0.98), end: const Offset(1.0, 1.0));
  }
}

