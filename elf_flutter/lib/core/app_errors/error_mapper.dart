
import 'dart:io';
import 'dart:async';

import 'package:elf_flutter/core/app_errors/error.dart';


AppError mapError(Object error) {

  if (error is SocketException) {
    return const AppError(
      AppErrorType.network,
      "📡 I can't reach the internet. Please check your connection.",
    );
  }

  if (error is TimeoutException) {
    return const AppError(
      AppErrorType.timeout,
      "🐢 The connection is very slow. Please try again.",
    );
  }

  final errorText = error.toString().toLowerCase();

  if (errorText.contains('429')) {
    return const AppError(
      AppErrorType.rateLimit,
      "⚠️ I'm getting too many requests right now. Please wait a moment.",
    );
  }

  if (errorText.contains('500')) {
    return const AppError(
      AppErrorType.server,
      "⚠️ Something went wrong on the server. Please try again.",
    );
  }

  return const AppError(
    AppErrorType.unknown,
    "⚠️ Something unexpected happened. Please try again.",
  );
}
