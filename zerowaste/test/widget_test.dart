// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:zerowaste/app.dart';
import 'package:zerowaste/services/auth_service.dart';
import 'package:zerowaste/services/eco_repository.dart';

void main() {
  testWidgets('Onboarding screen loads', (WidgetTester tester) async {
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
}
