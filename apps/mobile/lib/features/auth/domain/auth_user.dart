import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_user.freezed.dart';

/// A signed-in user, mapped from the identity provider.
///
/// This is the app's own domain representation; it deliberately does not expose
/// any provider-specific (Firebase) types beyond the data layer.
@freezed
abstract class AuthUser with _$AuthUser {
  const factory AuthUser({
    required String uid,
    required String email,
    String? displayName,
    String? photoUrl,
  }) = _AuthUser;
}
