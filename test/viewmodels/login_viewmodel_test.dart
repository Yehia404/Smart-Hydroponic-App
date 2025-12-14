import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smart_hydroponic_app/viewmodels/login_viewmodel.dart';
import 'package:smart_hydroponic_app/data/services/auth_service.dart';

// Mock classes
class MockAuthService extends Mock implements AuthService {}

class MockUser extends Mock implements User {}

void main() {
  late LoginViewModel viewModel;
  late MockAuthService mockAuthService;

  setUp(() {
    mockAuthService = MockAuthService();
    viewModel = LoginViewModel(mockAuthService);
  });

  group('LoginViewModel Unit Tests', () {
    test('should initialize with default values', () {
      expect(viewModel.isLoading, false);
      expect(viewModel.errorMessage, null);
    });

    test('should return false and set error for invalid email', () async {
      // Act
      final result = await viewModel.login('invalidemail', 'password123');

      // Assert
      expect(result, false);
      expect(viewModel.errorMessage, 'Please enter a valid email address.');
      expect(viewModel.isLoading, false);
      verifyNever(() => mockAuthService.login(any(), any()));
    });

    test('should return false and set error for empty password', () async {
      // Act
      final result = await viewModel.login('test@example.com', '');

      // Assert
      expect(result, false);
      expect(viewModel.errorMessage, 'Please enter your password.');
      expect(viewModel.isLoading, false);
      verifyNever(() => mockAuthService.login(any(), any()));
    });

    test('should return true on successful login', () async {
      // Arrange
      final mockUser = MockUser();
      when(
        () => mockAuthService.login('test@example.com', 'password123'),
      ).thenAnswer((_) async => mockUser);

      // Act
      final result = await viewModel.login('test@example.com', 'password123');

      // Assert
      expect(result, true);
      expect(viewModel.errorMessage, null);
      expect(viewModel.isLoading, false);
      verify(
        () => mockAuthService.login('test@example.com', 'password123'),
      ).called(1);
    });

    test('should return false and set error on login failure', () async {
      // Arrange
      when(
        () => mockAuthService.login('test@example.com', 'wrongpassword'),
      ).thenAnswer((_) async => null);

      // Act
      final result = await viewModel.login('test@example.com', 'wrongpassword');

      // Assert
      expect(result, false);
      expect(
        viewModel.errorMessage,
        'Login failed. Please check your credentials.',
      );
      expect(viewModel.isLoading, false);
    });

    test('should handle exceptions gracefully', () async {
      // Arrange
      when(
        () => mockAuthService.login('test@example.com', 'password123'),
      ).thenThrow(Exception('Network error'));

      // Act
      final result = await viewModel.login('test@example.com', 'password123');

      // Assert
      expect(result, false);
      expect(viewModel.errorMessage, contains('An error occurred'));
      expect(viewModel.isLoading, false);
    });

    test('should set loading state during login process', () async {
      // Arrange
      final mockUser = MockUser();
      bool wasLoadingTrue = false;

      when(
        () => mockAuthService.login('test@example.com', 'password123'),
      ).thenAnswer((_) async {
        // Check if loading is true during the async operation
        if (viewModel.isLoading) wasLoadingTrue = true;
        return mockUser;
      });

      // Act
      await viewModel.login('test@example.com', 'password123');

      // Assert
      expect(wasLoadingTrue, true);
      expect(viewModel.isLoading, false); // Should be false after completion
    });
  });
}
