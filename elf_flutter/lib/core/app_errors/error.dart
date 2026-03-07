enum AppErrorType {
  network,
  timeout,
  rateLimit,
  server,
  unknown,
}

class AppError {
  final AppErrorType type;
  final String message;

  const AppError(this.type, this.message);
}


