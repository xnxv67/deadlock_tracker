class ApiConstants {
  const ApiConstants._();

  static const String baseUrl = 'https://api.deadlock-api.com/v1';

  static const Duration connectTimeout = Duration(seconds: 20);
  static const Duration receiveTimeout = Duration(seconds: 60);
}
