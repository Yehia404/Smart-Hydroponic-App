import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:smart_hydroponic_app/view/auth/login_screen.dart';
import 'package:smart_hydroponic_app/viewmodels/login_viewmodel.dart';
import 'package:smart_hydroponic_app/data/services/auth_service.dart';

// Mock classes
class MockAuthService extends Mock implements AuthService {}

class MockLoginViewModel extends Mock implements LoginViewModel {}

void main() {
  late MockAuthService mockAuthService;
  late LoginViewModel loginViewModel;

  setUp(() {
    mockAuthService = MockAuthService();
    loginViewModel = LoginViewModel(mockAuthService);
  });

  Widget createTestWidget() {
    return MaterialApp(
      home: ChangeNotifierProvider<LoginViewModel>.value(
        value: loginViewModel,
        child: const LoginScreen(),
      ),
    );
  }

  group('LoginScreen Widget Tests', () {
    testWidgets('should display all UI elements', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());

      // Assert
      expect(find.byIcon(Icons.eco_rounded), findsOneWidget);
      expect(find.text('Welcome Back!'), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(2));
      expect(find.text('Login'), findsOneWidget);
      expect(find.text('Forgot Password?'), findsOneWidget);
      expect(find.text('Don\'t have an account?'), findsOneWidget);
    });

    testWidgets('should have email and password input fields', (
      WidgetTester tester,
    ) async {
      // Act
      await tester.pumpWidget(createTestWidget());

      // Assert
      final emailField = find.widgetWithText(TextField, 'Email');
      final passwordField = find.widgetWithText(TextField, 'Password');

      expect(emailField, findsOneWidget);
      expect(passwordField, findsOneWidget);
    });

    testWidgets('should accept text input in email field', (
      WidgetTester tester,
    ) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());

      // Act
      await tester.enterText(
        find.widgetWithText(TextField, 'Email'),
        'test@example.com',
      );
      await tester.pump();

      // Assert
      expect(find.text('test@example.com'), findsOneWidget);
    });

    testWidgets('should accept text input in password field', (
      WidgetTester tester,
    ) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());

      // Act
      await tester.enterText(
        find.widgetWithText(TextField, 'Password'),
        'password123',
      );
      await tester.pump();

      // Assert - password field should obscure text
      final passwordTextField = tester.widget<TextField>(
        find.widgetWithText(TextField, 'Password'),
      );
      expect(passwordTextField.obscureText, true);
    });

    testWidgets('should display error message when login fails', (
      WidgetTester tester,
    ) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());

      // Simulate login failure
      await tester.enterText(
        find.widgetWithText(TextField, 'Email'),
        'invalid',
      );
      await tester.enterText(find.widgetWithText(TextField, 'Password'), '');

      await tester.tap(find.text('Login'));
      await tester.pump();
      await tester.pump(); // Extra pump for async operation

      // Assert
      expect(loginViewModel.errorMessage, isNotNull);
    });

    testWidgets('should show loading indicator during login', (
      WidgetTester tester,
    ) async {
      // Arrange
      final mockViewModel = MockLoginViewModel();
      when(() => mockViewModel.isLoading).thenReturn(true);
      when(() => mockViewModel.errorMessage).thenReturn(null);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<LoginViewModel>.value(
            value: mockViewModel,
            child: const LoginScreen(),
          ),
        ),
      );

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Login'), findsNothing);
    });

    testWidgets('should have forgot password button', (
      WidgetTester tester,
    ) async {
      // Act
      await tester.pumpWidget(createTestWidget());

      // Assert
      expect(find.text('Forgot Password?'), findsOneWidget);
    });

    testWidgets('should have register link', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());

      // Assert
      expect(find.text('Don\'t have an account?'), findsOneWidget);
      expect(find.text('Sign Up'), findsOneWidget);
    });

    testWidgets('login button should be tappable', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());

      // Act
      final loginButton = find.text('Login');
      expect(loginButton, findsOneWidget);

      // Verify button is enabled by trying to tap it
      await tester.tap(loginButton);
      await tester.pump();

      // Assert - no exception should be thrown
    });

    testWidgets('should display email icon in email field', (
      WidgetTester tester,
    ) async {
      // Act
      await tester.pumpWidget(createTestWidget());

      // Assert
      expect(find.byIcon(Icons.email_outlined), findsOneWidget);
    });

    testWidgets('should display lock icon in password field', (
      WidgetTester tester,
    ) async {
      // Act
      await tester.pumpWidget(createTestWidget());

      // Assert
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    });
  });
}
