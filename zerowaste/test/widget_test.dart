import 'package:flutter_test/flutter_test.dart';

import 'package:zerowaste/app.dart';
import 'package:zerowaste/services/auth_service.dart';
import 'package:zerowaste/services/marketplace_repository.dart';

void main() {
  testWidgets('NFT marketplace onboarding loads', (WidgetTester tester) async {
    await tester.pumpWidget(
      NftMarketApp(
        repository: DemoMarketplaceRepository(),
        authService: DemoAuthService(),
      ),
    );

    expect(find.text('NovaNFT'), findsOneWidget);
    expect(find.text('Discover rare digital art before it trends'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
  });
}
