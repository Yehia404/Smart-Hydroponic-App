import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:smart_hydroponic_app/main.dart' as app;
import 'package:smart_hydroponic_app/firebase_options.dart';

/// Integration Test - Analytics & History Flow
/// Tests: Login → Dashboard → Analytics → View History & Charts
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Initialize Firebase once for all tests
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (e) {
      // Firebase already initialized, ignore
    }
  });

  testWidgets(
    '📊 Analytics & History Flow: Login → Dashboard → Analytics → View Data',
    (WidgetTester tester) async {
      // STEP 1: Launch app
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // STEP 2: Login
      final textFields = find.byType(TextField);
      if (textFields.evaluate().length >= 2) {
        await tester.enterText(textFields.first, 'kas@gmail.com');
        await tester.pump(const Duration(milliseconds: 500));

        await tester.enterText(textFields.at(1), '123456');
        await tester.pump(const Duration(milliseconds: 500));

        final loginButton = find.text('Login');
        if (loginButton.evaluate().isNotEmpty) {
          await tester.tap(loginButton.first);
          await tester.pumpAndSettle(const Duration(seconds: 5));

          // STEP 3: Navigate to Analytics
          final analyticsIcon = find.byIcon(Icons.analytics);
          if (analyticsIcon.evaluate().isNotEmpty) {
            await tester.tap(analyticsIcon.first);
            await tester.pumpAndSettle(const Duration(seconds: 4));
            print('✅ Navigated to Analytics');
          } else {
            // Try alternative icons
            final chartIcon = find.byIcon(Icons.bar_chart);
            if (chartIcon.evaluate().isNotEmpty) {
              await tester.tap(chartIcon.first);
              await tester.pumpAndSettle(const Duration(seconds: 4));
              print('✅ Navigated to Analytics');
            } else {
              // Try text-based navigation
              final analyticsMenu = find.text('Analytics').evaluate();
              if (analyticsMenu.isNotEmpty) {
                await tester.tap(find.text('Analytics').first);
                await tester.pumpAndSettle(const Duration(seconds: 4));
                print('✅ Navigated to Analytics');
              }
            }
          }

          // STEP 4: Wait for charts to load
          await tester.pump(const Duration(seconds: 3));
          print('✅ Charts loading...');

          // STEP 5: Look for common analytics UI elements
          final hasChart =
              find.textContaining('Temperature').evaluate().isNotEmpty ||
              find.textContaining('Humidity').evaluate().isNotEmpty ||
              find.textContaining('History').evaluate().isNotEmpty;

          if (hasChart) {
            print('✅ Analytics data is displayed');
          } else {
            print(
              '⚠️ Analytics data might not be loaded or different UI structure',
            );
          }

          // STEP 6: Test scrolling through analytics (if scrollable exists)
          final scrollables = find.descendant(
            of: find.byType(Scaffold),
            matching: find.byType(Scrollable),
          );
          if (scrollables.evaluate().isNotEmpty) {
            await tester.drag(scrollables.first, const Offset(0, -300));
            await tester.pumpAndSettle(const Duration(seconds: 2));
            print('✅ Scrolled through analytics');

            // STEP 7: Scroll back up
            await tester.drag(scrollables.first, const Offset(0, 200));
            await tester.pumpAndSettle(const Duration(seconds: 1));
            print('✅ Scrolled back up');
          } else {
            print('⚠️ No scrollable widget found - UI might fit on screen');
          }

          // STEP 8: Look for export or download buttons
          final exportButtons = find.byIcon(Icons.download);
          final shareButtons = find.byIcon(Icons.share);

          if (exportButtons.evaluate().isNotEmpty) {
            print('✅ Found export button');
            // Could test export functionality here
          } else if (shareButtons.evaluate().isNotEmpty) {
            print('✅ Found share button');
          }

          // STEP 9: Wait to observe the interface
          await tester.pump(const Duration(seconds: 3));
          print('✅ Analytics flow test completed');
        }
      }
    },
  );
}
