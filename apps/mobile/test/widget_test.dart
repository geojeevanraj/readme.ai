import 'package:flutter_test/flutter_test.dart';
import 'package:readme_ai/features/auth/presentation/login_page.dart';

import 'helpers/fake_auth_repository.dart';
import 'helpers/pump_app.dart';

void main() {
  testWidgets('app launches to the login screen when signed out', (
    tester,
  ) async {
    final repository = FakeAuthRepository();
    addTearDown(repository.dispose);

    await pumpApp(tester, authRepository: repository);

    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.text('Sign in with Google'), findsOneWidget);
  });
}
