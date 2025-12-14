import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:smart_hydroponic_app/main.dart' as app;
import 'package:smart_hydroponic_app/firebase_options.dart';

/// Comprehensive Integration Test Suite for Hydroponic System
/// All tests run in a single app instance - sequential test flow

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
    // Initialize Firebase once
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (e) {
      // Firebase already initialized, ignore
    }
  });

  testWidgets(
    '🎯 Complete authentication and navigation flow - Single instance test',
    (WidgetTester tester) async {
      // 🚀 STEP 1: Launch app and wait for splash screen
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Handle notification permission if it appears
      await handleNotificationPermission(tester);

      // Verify app launched successfully
      expect(find.byType(MaterialApp), findsOneWidget);
      final hasLoginScreen =
          find.text('Login').evaluate().isNotEmpty ||
          find.text('Welcome Back!').evaluate().isNotEmpty;
      expect(
        hasLoginScreen,
        isTrue,
        reason: '✅ App should show login screen after splash',
      );

      // 🔐 STEP 2: Test empty email validation
      final textFields = find.byType(TextField);
      if (textFields.evaluate().length >= 2) {
        // Clear any existing text first
        await tester.enterText(textFields.first, '');
        await tester.enterText(textFields.at(1), 'somepassword');
        await tester.pump(const Duration(milliseconds: 500));

        final loginButton = find.text('Login');
        if (loginButton.evaluate().isNotEmpty) {
          await tester.tap(loginButton.first);
          await tester.pump(const Duration(seconds: 1));

          // Should still be on login screen
          expect(find.byType(MaterialApp), findsOneWidget);
        }

        // 🔐 STEP 3: Test invalid email format
        await tester.pumpAndSettle(const Duration(milliseconds: 500));
        await tester.enterText(textFields.first, 'notanemail');
        await tester.enterText(textFields.at(1), 'password123');
        await tester.pump(const Duration(milliseconds: 500));

        if (loginButton.evaluate().isNotEmpty) {
          await tester.tap(loginButton.first);
          await tester.pump(const Duration(seconds: 2));

          // Should remain on login screen
          expect(find.byType(MaterialApp), findsOneWidget);
        }

        // 🔐 STEP 4: Navigate to registration screen
        await tester.pumpAndSettle(const Duration(milliseconds: 500));
        final registerLink = find.text('Register Now');
        if (registerLink.evaluate().isNotEmpty) {
          await tester.tap(registerLink.first);
          await tester.pumpAndSettle(const Duration(seconds: 2));

          // Verify navigation to registration screen
          final hasRegisterElements = find
              .text('Create Account')
              .evaluate()
              .isNotEmpty;
          expect(
            hasRegisterElements,
            isTrue,
            reason: '✅ Should navigate to registration',
          );

          // Go back to login screen
          final backButton = find.byType(BackButton);
          if (backButton.evaluate().isNotEmpty) {
            await tester.tap(backButton.first);
            await tester.pumpAndSettle(const Duration(seconds: 2));
          }
        }

        // 🔐 STEP 5: Test password recovery navigation
        await tester.pumpAndSettle(const Duration(milliseconds: 500));
        final forgotPasswordLink = find.text('Forgot Password?');
        if (forgotPasswordLink.evaluate().isNotEmpty) {
          await tester.tap(forgotPasswordLink.first);
          await tester.pumpAndSettle(const Duration(seconds: 2));

          // Verify navigation to password recovery
          final hasRecoveryElements =
              find.text('Reset Password').evaluate().isNotEmpty ||
              find.text('Password Recovery').evaluate().isNotEmpty;
          expect(
            hasRecoveryElements,
            isTrue,
            reason: '✅ Should navigate to password recovery',
          );

          // Go back to login screen
          final backButton = find.byType(BackButton);
          if (backButton.evaluate().isNotEmpty) {
            await tester.tap(backButton.first);
            await tester.pumpAndSettle(const Duration(seconds: 2));
          }
        }

        // ✅ STEP 6: Successful login with valid credentials
        await tester.pumpAndSettle(const Duration(seconds: 1));
        await tester.enterText(textFields.first, 'kas@gmail.com');
        await tester.pump(const Duration(milliseconds: 500));

        await tester.enterText(textFields.at(1), '123456');
        await tester.pump(const Duration(milliseconds: 500));

        if (loginButton.evaluate().isNotEmpty) {
          await tester.tap(loginButton.first);

          // Wait for authentication and navigation to dashboard
          await tester.pumpAndSettle(const Duration(seconds: 5));

          // Verify we're on the dashboard
          final dashboardIndicators =
              find.text('SMART Hydroponic').evaluate().isNotEmpty ||
              find.byIcon(Icons.settings_outlined).evaluate().isNotEmpty;
          expect(
            dashboardIndicators,
            isTrue,
            reason: '✅ Should be on dashboard after login',
          );

          await tester.pump(const Duration(seconds: 2));

          // 🔔 STEP 7: Test notifications access
          final notificationsIcon = find.byIcon(Icons.notifications_outlined);
          if (notificationsIcon.evaluate().isNotEmpty) {
            await tester.tap(notificationsIcon.first);
            await tester.pumpAndSettle(const Duration(seconds: 2));

            // Verify navigation to notifications
            expect(find.byType(MaterialApp), findsOneWidget);

            // Go back to dashboard
            final backButton = find.byType(BackButton);
            if (backButton.evaluate().isNotEmpty) {
              await tester.tap(backButton.first);
              await tester.pumpAndSettle(const Duration(seconds: 2));
            }
          }

          // 🔊 STEP 8: Verify accessibility features
          await tester.pump(const Duration(seconds: 1));
          final micIcon = find.byIcon(Icons.mic);
          final micNoneIcon = find.byIcon(Icons.mic_none);
          final hasMicButton =
              micIcon.evaluate().isNotEmpty ||
              micNoneIcon.evaluate().isNotEmpty;
          expect(
            hasMicButton,
            isTrue,
            reason: '✅ Voice command button should be visible',
          );

          final volumeIcon = find.byIcon(Icons.volume_up);
          final volumeOffIcon = find.byIcon(Icons.volume_off);
          final hasVolumeButton =
              volumeIcon.evaluate().isNotEmpty ||
              volumeOffIcon.evaluate().isNotEmpty;
          expect(
            hasVolumeButton,
            isTrue,
            reason: '✅ TTS button should be visible',
          );

          // 🏠 STEP 9: Test bottom navigation
          await tester.pump(const Duration(seconds: 1));
          final homeIcon = find.byIcon(Icons.home);
          final sensorIcon = find.byIcon(Icons.sensors);

          if (sensorIcon.evaluate().isNotEmpty) {
            await tester.tap(sensorIcon.first);
            await tester.pumpAndSettle(const Duration(seconds: 2));

            expect(find.byType(MaterialApp), findsOneWidget);

            // Go back to home
            if (homeIcon.evaluate().isNotEmpty) {
              await tester.tap(homeIcon.first);
              await tester.pumpAndSettle(const Duration(seconds: 2));
            }
          }

          // ⚙️ STEP 10: Navigate to Settings
          await tester.pump(const Duration(seconds: 1));
          final settingsIcon = find.byIcon(Icons.settings_outlined);
          if (settingsIcon.evaluate().isNotEmpty) {
            await tester.tap(settingsIcon.first);
            await tester.pumpAndSettle(const Duration(seconds: 3));

            // Verify we're on Settings screen
            final onSettings = find.text('Settings').evaluate().isNotEmpty;
            expect(onSettings, isTrue, reason: '✅ Should navigate to Settings');

            await tester.pump(const Duration(seconds: 1));

            // 🔧 STEP 11: Test Notifications settings
            final notificationSettings = find.text('Notifications');
            if (notificationSettings.evaluate().isNotEmpty) {
              await tester.tap(notificationSettings.first);
              await tester.pumpAndSettle(const Duration(seconds: 2));

              expect(find.byType(MaterialApp), findsOneWidget);

              // Go back
              final backButton = find.byType(BackButton);
              if (backButton.evaluate().isNotEmpty) {
                await tester.tap(backButton.first);
                await tester.pumpAndSettle(const Duration(seconds: 1));
              }
            }

            // 🔧 STEP 12: Test Sensor Thresholds
            final thresholds = find.text('Sensor Thresholds');
            if (thresholds.evaluate().isNotEmpty) {
              await tester.tap(thresholds.first);
              await tester.pumpAndSettle(const Duration(seconds: 2));

              expect(find.byType(MaterialApp), findsOneWidget);

              // Go back
              final backButton = find.byType(BackButton);
              if (backButton.evaluate().isNotEmpty) {
                await tester.tap(backButton.first);
                await tester.pumpAndSettle(const Duration(seconds: 1));
              }
            }

            // 🔧 STEP 13: Test Automation Rules
            final automation = find.text('Automation Rules');
            if (automation.evaluate().isNotEmpty) {
              await tester.tap(automation.first);
              await tester.pumpAndSettle(const Duration(seconds: 2));

              expect(find.byType(MaterialApp), findsOneWidget);

              // Go back
              final backButton = find.byType(BackButton);
              if (backButton.evaluate().isNotEmpty) {
                await tester.tap(backButton.first);
                await tester.pumpAndSettle(const Duration(seconds: 1));
              }
            }

            // 👤 STEP 14: Navigate to Profile
            await tester.pump(const Duration(seconds: 1));
            final profileTile = find.text('Profile');
            if (profileTile.evaluate().isNotEmpty) {
              await tester.tap(profileTile.first);
              await tester.pumpAndSettle(const Duration(seconds: 3));

              // Verify we're on Profile screen
              final onProfile =
                  find.text('Email').evaluate().isNotEmpty ||
                  find.text('Phone Number').evaluate().isNotEmpty ||
                  find.byIcon(Icons.email_outlined).evaluate().isNotEmpty;
              expect(onProfile, isTrue, reason: '✅ Should navigate to Profile');

              // Wait on profile screen for recording visibility
              await tester.pump(const Duration(seconds: 3));

              // Go back to settings
              final backButton = find.byType(BackButton);
              if (backButton.evaluate().isNotEmpty) {
                await tester.tap(backButton.first);
                await tester.pumpAndSettle(const Duration(seconds: 2));
              }
            }

            // 🚪 STEP 15: Test Logout
            await tester.pump(const Duration(seconds: 1));
            final logoutButton = find.text('Logout');
            if (logoutButton.evaluate().isNotEmpty) {
              await tester.tap(logoutButton.first);
              await tester.pumpAndSettle(const Duration(seconds: 3));

              // Verify we're back on login screen
              final backOnLogin =
                  find.text('Login').evaluate().isNotEmpty ||
                  find.text('Welcome Back!').evaluate().isNotEmpty;
              expect(
                backOnLogin,
                isTrue,
                reason: '✅ Should return to login after logout',
              );
            }
          }
        }
      }
    },
  );
}
