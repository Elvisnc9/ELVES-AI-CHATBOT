
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ShellView {onboarding, chat, settings, voicechat}

final shellViewProvider =
    StateProvider<ShellView>((ref) => ShellView.chat);
