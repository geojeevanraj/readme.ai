import 'package:dio/dio.dart';

import '../error/failure.dart';

/// Translates a low-level [DioException] into the application's typed
/// [Failure] taxonomy, keeping Dio specifics out of the rest of the codebase.
Failure mapDioException(DioException exception) {
  switch (exception.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.transformTimeout:
    case DioExceptionType.connectionError:
      return const Failure.network(
        message: 'Could not reach the server. Check your connection.',
      );
    case DioExceptionType.cancel:
      return const Failure.cancelled(message: 'The request was cancelled.');
    case DioExceptionType.badResponse:
      return Failure.server(
        message: 'The server returned an error.',
        statusCode: exception.response?.statusCode,
      );
    case DioExceptionType.badCertificate:
    case DioExceptionType.unknown:
      return const Failure.unexpected(
        message: 'An unexpected network error occurred.',
      );
  }
}
