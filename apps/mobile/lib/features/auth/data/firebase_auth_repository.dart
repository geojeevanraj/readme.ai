import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../domain/auth_exception.dart';
import '../domain/auth_repository.dart';
import '../domain/auth_user.dart';

/// [AuthRepository] backed by Firebase Authentication and Google Sign-In.
///
/// Provider-specific types (Firebase `User`, `GoogleSignIn`) never escape this
/// class; callers receive domain [AuthUser]s and typed [AuthException]s.
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({
    required FirebaseAuth firebaseAuth,
    required GoogleSignIn googleSignIn,
  }) : _firebaseAuth = firebaseAuth,
       _googleSignIn = googleSignIn;

  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  @override
  Stream<AuthUser?> authStateChanges() =>
      _firebaseAuth.authStateChanges().map(_toAuthUser);

  @override
  Future<void> signInWithGoogle() async {
    try {
      final account = await _googleSignIn.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        throw const AuthException.unknown(
          'Google did not return an identity token.',
        );
      }
      final credential = GoogleAuthProvider.credential(idToken: idToken);
      await _firebaseAuth.signInWithCredential(credential);
    } on GoogleSignInException catch (error) {
      throw _mapGoogleException(error);
    } on FirebaseAuthException catch (error) {
      throw AuthException.unknown(error.message ?? 'Authentication failed.');
    }
  }

  @override
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _firebaseAuth.signOut();
  }

  @override
  Future<String?> idToken() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      return null;
    }
    return user.getIdToken();
  }

  AuthUser? _toAuthUser(User? user) {
    if (user == null) {
      return null;
    }
    return AuthUser(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
      photoUrl: user.photoURL,
    );
  }

  AuthException _mapGoogleException(GoogleSignInException error) {
    if (error.code == GoogleSignInExceptionCode.canceled) {
      return const AuthException.cancelled();
    }
    return AuthException.unknown(error.description ?? 'Google sign-in failed.');
  }
}
