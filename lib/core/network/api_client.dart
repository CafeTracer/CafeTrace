import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';
import '../errors/app_error.dart';

/// Singleton de Dio configurado con:
/// - Base URL configurable desde AppConstants
/// - Interceptor de autenticación JWT (agrega Authorization header automáticamente)
/// - Interceptor de errores (mapea DioException a AppError)
class ApiClient {
  ApiClient._();
  static final ApiClient _instance = ApiClient._();
  static ApiClient get instance => _instance;

  late final Dio _dio;
  final _storage = const FlutterSecureStorage();

  Dio get dio => _dio;

  void initialize() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: AppConstants.connectTimeout,
        receiveTimeout: AppConstants.receiveTimeout,
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      ),
    );

    _dio.interceptors.addAll([
      _AuthInterceptor(_storage),
      _ErrorInterceptor(),
      LogInterceptor(requestBody: true, responseBody: true, error: true),
    ]);
  }
}

/// Agrega el JWT a cada request que lo requiere.
class _AuthInterceptor extends Interceptor {
  final FlutterSecureStorage _storage;
  _AuthInterceptor(this._storage);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.read(key: AppConstants.jwtTokenKey);
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}

/// Mapea DioException a AppError para desacoplar infraestructura del dominio.
class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final appError = _map(err);
    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        error: appError,
        message: appError.message,
        type: err.type,
        response: err.response,
      ),
    );
  }

  AppError _map(DioException err) {
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError) {
      return const NetworkError();
    }

    final statusCode = err.response?.statusCode;
    final detail = err.response?.data?['detail'] ?? err.response?.data?['mensaje'];

    if (statusCode == null) return const UnknownError();

    return switch (statusCode) {
      400 => ValidationError(detail?.toString() ?? 'Datos inválidos.'),
      401 => const UnauthorizedError(),
      403 => const ForbiddenError(),
      404 => const NotFoundError(),
      409 => ConflictError(detail?.toString() ?? 'Registro duplicado.'),
      422 => ValidationError(
          detail?.toString() ?? 'Datos inválidos.',
          fieldErrors: _parseFieldErrors(err.response?.data),
        ),
      _ when statusCode >= 500 => const ServerError(),
      _ => const UnknownError(),
    };
  }

  Map<String, List<String>>? _parseFieldErrors(dynamic data) {
    if (data == null || data is! Map) return null;
    final detail = data['detail'];
    if (detail is! List) return null;
    final result = <String, List<String>>{};
    for (final item in detail) {
      if (item is Map) {
        final loc = (item['loc'] as List?)?.last?.toString() ?? 'campo';
        final msg = item['msg']?.toString() ?? 'Error';
        result.putIfAbsent(loc, () => []).add(msg);
      }
    }
    return result;
  }
}

/// Extrae AppError de un DioException para usarlo en providers.
AppError extractAppError(Object error) {
  if (error is DioException && error.error is AppError) {
    return error.error as AppError;
  }
  return const UnknownError();
}
