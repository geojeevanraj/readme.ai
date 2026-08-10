import 'package:flutter_test/flutter_test.dart';
import 'package:readme_ai/features/auth/domain/auth_exception.dart';
import 'package:readme_ai/features/auth/presentation/login_page.dart';

import '../../helpers/fake_auth_repository.dart';
import '../../helpers/pump_app.dart';

void main() {
  testWidgets('shows what the app does before asking for an account', (
    tester,
  ) async {
    final auth = FakeAuthRepository();
    addTearDown(auth.dispose);

    await pumpApp(tester, authRepository: auth);

    expect(find.byType(LoginPage), findsOneWidget);
    // The sample passage, the phrase a reader would select, and the answer.
    expect(find.textContaining('invisible hand'), findsWidgets);
    expect(find.textContaining('nobody is coordinating it'), findsOneWidget);
  });

  testWidgets('a failed sign-in explains itself next to the button', (
    tester,
  ) async {
    final auth = FakeAuthRepository()
      ..signInError = const AuthException.notConfigured();
    addTearDown(auth.dispose);

    await pumpApp(tester, authRepository: auth);

    await tester.ensureVisible(find.text('Sign in with Google'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign in with Google'));
    await tester.pumpAndSettle();

    // The failure stays on screen (unlike a snackbar) and the button invites
    // another attempt rather than repeating its original label.
    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.text('Try signing in again'), findsOneWidget);
  });

  testWidgets('a cancelled sign-in is not treated as an error', (tester) async {
    final auth = FakeAuthRepository()
      ..signInError = const AuthException.cancelled();
    addTearDown(auth.dispose);

    await pumpApp(tester, authRepository: auth);

    await tester.ensureVisible(find.text('Sign in with Google'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign in with Google'));
    await tester.pumpAndSettle();

    expect(find.text('Try signing in again'), findsNothing);
    expect(find.text('Sign in with Google'), findsOneWidget);
  });
}
