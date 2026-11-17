enum AppErrorType {
  network,
  rateLimited,
  timeout,
  server,
  notFound,
  unknown,
}

class AppException implements Exception {
  const AppException(this.type, [this.message = '']);

  final AppErrorType type;
  final String message;

  @override
  String toString() =>
      'AppException($type${message.isEmpty ? '' : ': $message'})';
}
