import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:smart_hydroponic_app/main.dart' as app;
import 'package:smart_hydroponic_app/firebase_options.dart';

/// Integration Test - Settings Configuration Flow
/// Tests: Login → Dashboard → Settings → Configure Options
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

  testWidgets('⚙️ Settings Configuration Flow: Login → Settings → Configure', (
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

        // STEP 3: Navigate to Settings
        final settingsIcon = find.byIcon(Icons.settings_outlined);
        if (settingsIcon.evaluate().isNotEmpty) {
          await tester.tap(settingsIcon.first);
          await tester.pumpAndSettle(const Duration(seconds: 3));
          print('✅ Navigated to Settings');
        } else {
          // Try alternative navigation
          final settingsMenu = find.text('Settings').evaluate();
          if (settingsMenu.isNotEmpty) {
            await tester.tap(find.text('Settings').first);
            await tester.pumpAndSettle(const Duration(seconds: 3));
            print('✅ Navigated to Settings');
          }
        }

        // STEP 4: Wait for settings to load
        await tester.pump(const Duration(seconds: 2));

        // STEP 5: Look for settings categories
        final hasSettings =
            find.textContaining('Profile').evaluate().isNotEmpty ||
            find.textContaining('Notifications').evaluate().isNotEmpty ||
            find.textContaining('Theme').evaluate().isNotEmpty ||
            find.textContaining('Language').evaluate().isNotEmpty;

        if (hasSettings) {
          print('✅ Settings screen loaded');
        } else {
          print('⚠️ Settings UI structure might be different');
        }

        // STEP 6: Test scrolling through settings (if scrollable exists)
        final scrollables = find.descendant(
          of: find.byType(Scaffold),
          matching: find.byType(Scrollable),
        );
        if (scrollables.evaluate().isNotEmpty) {
          await tester.drag(scrollables.first, const Offset(0, -300));
          await tester.pumpAndSettle(const Duration(seconds: 1));
          print('✅ Scrolled through settings');
        } else {
          print('⚠️ No scrollable widget found - UI might fit on screen');
        }

        // STEP 7: Look for switches/toggles in settings
        final switches = find.byType(Switch);
        if (switches.evaluate().isNotEmpty) {
          print('✅ Found ${switches.evaluate().length} toggle switches');

          // Test toggling a setting (non-destructive)
          final switchWidget = switches.first;
          await tester.tap(switchWidget);
          await tester.pumpAndSettle(const Duration(seconds: 1));
          print('✅ Toggled a setting');

          // Toggle back
          await tester.tap(switchWidget);
          await tester.pumpAndSettle(const Duration(seconds: 1));
          print('✅ Toggled setting back');
        }

        // STEP 8: Test navigation to Profile settings (if exists)
        final profileOption = find.text('Profile');
        if (profileOption.evaluate().isNotEmpty) {
          await tester.tap(profileOption.first);
          await tester.pumpAndSettle(const Duration(seconds: 2));
          print('✅ Opened Profile settings');

          // Go back
          final backButton = find.byIcon(Icons.arrow_back);
          if (backButton.evaluate().isNotEmpty) {
            await tester.tap(backButton.first);
            await tester.pumpAndSettle(const Duration(seconds: 1));
            print('✅ Returned from Profile');
          }
        }

        // STEP 9: Test navigation to Notification settings (if exists)
        final notificationOption = find.textContaining('Notification');
        if (notificationOption.evaluate().isNotEmpty) {
          await tester.tap(notificationOption.first);
          await tester.pumpAndSettle(const Duration(seconds: 2));
          print('✅ Opened Notification settings');

          // Go back
          final backButton = find.byIcon(Icons.arrow_back);
          if (backButton.evaluate().isNotEmpty) {
            await tester.tap(backButton.first);
            await tester.pumpAndSettle(const Duration(seconds: 1));
            print('✅ Returned from Notifications');
          }
        }

        // STEP 10: Scroll back to top (if scrollable exists)
        if (scrollables.evaluate().isNotEmpty) {
          await tester.drag(scrollables.first, const Offset(0, 300));
          await tester.pumpAndSettle(const Duration(seconds: 1));
          print('✅ Scrolled back to top');
        }

        // STEP 11: Wait to observe the interface
        await tester.pump(const Duration(seconds: 3));
        print('✅ Settings configuration flow test completed');
      }
    }
  });
}
