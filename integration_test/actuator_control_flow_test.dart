import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:smart_hydroponic_app/main.dart' as app;
import 'package:smart_hydroponic_app/firebase_options.dart';

/// Integration Test - Actuator Control Flow
/// Tests: Login → Dashboard → Actuator Control → Toggle Devices
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
    '⚡ Actuator Control Flow: Login → Dashboard → Controls → Toggle Devices',
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

          // STEP 3: Navigate to Actuator Controls
          final controlIcon = find.byIcon(Icons.control_camera);
          if (controlIcon.evaluate().isNotEmpty) {
            await tester.tap(controlIcon.first);
            await tester.pumpAndSettle(const Duration(seconds: 3));
            print('✅ Navigated to Actuator Control');
          } else {
            // Try alternative navigation
            final controlMenu = find.text('Controls').evaluate();
            if (controlMenu.isNotEmpty) {
              await tester.tap(find.text('Controls').first);
              await tester.pumpAndSettle(const Duration(seconds: 3));
              print('✅ Navigated to Actuator Control');
            }
          }

          // STEP 4: Look for switches or toggle buttons
          await tester.pump(const Duration(seconds: 2));

          final switches = find.byType(Switch);
          final toggleButtons = find.byType(IconButton);

          if (switches.evaluate().isNotEmpty) {
            print('✅ Found ${switches.evaluate().length} switches');

            // STEP 5: Toggle first switch
            await tester.tap(switches.first);
            await tester.pumpAndSettle(const Duration(seconds: 2));
            print('✅ Toggled first switch');

            // Wait and toggle back
            await tester.pump(const Duration(seconds: 2));
            await tester.tap(switches.first);
            await tester.pumpAndSettle(const Duration(seconds: 2));
            print('✅ Toggled switch back');
          } else if (toggleButtons.evaluate().isNotEmpty) {
            print('✅ Found ${toggleButtons.evaluate().length} toggle buttons');

            // Test first toggle button
            await tester.tap(toggleButtons.first);
            await tester.pumpAndSettle(const Duration(seconds: 2));
            print('✅ Tapped first toggle button');
          } else {
            print(
              '⚠️ No switches or toggle buttons found - UI structure might be different',
            );
          }

          // STEP 6: Test scrolling through controls (if scrollable exists)
          final scrollables = find.descendant(
            of: find.byType(Scaffold),
            matching: find.byType(Scrollable),
          );
          if (scrollables.evaluate().isNotEmpty) {
            await tester.drag(scrollables.first, const Offset(0, -200));
            await tester.pumpAndSettle(const Duration(seconds: 1));
            print('✅ Scrolled through controls');
          } else {
            print('⚠️ No scrollable widget found - UI might fit on screen');
          }

          // STEP 7: Wait to observe the interface
          await tester.pump(const Duration(seconds: 3));
          print('✅ Actuator control flow test completed');
        }
      }
    },
  );
}
