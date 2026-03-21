import 'dart:io';
import 'dart:async';

import 'package:elf_flutter/core/app_errors/error.dart';

AppError mapError(Object error) {
  if (error is SocketException) {
    return const AppError(
      AppErrorType.network,
      "No internet connection. Please check your network and try again.",
    );
  }

  if (error is TimeoutException) {
    return const AppError(
      AppErrorType.timeout,
      "The request timed out. Please try again.",
    );
  }

  final errorText = error.toString().toLowerCase();

  if (errorText.contains('429')) {
    return const AppError(
      AppErrorType.rateLimit,
      "Too many requests. Please wait a moment and try again.",
    );
  }

  if (errorText.contains('500') ||
      errorText.contains('502') ||
      errorText.contains('503')) {
    return const AppError(
      AppErrorType.server,
      "Something went wrong on our end. Please try again shortly.",
    );
  }

  return const AppError(
    AppErrorType.unknown,
    "Something unexpected happened. Please try again.",
  );
}