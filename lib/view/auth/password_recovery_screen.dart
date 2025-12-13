import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/password_recovery_viewmodel.dart';

class PasswordRecoveryScreen extends StatefulWidget {
  const PasswordRecoveryScreen({super.key});

  @override
  State<PasswordRecoveryScreen> createState() => _PasswordRecoveryScreenState();
}

class _PasswordRecoveryScreenState extends State<PasswordRecoveryScreen> {
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<PasswordRecoveryViewModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        // Here is the creative part: we swap the UI based on the state
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _buildUIForState(context, viewModel),
        ),
      ),
    );
  }

  // Helper to decide which UI to show
  Widget _buildUIForState(
    BuildContext context,
    PasswordRecoveryViewModel viewModel,
  ) {
    // 1. Success State: Show a confirmation message
    if (viewModel.state == RecoveryState.Success) {
      return Column(
        key: const ValueKey('Success'), // Key for AnimatedSwitcher
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, color: Colors.green, size: 80),
          const SizedBox(height: 20),
          const Text(
            'Success!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            'A password reset link has been sent to your email. Please check your inbox (and spam folder).',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey[400]),
          ),
          const SizedBox(height: 30),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Back to Login'),
          ),
        ],
      );
    }

    // 2. Initial, Error, or Loading State: Show the form
    return Column(
      key: const ValueKey('Initial'), // Key for AnimatedSwitcher
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Enter your email to receive a password reset link.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 30),

        // Email Field
        TextField(
          controller: _emailController,
          decoration: const InputDecoration(
            labelText: 'Email',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.emailAddress,
        ),

        // Error Message
        if (viewModel.state == RecoveryState.Error &&
            viewModel.errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 15.0),
            child: Text(
              viewModel.errorMessage!,
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),

        const SizedBox(height: 30),

        // Button
        SizedBox(
          width: double.infinity,
          height: 50,
          child: (viewModel.state == RecoveryState.Loading)
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton(
                  onPressed: () {
                    viewModel.sendResetLink(_emailController.text.trim());
                  },
                  child: const Text(
                    'Send Reset Link',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
        ),
      ],
    );
  }
}
