import 'package:dio/dio.dart';

/// Dio interceptor that attaches the current user's bearer token to every
/// outgoing request, so the backend can validate identity on each call.
///
/// The token is resolved lazily per request via [_tokenProvider]; no token is
/// cached here, ensuring a fresh, valid token is always sent.
class AuthInterceptor extends Interceptor {
  const AuthInterceptor(this._tokenProvider);

  final Future<String?> Function() _tokenProvider;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _tokenProvider();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}
