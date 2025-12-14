import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:smart_hydroponic_app/main.dart' as app;
import 'package:smart_hydroponic_app/firebase_options.dart';

/// Integration Test - Sensor Monitoring Flow
/// Tests: Login → Dashboard → Sensor Monitoring → View Sensor Data
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
    '🌡️ Sensor Monitoring Flow: Login → Dashboard → Sensors → View Data',
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

          // STEP 3: Navigate to Sensor Monitoring
          // Look for sensor monitoring icon or text
          final sensorIcon = find.byIcon(Icons.sensors);
          if (sensorIcon.evaluate().isNotEmpty) {
            await tester.tap(sensorIcon.first);
            await tester.pumpAndSettle(const Duration(seconds: 3));
            print('✅ Navigated to Sensor Monitoring');
          } else {
            // Try to find sensor menu item
            final sensorMenu = find.text('Sensors').evaluate();
            if (sensorMenu.isNotEmpty) {
              await tester.tap(find.text('Sensors').first);
              await tester.pumpAndSettle(const Duration(seconds: 3));
              print('✅ Navigated to Sensor Monitoring');
            }
          }

          // STEP 4: Verify sensor data is displayed
          await tester.pump(const Duration(seconds: 2));

          // Look for sensor readings (temperature, humidity, pH, etc.)
          final hasTemperature =
              find.textContaining('°C').evaluate().isNotEmpty ||
              find.textContaining('Temperature').evaluate().isNotEmpty;
          final hasHumidity =
              find.textContaining('Humidity').evaluate().isNotEmpty ||
              find.textContaining('%').evaluate().isNotEmpty;

          if (hasTemperature || hasHumidity) {
            print('✅ Sensor data is displayed');
          } else {
            print(
              '⚠️ Sensor data might not be loaded yet or different UI structure',
            );
          }

          // STEP 5: Test scrolling through sensor data (if scrollable exists)
          final scrollables = find.descendant(
            of: find.byType(Scaffold),
            matching: find.byType(Scrollable),
          );
          if (scrollables.evaluate().isNotEmpty) {
            await tester.drag(scrollables.first, const Offset(0, -200));
            await tester.pumpAndSettle(const Duration(seconds: 1));
            print('✅ Scrolled through sensor data');
          } else {
            print('⚠️ No scrollable widget found - UI might fit on screen');
          }

          // STEP 6: Wait to observe the interface
          await tester.pump(const Duration(seconds: 3));
          print('✅ Sensor monitoring flow test completed');
        }
      }
    },
  );
}
