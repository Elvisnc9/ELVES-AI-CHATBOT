enum AppErrorType {
  network,
  slowConnection,
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


