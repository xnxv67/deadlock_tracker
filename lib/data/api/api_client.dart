import 'package:dio/dio.dart';

import '../../core/constants/api_constants.dart';
import '../../core/error/app_exception.dart';

/// Тонкая обёртка над Dio для запросов к Deadlock API.
///
/// Приводит сетевые ошибки Dio к доменному [AppException], чтобы BLoC и UI
/// работали с понятными типами (`timeout`, `network`, `server` и т.д.),
/// а не с деталями HTTP-клиента.
class ApiClient {
  ApiClient({Dio? dio, String baseUrl = ApiConstants.baseUrl})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: baseUrl,
              connectTimeout: ApiConstants.connectTimeout,
              receiveTimeout: ApiConstants.receiveTimeout,
              headers: const {'Accept': 'application/json'},
              responseType: ResponseType.json,
            ),
          );

  final Dio _dio;

  /// Доступ к настроенному клиенту для нестандартных запросов.
  Dio get dio => _dio;

  /// GET-запрос, возвращающий JSON-массив.
  Future<List<dynamic>> getList(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    final data = await _get(path, query: query);
    if (data is List) {
      return data;
    }
    throw const AppException(
      AppErrorType.unknown,
      'Ожидался JSON-массив в ответе API',
    );
  }

  /// GET-запрос, возвращающий JSON-объект.
  Future<Map<String, dynamic>> getMap(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    final data = await _get(path, query: query);
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    throw const AppException(
      AppErrorType.unknown,
      'Ожидался JSON-объект в ответе API',
    );
  }

  Future<dynamic> _get(String path, {Map<String, dynamic>? query}) async {
    try {
      final response = await _dio.get<dynamic>(
        path,
        queryParameters: query,
      );
      return response.data;
    } on DioException catch (error) {
      throw _mapError(error);
    } on AppException {
      rethrow;
    } catch (error) {
      throw AppException(AppErrorType.unknown, error.toString());
    }
  }

  /// Переводит [DioException] в [AppException] с доменным типом ошибки.
  AppException _mapError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return const AppException(AppErrorType.timeout);
      case DioExceptionType.connectionError:
      case DioExceptionType.badCertificate:
        return const AppException(AppErrorType.network);
      case DioExceptionType.badResponse:
        final code = error.response?.statusCode ?? 0;
        if (code == 429) {
          return const AppException(AppErrorType.rateLimited);
        }
        if (code == 404) {
          return const AppException(AppErrorType.notFound);
        }
        if (code >= 500) {
          return const AppException(AppErrorType.server);
        }
        return AppException(AppErrorType.unknown, 'HTTP $code');
      case DioExceptionType.cancel:
        return const AppException(
          AppErrorType.unknown,
          'Запрос был отменён',
        );
      case DioExceptionType.unknown:
        return const AppException(AppErrorType.network);
    }
  }
}
