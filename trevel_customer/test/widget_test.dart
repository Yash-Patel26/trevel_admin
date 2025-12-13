import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:trevel_customer/main.dart';
import 'package:trevel_customer/features/splash/presentation/pages/splash_page.dart';

void main() {
  testWidgets('Splash screen smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const TrevelCustomerApp());

    // Verify that SplashPage is present
    expect(find.byType(SplashPage), findsOneWidget);
    
    // Verify that the logo image is present
    expect(find.byType(Image), findsOneWidget);
  });
}
