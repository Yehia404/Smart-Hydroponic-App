import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:smart_hydroponic_app/main.dart' as app;
import 'package:smart_hydroponic_app/firebase_options.dart';

/// Basic Integration Test - Quick Smoke Test
/// For comprehensive tests, see comprehensive_auth_flow_test.dart

/// Helper function to handle notification permission dialogs
/// Note: Native Android dialogs cannot be detected by Flutter finders.
/// This function waits to allow time for manual dismissal or ADB automation.
Future<void> handleNotificationPermission(WidgetTester tester) async {
  print('⏳ Waiting for potential permission dialog (3 seconds)...');

  // Wait for dialog to appear and be dismissed
  // Native Android dialogs are not detectable by Flutter widget finders
  await tester.pump(const Duration(seconds: 3));

  // Try to find Flutter-based permission dialogs (if app uses custom dialog)
  final denyButton = find.text('Deny');
  final dontAllowButton = find.textContaining("Don't");
  final dismissButton = find.text('Dismiss');
  final cancelButton = find.text('Cancel');

  if (denyButton.evaluate().isNotEmpty) {
    await tester.tap(denyButton);
    await tester.pumpAndSettle(const Duration(seconds: 1));
    print('🚫 Denied notification permission');
  } else if (dontAllowButton.evaluate().isNotEmpty) {
    await tester.tap(dontAllowButton.first);
    await tester.pumpAndSettle(const Duration(seconds: 1));
    print('🚫 Denied notification permission');
  } else if (dismissButton.evaluate().isNotEmpty) {
    await tester.tap(dismissButton);
    await tester.pumpAndSettle(const Duration(seconds: 1));
    print('🚫 Dismissed notification permission');
  } else if (cancelButton.evaluate().isNotEmpty) {
    await tester.tap(cancelButton);
    await tester.pumpAndSettle(const Duration(seconds: 1));
    print('🚫 Cancelled notification permission');
  } else {
    print('ℹ️ No Flutter permission dialog found (may be native OS dialog)');
  }
}

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

    // Launch app once for all tests
    app.main();
  });

  group('🔥 Quick Smoke Test - Login & Navigation', () {
    testWidgets('Complete flow: Login → Dashboard → Settings → Profile', (
      WidgetTester tester,
    ) async {
      // App already launched in setUpAll, just wait for splash to complete
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Handle notification permission if it appears
      await handleNotificationPermission(tester);

      final textFields = find.byType(TextField);
      if (textFields.evaluate().length >= 2) {
        // Step 1: Login with valid credentials
        await tester.enterText(textFields.first, 'kas@gmail.com');
        await tester.pump(const Duration(milliseconds: 500));

        await tester.enterText(textFields.at(1), '123456');
        await tester.pump(const Duration(milliseconds: 500));

        final loginButton = find.text('Login');
        if (loginButton.evaluate().isNotEmpty) {
          await tester.tap(loginButton.first);

          // Step 2: Wait for authentication and navigation to dashboard
          await tester.pumpAndSettle(const Duration(seconds: 5));

          // Verify we're on dashboard (look for SMART Hydroponic title or settings icon)
          final onDashboard =
              find.text('SMART Hydroponic').evaluate().isNotEmpty ||
              find.byIcon(Icons.settings_outlined).evaluate().isNotEmpty;
          expect(
            onDashboard,
            isTrue,
            reason: 'Should be on dashboard after login',
          );

          // Small delay to ensure dashboard is stable
          await tester.pump(const Duration(seconds: 2));

          // Step 3: Navigate to Settings using icon
          final settingsButton = find.byIcon(Icons.settings_outlined);
          if (settingsButton.evaluate().isNotEmpty) {
            await tester.tap(settingsButton.first);
            await tester.pumpAndSettle(const Duration(seconds: 3));

            // Verify we're on Settings screen
            final onSettings = find.text('Settings').evaluate().isNotEmpty;
            expect(onSettings, isTrue, reason: 'Should navigate to Settings');

            // Small delay to ensure settings screen is stable
            await tester.pump(const Duration(seconds: 2));

            // Step 4: Open Profile page
            final profileButton = find.text('Profile');
            if (profileButton.evaluate().isNotEmpty) {
              await tester.tap(profileButton.first);
              await tester.pumpAndSettle(const Duration(seconds: 3));

              // Verify we're on Profile screen (look for profile-related elements)
              final onProfile =
                  find.text('Email').evaluate().isNotEmpty ||
                  find.text('Phone Number').evaluate().isNotEmpty ||
                  find.byIcon(Icons.email_outlined).evaluate().isNotEmpty;
              expect(onProfile, isTrue, reason: 'Should navigate to Profile');

              // Wait on profile screen for recording visibility
              await tester.pump(const Duration(seconds: 3));
            }
          }
        }
      }
    });
  });
}
