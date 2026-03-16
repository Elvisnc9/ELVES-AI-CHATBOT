
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ShellView {onboarding, chat, settings,}

final shellViewProvider =
    StateProvider<ShellView>((ref) => ShellView.chat);
