import 'package:flutter_test/flutter_test.dart';
import 'package:zerowaste/app.dart';
import 'package:zerowaste/services/auth_service.dart';
import 'package:zerowaste/services/eco_repository.dart';

void main() {
  testWidgets('shows EcoDiscover onboarding', (tester) async {
    await tester.pumpWidget(
      EcoDiscoverApp(
        repository: DemoEcoRepository(),
        authService: DemoAuthService(),
      ),
    );

    expect(find.text('EcoDiscover'), findsOneWidget);
    expect(find.text('Eco-friendly discovery'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
  });

  testWidgets('can open the login screen from onboarding', (tester) async {
    await tester.pumpWidget(
      EcoDiscoverApp(
        repository: DemoEcoRepository(),
        authService: DemoAuthService(),
      ),
    );

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('nature@example.com'), findsOneWidget);
  });
}
