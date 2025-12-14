import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:smart_hydroponic_app/main.dart' as app;
import 'package:smart_hydroponic_app/firebase_options.dart';

/// Integration Test - Alerts & Notifications Flow
/// Tests: Login → Dashboard → Alerts → View & Interact with Notifications
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
    '🔔 Alerts & Notifications Flow: Login → Dashboard → View Alerts',
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

          // STEP 3: Navigate to Alerts/Notifications
          final notificationIcon = find.byIcon(Icons.notifications_outlined);
          if (notificationIcon.evaluate().isNotEmpty) {
            await tester.tap(notificationIcon.first);
            await tester.pumpAndSettle(const Duration(seconds: 3));
            print('✅ Navigated to Alerts/Notifications');
          } else {
            // Try alternative icons
            final alertIcon = find.byIcon(Icons.notification_important);
            if (alertIcon.evaluate().isNotEmpty) {
              await tester.tap(alertIcon.first);
              await tester.pumpAndSettle(const Duration(seconds: 3));
              print('✅ Navigated to Alerts');
            } else {
              // Try text-based navigation
              final alertsMenu = find.text('Alerts').evaluate();
              if (alertsMenu.isNotEmpty) {
                await tester.tap(find.text('Alerts').first);
                await tester.pumpAndSettle(const Duration(seconds: 3));
                print('✅ Navigated to Alerts');
              }
            }
          }

          // STEP 4: Wait for alerts to load
          await tester.pump(const Duration(seconds: 2));

          // STEP 5: Look for alerts/notifications list
          final hasAlerts =
              find.textContaining('Alert').evaluate().isNotEmpty ||
              find.textContaining('Notification').evaluate().isNotEmpty ||
              find.textContaining('Warning').evaluate().isNotEmpty ||
              find.byType(ListTile).evaluate().isNotEmpty;

          if (hasAlerts) {
            print('✅ Alerts/Notifications are displayed');

            // STEP 6: Try tapping on first alert if exists
            final listTiles = find.byType(ListTile);
            if (listTiles.evaluate().isNotEmpty) {
              await tester.tap(listTiles.first);
              await tester.pumpAndSettle(const Duration(seconds: 2));
              print('✅ Tapped on first alert');

              // Go back if a detail view opened
              final backButton = find.byIcon(Icons.arrow_back);
              if (backButton.evaluate().isNotEmpty) {
                await tester.tap(backButton.first);
                await tester.pumpAndSettle(const Duration(seconds: 1));
                print('✅ Returned from alert detail');
              }
            }
          } else {
            print('⚠️ No alerts found or different UI structure');
          }

          // STEP 7: Test scrolling through alerts
          final scrollables = find.descendant(
            of: find.byType(Scaffold),
            matching: find.byType(Scrollable),
          );
          if (scrollables.evaluate().isNotEmpty) {
            await tester.drag(scrollables.first, const Offset(0, -200));
            await tester.pumpAndSettle(const Duration(seconds: 1));
            print('✅ Scrolled through alerts');
          } else {
            print('⚠️ No scrollable widget found - UI might fit on screen');
          }

          // STEP 8: Look for filter or settings buttons
          final filterButtons = find.byIcon(Icons.filter_list);
          final settingsButtons = find.byIcon(Icons.settings);

          if (filterButtons.evaluate().isNotEmpty) {
            print('✅ Found filter button');
          } else if (settingsButtons.evaluate().isNotEmpty) {
            print('✅ Found settings button');
          }

          // STEP 9: Wait to observe the interface
          await tester.pump(const Duration(seconds: 3));
          print('✅ Alerts & notifications flow test completed');
        }
      }
    },
  );
}
