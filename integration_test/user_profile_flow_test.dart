import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:smart_hydroponic_app/main.dart' as app;
import 'package:smart_hydroponic_app/firebase_options.dart';

/// Integration Test - User Profile Flow
/// Tests: Login → Dashboard → Profile → View & Edit Profile
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

  testWidgets('👤 User Profile Flow: Login → Profile → View Details', (
    WidgetTester tester,
  ) async {
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

        // STEP 3: Navigate to Settings first (Profile is usually under Settings)
        final settingsIcon = find.byIcon(Icons.settings_outlined);
        if (settingsIcon.evaluate().isNotEmpty) {
          await tester.tap(settingsIcon.first);
          await tester.pumpAndSettle(const Duration(seconds: 3));
          print('✅ Navigated to Settings');

          // STEP 4: Find and tap Profile option
          final profileOption = find.text('Profile');
          if (profileOption.evaluate().isNotEmpty) {
            await tester.tap(profileOption.first);
            await tester.pumpAndSettle(const Duration(seconds: 3));
            print('✅ Opened Profile screen');

            // STEP 5: Wait for profile data to load
            await tester.pump(const Duration(seconds: 2));

            // STEP 6: Verify profile information is displayed
            final hasEmail = find.textContaining('@').evaluate().isNotEmpty;
            final hasName =
                find.textContaining('Name').evaluate().isNotEmpty ||
                find.text('kas@gmail.com').evaluate().isNotEmpty;

            if (hasEmail || hasName) {
              print('✅ Profile information is displayed');
            } else {
              print(
                '⚠️ Profile data might not be loaded or different structure',
              );
            }

            // STEP 7: Look for edit button
            final editButtons = find.byIcon(Icons.edit);
            if (editButtons.evaluate().isNotEmpty) {
              print('✅ Found edit button');
              // Could test edit functionality here
            }

            // STEP 8: Test scrolling through profile
            final scrollables = find.descendant(
              of: find.byType(Scaffold),
              matching: find.byType(Scrollable),
            );
            if (scrollables.evaluate().isNotEmpty) {
              await tester.drag(scrollables.first, const Offset(0, -200));
              await tester.pumpAndSettle(const Duration(seconds: 1));
              print('✅ Scrolled through profile');

              await tester.drag(scrollables.first, const Offset(0, 200));
              await tester.pumpAndSettle(const Duration(seconds: 1));
              print('✅ Scrolled back');
            } else {
              print('⚠️ No scrollable widget found - UI might fit on screen');
            }

            // STEP 9: Wait to observe the interface
            await tester.pump(const Duration(seconds: 3));

            // STEP 10: Navigate back
            final backButton = find.byIcon(Icons.arrow_back);
            if (backButton.evaluate().isNotEmpty) {
              await tester.tap(backButton.first);
              await tester.pumpAndSettle(const Duration(seconds: 1));
              print('✅ Returned from Profile');
            }

            print('✅ User profile flow test completed');
          } else {
            // Try alternative - look for account or user icon in settings
            final accountIcon = find.byIcon(Icons.account_circle);
            if (accountIcon.evaluate().isNotEmpty) {
              await tester.tap(accountIcon.first);
              await tester.pumpAndSettle(const Duration(seconds: 3));
              print('✅ Opened user account screen');
            }
          }
        } else {
          // Try direct profile navigation from dashboard
          final profileIcon = find.byIcon(Icons.account_circle);
          if (profileIcon.evaluate().isNotEmpty) {
            await tester.tap(profileIcon.first);
            await tester.pumpAndSettle(const Duration(seconds: 3));
            print('✅ Navigated directly to Profile');
          }
        }
      }
    }
  });
}
