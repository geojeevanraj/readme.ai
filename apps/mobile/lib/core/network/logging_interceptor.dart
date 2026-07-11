import 'package:dio/dio.dart';

import '../logging/app_logger.dart';

/// Dio interceptor that logs the lifecycle of every request through the shared
/// [AppLogger]. Intentionally logs metadata only (method, path, status) and
/// never request/response bodies, to avoid leaking sensitive content.
class LoggingInterceptor extends Interceptor {
  const LoggingInterceptor(this._logger);

  final AppLogger _logger;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _logger.debug('--> ${options.method} ${options.uri.path}');
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    _logger.debug(
      '<-- ${response.statusCode} ${response.requestOptions.uri.path}',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _logger.warning('x-- ${err.type.name} ${err.requestOptions.uri.path}');
    handler.next(err);
  }
}
